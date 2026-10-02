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
            Logger.log("iCloud not available, skipping upload", location: .cloudKit, event: .unowned)
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
        Logger.log("Starting downloadAll", location: .cloudKit, event: .unowned)
        guard await checkiCloudAvailability() else {
            Logger.log("iCloud not available, skipping download", location: .cloudKit, event: .unowned)
            return
        }
        
        await MainActor.run { onStateChange?(.downloading) }
        
        do {
            Logger.log("downloadAll: ensureZoneExists...", location: .cloudKit, event: .unowned)
            try await ensureZoneExists()
            Logger.log("downloadAll: fetching all records from zone...", location: .cloudKit, event: .unowned)
            let allRecords = try await fetchAllRecordsFromZone()
            Logger.log("downloadAll: downloadProfile...", location: .cloudKit, event: .unowned)
            try await downloadProfile(from: allRecords["CD_Profile"] ?? [])
            Logger.log("downloadAll: downloadUsers...", location: .cloudKit, event: .unowned)
            try await downloadUsers(from: allRecords["CD_User"] ?? [])
            Logger.log("downloadAll: downloadFriends...", location: .cloudKit, event: .unowned)
            try await downloadFriends(from: allRecords["CD_Friend"] ?? [])
            Logger.log("downloadAll: downloadStories...", location: .cloudKit, event: .unowned)
            try await downloadStories(from: allRecords["CD_Story"] ?? [])
            Logger.log("downloadAll: downloadNotes...", location: .cloudKit, event: .unowned)
            try await downloadNotes(from: allRecords["CD_Note"] ?? [])
            Logger.log("downloadAll: downloadNoteFriends...", location: .cloudKit, event: .unowned)
            try await downloadNoteFriends(from: allRecords["CD_NoteFriend"] ?? [])
            
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
    
    func fetchAllRecordsFromZone() async throws -> [String: [CKRecord]] {
        var recordsByType: [String: [CKRecord]] = [:]
        var moreComing = true
        var changeToken: CKServerChangeToken? = nil
        
        while moreComing {
            let result = try await privateDB.recordZoneChanges(
                inZoneWith: zoneID,
                since: changeToken
            )
            
            for (_, recordResult) in result.modificationResultsByID {
                if case .success(let modification) = recordResult {
                    let record = modification.record
                    recordsByType[record.recordType, default: []].append(record)
                }
            }
            
            changeToken = result.changeToken
            moreComing = result.moreComing
        }
        
        Logger.log("Fetched records from zone: \(recordsByType.mapValues { $0.count })", location: .cloudKit, event: .success)
        return recordsByType
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
}
