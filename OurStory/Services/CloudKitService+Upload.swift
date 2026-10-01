//
//  CloudKitService+Upload.swift
//  OurStory
//

import Foundation
import CloudKit
import GRDB

extension CloudKitService {
    
    // MARK: - Upload Profile
    
    func uploadProfile() async throws {
        let userDefaults = UserDefaultsManager()
        let user = userDefaults.getCurrentUser()
        
        let recordID = CKRecord.ID(recordName: "profile_\(user.id.uuidString)", zoneID: zoneID)
        let record = CKRecord(recordType: "CD_Profile", recordID: recordID)
        record["userID"] = user.id.uuidString as NSString
        record["name"] = user.name as NSString
        record["color"] = user.color as NSString
        record["updatedDate"] = Date() as NSDate
        
        try await batchSave(records: [record])
        Logger.log("Uploaded profile", location: .cloudKit, event: .success)
    }
    
    // MARK: - Upload Users
    
    func uploadUsers() async throws {
        let users = try await dbPool.read { db in
            try UserModelGRDB.fetchAll(db)
        }
        
        var records: [CKRecord] = []
        for user in users {
            let recordID = CKRecord.ID(recordName: user.id.uuidString, zoneID: zoneID)
            let record = CKRecord(recordType: "CD_User", recordID: recordID)
            record["name"] = user.name as NSString
            record["color"] = user.color as NSString
            record["updatedDate"] = (user.updatedDate ?? Date()) as NSDate
            records.append(record)
        }
        
        try await batchSave(records: records)
        Logger.log("Uploaded \(records.count) users", location: .cloudKit, event: .success)
    }
    
    // MARK: - Upload Friends
    
    func uploadFriends() async throws {
        let friends = try await dbPool.read { db in
            try FriendModelGRDB.fetchAll(db)
        }
        
        var records: [CKRecord] = []
        for friend in friends {
            let recordID = CKRecord.ID(recordName: friend.id.uuidString, zoneID: zoneID)
            let record = CKRecord(recordType: "CD_Friend", recordID: recordID)
            record["name"] = friend.name as NSString
            record["color"] = friend.color as NSString
            record["userID"] = friend.userID?.uuidString as NSString?
            record["lastSyncDate"] = friend.lastSyncDate as NSDate?
            record["updatedDate"] = (friend.updatedDate ?? Date()) as NSDate
            records.append(record)
        }
        
        try await batchSave(records: records)
        Logger.log("Uploaded \(records.count) friends", location: .cloudKit, event: .success)
    }
    
    // MARK: - Upload Stories
    
    func uploadStories() async throws {
        let stories = try await dbPool.read { db in
            try StoryModelGRDB.fetchAll(db)
        }
        
        var records: [CKRecord] = []
        for story in stories {
            let recordID = CKRecord.ID(recordName: story.id.uuidString, zoneID: zoneID)
            let record = CKRecord(recordType: "CD_Story", recordID: recordID)
            record["date"] = story.date as NSDate
            record["title"] = story.title as NSString
            record["isUserTitle"] = NSNumber(value: story.isUserTitle)
            record["updatedDate"] = (story.updatedDate ?? Date()) as NSDate
            records.append(record)
        }
        
        try await batchSave(records: records)
        Logger.log("Uploaded \(records.count) stories", location: .cloudKit, event: .success)
    }
    
    // MARK: - Upload Notes
    
    func uploadNotes() async throws {
        let notes = try await dbPool.read { db in
            try NoteModelGRDB.fetchAll(db)
        }
        
        var records: [CKRecord] = []
        for note in notes {
            let recordID = CKRecord.ID(recordName: note.id.uuidString, zoneID: zoneID)
            let record = CKRecord(recordType: "CD_Note", recordID: recordID)
            record["title"] = note.title as NSString?
            record["text"] = note.text as NSString
            record["date"] = note.date as NSDate
            record["rootStoryID"] = note.rootStoryID.uuidString as NSString
            record["ownerID"] = note.ownerID?.uuidString as NSString?
            record["updatedDate"] = (note.updatedDate ?? Date()) as NSDate
            records.append(record)
        }
        
        try await batchSave(records: records)
        Logger.log("Uploaded \(records.count) notes", location: .cloudKit, event: .success)
    }
    
    // MARK: - Upload NoteFriends
    
    func uploadNoteFriends() async throws {
        let noteFriends = try await dbPool.read { db in
            try NoteFriend.fetchAll(db)
        }
        
        var records: [CKRecord] = []
        for nf in noteFriends {
            let compositeKey = "\(nf.noteId.uuidString)_\(nf.friendId.uuidString)"
            let recordID = CKRecord.ID(recordName: compositeKey, zoneID: zoneID)
            let record = CKRecord(recordType: "CD_NoteFriend", recordID: recordID)
            record["noteID"] = nf.noteId.uuidString as NSString
            record["friendID"] = nf.friendId.uuidString as NSString
            record["isSent"] = NSNumber(value: nf.isSent)
            record["updatedDate"] = (nf.updatedDate ?? Date()) as NSDate
            records.append(record)
        }
        
        try await batchSave(records: records)
        Logger.log("Uploaded \(records.count) noteFriends", location: .cloudKit, event: .success)
    }
    
    // MARK: - Process Deletions
    
    func processDeletions() async throws {
        let deletions = try await dbPool.read { db in
            try DeletedRecordModelGRDB.fetchAll(db)
        }
        
        guard !deletions.isEmpty else { return }
        
        var recordIDsToDelete: [CKRecord.ID] = []
        for deletion in deletions {
            let ckRecordID = CKRecord.ID(recordName: deletion.recordID, zoneID: zoneID)
            recordIDsToDelete.append(ckRecordID)
        }
        
        // Delete from CloudKit in batches
        let batchSize = 400
        for batchStart in stride(from: 0, to: recordIDsToDelete.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, recordIDsToDelete.count)
            let batch = Array(recordIDsToDelete[batchStart..<batchEnd])
            
            let (_, deleteResults) = try await privateDB.modifyRecords(
                saving: [],
                deleting: batch,
                savePolicy: .changedKeys,
                atomically: false
            )
            
            for (recordID, result) in deleteResults {
                if case .failure(let error) = result {
                    // Ignore "not found" errors — record may already be deleted
                    if let ckError = error as? CKError, ckError.code == .unknownItem {
                        continue
                    }
                    Logger.log("Failed to delete record \(recordID.recordName): \(error)", location: .cloudKit, event: .error(error))
                }
            }
        }
        
        // Clean up local tracking table
        try await dbPool.write { db in
            try db.execute(sql: "DELETE FROM deletedRecord")
        }
        
        Logger.log("Processed \(deletions.count) deletions", location: .cloudKit, event: .success)
    }
}
