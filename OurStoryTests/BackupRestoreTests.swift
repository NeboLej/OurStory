import Foundation
import GRDB
import Testing
@testable import OurStory

struct BackupRestoreTests {
    @Test func restoreResolvesConflictsAndMaintainsLinks() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var configuration = Configuration()
        configuration.prepareDatabase { db in try db.execute(sql: "PRAGMA foreign_keys = ON") }
        let pool = try DatabasePool(path: directory.appendingPathComponent("current.sqlite").path, configuration: configuration)
        let service = BackupService(dbPool: pool, backupDirectory: directory.appendingPathComponent("backups"))
        let friendID = UUID()
        let otherFriendID = UUID()
        let noteID = UUID()
        let newNoteID = UUID()
        let now = Date()

        try pool.write { db in
            try db.execute(sql: """
                CREATE TABLE user (id BLOB PRIMARY KEY, name TEXT NOT NULL, color TEXT NOT NULL, updatedDate REAL);
                CREATE TABLE friend (id BLOB PRIMARY KEY, name TEXT NOT NULL, color TEXT NOT NULL, userID BLOB REFERENCES user(id), lastSyncDate REAL, updatedDate REAL, isHidden BOOLEAN NOT NULL);
                CREATE TABLE note (id BLOB PRIMARY KEY, title TEXT, text TEXT NOT NULL, date REAL NOT NULL, ownerID BLOB REFERENCES friend(id), updatedDate REAL);
                CREATE TABLE noteFriend (noteID BLOB NOT NULL REFERENCES note(id), friendID BLOB NOT NULL REFERENCES friend(id), isSent BOOLEAN NOT NULL, updatedDate REAL, PRIMARY KEY (noteID, friendID));
                CREATE TABLE deletedRecord (recordType TEXT NOT NULL, recordID TEXT NOT NULL, deletionDate REAL NOT NULL, PRIMARY KEY (recordType, recordID));
                """)
            try db.execute(sql: "INSERT INTO friend (id, name, color, isHidden) VALUES (?, 'Backup friend', 'red', 0), (?, 'Other', 'blue', 0)", arguments: [friendID, otherFriendID])
            try db.execute(sql: "INSERT INTO note (id, text, date) VALUES (?, 'Backup story', ?), (?, 'New story', ?)", arguments: [noteID, now, newNoteID, now])
            try db.execute(sql: "INSERT INTO noteFriend (noteID, friendID, isSent) VALUES (?, ?, 0)", arguments: [noteID, friendID])
        }
        try await service.create()
        let backup = try #require(await service.list().first)
        let details = try await service.details(for: backup)
        #expect(details.noteCount == 2)
        #expect(details.friendCount == 2)

        try pool.write { db in
            try db.execute(sql: "UPDATE note SET text = 'Current story' WHERE id = ?", arguments: [noteID])
            try db.execute(sql: "DELETE FROM note WHERE id = ?", arguments: [newNoteID])
            try db.execute(sql: "DELETE FROM noteFriend WHERE noteID = ?", arguments: [noteID])
            try db.execute(sql: "INSERT INTO noteFriend (noteID, friendID, isSent) VALUES (?, ?, 0)", arguments: [noteID, otherFriendID])
        }
        do {
            try await service.restore(backup, policy: nil)
            Issue.record("Expected a conflict")
        } catch BackupRestoreError.conflicts {
        }
        try await service.restore(backup, policy: .skip)
        try pool.read { db in
            #expect(try String.fetchOne(db, sql: "SELECT text FROM note WHERE id = ?", arguments: [noteID]) == "Current story")
            #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM note WHERE id = ?", arguments: [newNoteID]) == 1)
            #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM noteFriend WHERE noteID = ? AND friendID = ?", arguments: [noteID, otherFriendID]) == 1)
        }

        try await service.restore(backup, policy: .replace)
        try pool.read { db in
            #expect(try String.fetchOne(db, sql: "SELECT text FROM note WHERE id = ?", arguments: [noteID]) == "Backup story")
            #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM noteFriend WHERE noteID = ? AND friendID = ?", arguments: [noteID, friendID]) == 1)
            let key = "\(noteID.uuidString)_\(otherFriendID.uuidString)"
            #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM deletedRecord WHERE recordType = 'CD_NoteFriend' AND recordID = ?", arguments: [key]) == 1)
        }
    }
}
