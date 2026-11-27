import Foundation
import GRDB

struct DatabaseBackup: Identifiable {
    let url: URL
    let date: Date
    var id: URL { url }
}

struct BackupDetails {
    let noteCount: Int
    let friendCount: Int
}

enum BackupConflictPolicy {
    case replace
    case skip
}

enum BackupRestoreError: LocalizedError {
    case conflicts
    case invalidBackup
    case syncInProgress

    var errorDescription: String? {
        switch self {
        case .conflicts: L10n.restoreConflicts
        case .invalidBackup: L10n.restoreInvalid
        case .syncInProgress: L10n.restoreSyncBusy
        }
    }
}

private struct BackupContents {
    let users: [UserModelGRDB]
    let friends: [FriendModelGRDB]
    let notes: [NoteModelGRDB]
    let links: [NoteFriend]
}

actor BackupService {
    static let shared = BackupService()
    private let interval: TimeInterval = 2 * 24 * 60 * 60
    private let dbPool: DatabasePool
    private let backupDirectory: URL?

    init(dbPool: DatabasePool = DatabaseManager.shared.dbPool, backupDirectory: URL? = nil) {
        self.dbPool = dbPool
        self.backupDirectory = backupDirectory
    }

    private func directory() throws -> URL {
        let base = try backupDirectory ?? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = backupDirectory == nil ? base.appendingPathComponent("DatabaseBackups", isDirectory: true) : base
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func list() throws -> [DatabaseBackup] {
        try FileManager.default.contentsOfDirectory(at: directory(), includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "sqlite" }
            .map { url in
                let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return DatabaseBackup(url: url, date: date)
            }
            .sorted { $0.date > $1.date }
    }

    private func openBackup(_ backup: DatabaseBackup) throws -> DatabaseQueue {
        let base = try directory().standardizedFileURL
        let url = backup.url.standardizedFileURL
        guard url.deletingLastPathComponent() == base,
              FileManager.default.fileExists(atPath: url.path) else {
            throw BackupRestoreError.invalidBackup
        }
        // Older snapshots can retain the source database's WAL header. Opening
        // them read-only can fail when SQLite needs to create WAL sidecar files.
        let database = try DatabaseQueue(path: url.path)
        try database.writeWithoutTransaction { db in
            guard try String.fetchOne(db, sql: "PRAGMA journal_mode = DELETE")?.lowercased() == "delete" else {
                throw BackupRestoreError.invalidBackup
            }
        }
        return database
    }

    func details(for backup: DatabaseBackup) throws -> BackupDetails {
        let source = try openBackup(backup)
        return try source.read { db in
            BackupDetails(noteCount: try NoteModelGRDB.fetchCount(db),
                          friendCount: try FriendModelGRDB.fetchCount(db))
        }
    }

    private func readContents(of backup: DatabaseBackup) throws -> BackupContents {
        let source = try openBackup(backup)
        return try source.read { db in
            guard try String.fetchOne(db, sql: "PRAGMA integrity_check") == "ok",
                  try Row.fetchAll(db, sql: "PRAGMA foreign_key_check").isEmpty else {
                throw BackupRestoreError.invalidBackup
            }
            let requiredColumns: [String: Set<String>] = [
                "user": ["id", "name", "color", "updatedDate"],
                "friend": ["id", "name", "color", "userID", "lastSyncDate", "updatedDate", "isHidden"],
                "note": ["id", "title", "text", "date", "ownerID", "updatedDate"],
                "noteFriend": ["noteID", "friendID", "isSent", "updatedDate"]
            ]
            for (table, required) in requiredColumns {
                guard try db.tableExists(table),
                      required.isSubset(of: Set(try db.columns(in: table).map(\.name))) else {
                    throw BackupRestoreError.invalidBackup
                }
            }
            let contents = try BackupContents(
                users: UserModelGRDB.fetchAll(db),
                friends: FriendModelGRDB.fetchAll(db),
                notes: NoteModelGRDB.fetchAll(db),
                links: NoteFriend.fetchAll(db)
            )
            let users = Set(contents.users.map(\.id))
            let friends = Set(contents.friends.map(\.id))
            let notes = Set(contents.notes.map(\.id))
            let links = Set(contents.links.map { "\($0.noteId.uuidString)_\($0.friendId.uuidString)" })
            guard users.count == contents.users.count,
                  friends.count == contents.friends.count,
                  notes.count == contents.notes.count,
                  links.count == contents.links.count,
                  contents.friends.allSatisfy({ $0.userID.map(users.contains) ?? true }),
                  contents.notes.allSatisfy({ $0.ownerID.map(friends.contains) ?? true }),
                  contents.links.allSatisfy({ notes.contains($0.noteId) && friends.contains($0.friendId) }) else {
                throw BackupRestoreError.invalidBackup
            }
            return contents
        }
    }

    func restore(_ backup: DatabaseBackup, policy: BackupConflictPolicy?) throws {
        let contents = try readContents(of: backup)

        try dbPool.write { db in
            let existingUsers = Set(try UserModelGRDB.fetchAll(db).map(\.id))
            let existingFriends = Set(try FriendModelGRDB.fetchAll(db).map(\.id))
            let existingNotes = Set(try NoteModelGRDB.fetchAll(db).map(\.id))
            let hasConflicts = contents.users.contains { existingUsers.contains($0.id) }
                || contents.friends.contains { existingFriends.contains($0.id) }
                || contents.notes.contains { existingNotes.contains($0.id) }
            if hasConflicts && policy == nil { throw BackupRestoreError.conflicts }

            let now = Date()
            for var user in contents.users where policy == .replace || !existingUsers.contains(user.id) {
                user.updatedDate = now
                try user.save(db)
                try db.execute(sql: "DELETE FROM deletedRecord WHERE recordType = ? AND recordID = ?", arguments: ["CD_User", user.id.uuidString])
            }
            for var friend in contents.friends where policy == .replace || !existingFriends.contains(friend.id) {
                friend.updatedDate = now
                try friend.save(db)
                try db.execute(sql: "DELETE FROM deletedRecord WHERE recordType = ? AND recordID = ?", arguments: ["CD_Friend", friend.id.uuidString])
            }
            let restoredNotes = contents.notes.filter { policy == .replace || !existingNotes.contains($0.id) }
            let restoredNoteIDs = Set(restoredNotes.map(\.id))
            let backupLinks = contents.links.filter { restoredNoteIDs.contains($0.noteId) }
            let backupLinkIDs = Set(backupLinks.map { "\($0.noteId.uuidString)_\($0.friendId.uuidString)" })

            for var note in restoredNotes {
                if existingNotes.contains(note.id) {
                    let oldLinks = try NoteFriend.filter(Column("noteID") == note.id).fetchAll(db)
                    for link in oldLinks {
                        let key = "\(link.noteId.uuidString)_\(link.friendId.uuidString)"
                        if !backupLinkIDs.contains(key) {
                            try db.execute(sql: "INSERT OR REPLACE INTO deletedRecord (recordType, recordID, deletionDate) VALUES (?, ?, ?)",
                                           arguments: ["CD_NoteFriend", key, now])
                        }
                    }
                    try db.execute(sql: "DELETE FROM noteFriend WHERE noteID = ?", arguments: [note.id])
                }
                note.updatedDate = now
                try note.save(db)
                try db.execute(sql: "DELETE FROM deletedRecord WHERE recordType = ? AND recordID = ?", arguments: ["CD_Note", note.id.uuidString])
            }
            for var link in backupLinks {
                link.updatedDate = now
                try link.insert(db)
                let key = "\(link.noteId.uuidString)_\(link.friendId.uuidString)"
                try db.execute(sql: "DELETE FROM deletedRecord WHERE recordType = ? AND recordID = ?", arguments: ["CD_NoteFriend", key])
            }
        }
    }

    func importBackup(from sourceURL: URL) throws {
        let accessGranted = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessGranted { sourceURL.stopAccessingSecurityScopedResource() } }

        let directoryURL = try directory()
        let stagingURL = directoryURL.appendingPathComponent(".import-\(UUID().uuidString)")
        let destinationURL = directoryURL.appendingPathComponent("OurStory-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: stagingURL) }

        var coordinationError: NSError?
        var copyResult: Result<Void, Error>?
        NSFileCoordinator().coordinate(readingItemAt: sourceURL, options: [], error: &coordinationError) { coordinatedURL in
            copyResult = Result { try FileManager.default.copyItem(at: coordinatedURL, to: stagingURL) }
        }
        if let coordinationError { throw coordinationError }
        guard let copyResult else { throw BackupRestoreError.invalidBackup }
        try copyResult.get()

        do {
            _ = try readContents(of: DatabaseBackup(url: stagingURL, date: .now))
        } catch {
            throw BackupRestoreError.invalidBackup
        }
        try FileManager.default.setAttributes([.creationDate: Date()], ofItemAtPath: stagingURL.path)
        try FileManager.default.moveItem(at: stagingURL, to: destinationURL)
        try pruneBackups()
    }

    private func pruneBackups() throws {
        for backup in try list().dropFirst(10) {
            try FileManager.default.removeItem(at: backup.url)
        }
    }

    func createIfNeeded() throws {
        if let latest = try list().first, Date().timeIntervalSince(latest.date) < interval { return }
        try create()
    }

    func create() throws {
        let url = try directory().appendingPathComponent("OurStory-\(UUID().uuidString).sqlite")
        do {
            let destination = try DatabaseQueue(path: url.path)
            try dbPool.backup(to: destination)
            try destination.writeWithoutTransaction { db in
                guard try String.fetchOne(db, sql: "PRAGMA journal_mode = DELETE")?.lowercased() == "delete" else {
                    throw BackupRestoreError.invalidBackup
                }
            }
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
        try pruneBackups()
    }
}
