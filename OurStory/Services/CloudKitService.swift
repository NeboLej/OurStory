//
//  CloudKitService.swift
//  OurStory
//

import Foundation
import CloudKit
import GRDB

enum CloudSyncState: Equatable {
    case idle
    case uploading
    case downloading
    case error(String)
    case completed
}

final class CloudKitService {
    
    static let shared = CloudKitService()
    
    private let container = CKContainer(identifier: "iCloud.com.nebo.OurStory")
    var privateDB: CKDatabase { container.privateCloudDatabase }
    let zoneID = CKRecordZone.ID(zoneName: "OurStoryZone", ownerName: CKCurrentUserDefaultName)
    
    let dbPool: DatabasePool
    
    var onStateChange: ((CloudSyncState) -> Void)?
    
    private init() {
        self.dbPool = DatabaseManager.shared.dbPool
    }
    
    // MARK: - iCloud Availability
    
    func checkiCloudAvailability() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            Logger.log("iCloud account check failed: \(error)", location: .cloudKit, event: .error(error))
            return false
        }
    }
    
    // MARK: - Zone Setup
    
    func ensureZoneExists() async throws {
        do {
            _ = try await privateDB.recordZone(for: zoneID)
            Logger.log("Zone already exists", location: .cloudKit, event: .success)
        } catch let error as CKError where error.code == .zoneNotFound {
            let zone = CKRecordZone(zoneID: zoneID)
            _ = try await privateDB.save(zone)
            Logger.log("Zone created", location: .cloudKit, event: .success)
        }
    }
    
    // MARK: - Full Upload
    
    func uploadAll() async {
        guard await checkiCloudAvailability() else {
            Logger.log("iCloud not available, skipping upload", location: .cloudKit, event: .processing)
            return
        }
        
        await MainActor.run { onStateChange?(.uploading) }
        
        do {
            try await ensureZoneExists()
            let lastUpload = await getLastUploadDate()
            try await uploadProfile()
            try await uploadUsers(since: lastUpload)
            try await uploadFriends(since: lastUpload)
            try await uploadStories(since: lastUpload)
            try await uploadNotes(since: lastUpload)
            try await uploadNoteFriends(since: lastUpload)
            try await processDeletions()
            
            // Save last upload date
            try await dbPool.write { db in
                try db.execute(
                    sql: "INSERT OR REPLACE INTO cloudSyncMetadata (key, value) VALUES (?, ?)",
                    arguments: ["lastUploadDate", ISO8601DateFormatter().string(from: Date())]
                )
            }
            
            Logger.log("Upload completed", location: .cloudKit, event: .success)
            await MainActor.run { onStateChange?(.completed) }
        } catch {
            Logger.log("CloudKit upload failed: \(error)", location: .cloudKit, event: .error(error))
            await MainActor.run { onStateChange?(.error(error.localizedDescription)) }
        }
    }
    
    // MARK: - Full Download
    
    func downloadAll() async {
        Logger.log("Starting downloadAll", location: .cloudKit, event: .processing)
        guard await checkiCloudAvailability() else {
            Logger.log("iCloud not available, skipping download", location: .cloudKit, event: .processing)
            return
        }
        
        await MainActor.run { onStateChange?(.downloading) }
        
        do {
            Logger.log("downloadAll: ensureZoneExists...", location: .cloudKit, event: .processing)
            try await ensureZoneExists()
            
            // Process pending local deletions BEFORE downloading
            Logger.log("downloadAll: processing pending deletions...", location: .cloudKit, event: .processing)
            try await processDeletions()
            
            // Load saved change token for delta download
            let savedToken = await loadZoneChangeToken()
            Logger.log("downloadAll: fetching changes (token: \(savedToken != nil ? "saved" : "nil"))...", location: .cloudKit, event: .processing)
            let changes = try await fetchChangedRecordsFromZone(since: savedToken)
            
            // Safety: count local notes BEFORE applying any deletions
            let localNoteCount = try await dbPool.read { db in try NoteModelGRDB.fetchCount(db) }
            
            // Filter deletions: never apply mass deletions that would wipe local data
            var safeDeletions = changes.deletedRecordIDs
            if !safeDeletions.isEmpty && localNoteCount > 0 {
                // Count how many deletion IDs target notes (UUID format, not composite key)
                let noteDeleteCount = safeDeletions.filter { !$0.recordName.contains("_") && UUID(uuidString: $0.recordName) != nil }.count
                let totalModifications = changes.recordsByType.values.reduce(0) { $0 + $1.count }
                
                // Block ALL deletions if they would remove >50% of local notes OR
                // if there are only deletions with no modifications (cloud wipe scenario)
                if noteDeleteCount > localNoteCount / 2 || (totalModifications == 0 && safeDeletions.count > 0) {
                    Logger.log("SAFETY: Blocked \(safeDeletions.count) remote deletions (would delete \(noteDeleteCount)/\(localNoteCount) notes, modifications: \(totalModifications)). Resetting token.", location: .cloudKit, event: .processing)
                    safeDeletions = []
                    try await resetZoneChangeToken()
                }
            }
            
            // Load locally pending deletions as safety net
            let pendingDeletionIDs = try await loadPendingDeletionIDs()
            
            func filterDeleted(_ records: [CKRecord]) -> [CKRecord] {
                records.filter { !pendingDeletionIDs.contains($0.recordID.recordName) }
            }
            
            // Process safe remote deletions
            Logger.log("downloadAll: processing remote deletions (\(safeDeletions.count))...", location: .cloudKit, event: .processing)
            try await processRemoteDeletions(safeDeletions)
            
            let allRecords = changes.recordsByType
            
            Logger.log("downloadAll: downloadProfile...", location: .cloudKit, event: .processing)
            try await downloadProfile(from: allRecords["CD_Profile"] ?? [])
            Logger.log("downloadAll: downloadUsers...", location: .cloudKit, event: .processing)
            try await downloadUsers(from: filterDeleted(allRecords["CD_User"] ?? []))
            Logger.log("downloadAll: downloadFriends...", location: .cloudKit, event: .processing)
            try await downloadFriends(from: filterDeleted(allRecords["CD_Friend"] ?? []))
            Logger.log("downloadAll: downloadStories...", location: .cloudKit, event: .processing)
            try await downloadStories(from: filterDeleted(allRecords["CD_Story"] ?? []))
            Logger.log("downloadAll: downloadNotes...", location: .cloudKit, event: .processing)
            try await downloadNotes(from: filterDeleted(allRecords["CD_Note"] ?? []))
            Logger.log("downloadAll: downloadNoteFriends...", location: .cloudKit, event: .processing)
            try await downloadNoteFriends(from: filterDeleted(allRecords["CD_NoteFriend"] ?? []))
            
            // Persist the new change token for next delta download
            try await saveZoneChangeToken(changes.newToken)
            
            // Save last download date
            try await dbPool.write { db in
                try db.execute(
                    sql: "INSERT OR REPLACE INTO cloudSyncMetadata (key, value) VALUES (?, ?)",
                    arguments: ["lastDownloadDate", ISO8601DateFormatter().string(from: Date())]
                )
            }
            
            Logger.log("Download completed", location: .cloudKit, event: .success)
            await MainActor.run { onStateChange?(.completed) }
        } catch {
            Logger.log("CloudKit download failed: \(error)", location: .cloudKit, event: .error(error))
            await MainActor.run { onStateChange?(.error(error.localizedDescription)) }
        }
    }
    
    // MARK: - Helpers
    
    struct ZoneChangesResult {
        let recordsByType: [String: [CKRecord]]
        let deletedRecordIDs: [CKRecord.ID]
        let newToken: CKServerChangeToken?
    }
    
    func fetchChangedRecordsFromZone(since savedToken: CKServerChangeToken?) async throws -> ZoneChangesResult {
        var recordsByType: [String: [CKRecord]] = [:]
        var deletedRecordIDs: [CKRecord.ID] = []
        var moreComing = true
        var changeToken = savedToken
        var latestToken: CKServerChangeToken?
        
        while moreComing {
            let result: (modificationResultsByID: [CKRecord.ID: Result<CKDatabase.RecordZoneChange.Modification, Error>], deletions: [CKDatabase.RecordZoneChange.Deletion], changeToken: CKServerChangeToken, moreComing: Bool)
            do {
                result = try await privateDB.recordZoneChanges(
                    inZoneWith: zoneID,
                    since: changeToken
                )
            } catch let error as CKError where error.code == .changeTokenExpired {
                Logger.log("Change token expired, performing full download", location: .cloudKit, event: .processing)
                return try await fetchChangedRecordsFromZone(since: nil)
            }
            
            for (_, recordResult) in result.modificationResultsByID {
                if case .success(let modification) = recordResult {
                    let record = modification.record
                    recordsByType[record.recordType, default: []].append(record)
                }
            }
            
            for deletion in result.deletions {
                deletedRecordIDs.append(deletion.recordID)
            }
            
            latestToken = result.changeToken
            changeToken = result.changeToken
            moreComing = result.moreComing
        }
        
        Logger.log("Fetched changes from zone: \(recordsByType.mapValues { $0.count }), deletions: \(deletedRecordIDs.count)", location: .cloudKit, event: .success)
        return ZoneChangesResult(recordsByType: recordsByType, deletedRecordIDs: deletedRecordIDs, newToken: latestToken)
    }
    
    func batchSave(records: [CKRecord]) async throws {
        guard !records.isEmpty else { return }
        
        let batchSize = 400
        for batchStart in stride(from: 0, to: records.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, records.count)
            let batch = Array(records[batchStart..<batchEnd])
            
            let (saveResults, _) = try await privateDB.modifyRecords(
                saving: batch,
                deleting: [],
                savePolicy: .changedKeys,
                atomically: false
            )
            
            for (recordID, result) in saveResults {
                if case .failure(let error) = result {
                    Logger.log("Failed to save record \(recordID.recordName): \(error)", location: .cloudKit, event: .error(error))
                }
            }
        }
    }
    
    func loadPendingDeletionIDs() async throws -> Set<String> {
        try await dbPool.read { db in
            let rows = try DeletedRecordModelGRDB.fetchAll(db)
            return Set(rows.map { $0.recordID })
        }
    }
    
    func getLastDownloadDate() async -> Date? {
        await getMetadataDate(key: "lastDownloadDate")
    }
    
    func getLastUploadDate() async -> Date? {
        await getMetadataDate(key: "lastUploadDate")
    }
    
    private func getMetadataDate(key: String) async -> Date? {
        do {
            return try await dbPool.read { db in
                if let row = try Row.fetchOne(db, sql: "SELECT value FROM cloudSyncMetadata WHERE key = ?", arguments: [key]),
                   let dateString = row["value"] as? String {
                    return ISO8601DateFormatter().date(from: dateString)
                }
                return nil
            }
        } catch {
            return nil
        }
    }
    
    // MARK: - Zone Change Token Persistence
    
    func loadZoneChangeToken() async -> CKServerChangeToken? {
        do {
            return try await dbPool.read { db in
                guard let row = try Row.fetchOne(db, sql: "SELECT dataValue FROM cloudSyncMetadata WHERE key = ?", arguments: ["zoneChangeToken"]),
                      let data = row["dataValue"] as? Data else {
                    return nil
                }
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
            }
        } catch {
            Logger.log("Failed to load zone change token: \(error)", location: .cloudKit, event: .error(error))
            return nil
        }
    }
    
    func saveZoneChangeToken(_ token: CKServerChangeToken?) async throws {
        guard let token else { return }
        let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
        try await dbPool.write { db in
            try db.execute(
                sql: "INSERT OR REPLACE INTO cloudSyncMetadata (key, dataValue) VALUES (?, ?)",
                arguments: ["zoneChangeToken", data]
            )
        }
    }
    
    func resetZoneChangeToken() async throws {
        try await dbPool.write { db in
            try db.execute(
                sql: "DELETE FROM cloudSyncMetadata WHERE key = ?",
                arguments: ["zoneChangeToken"]
            )
        }
        Logger.log("Zone change token reset, next download will be full", location: .cloudKit, event: .processing)
    }
}
