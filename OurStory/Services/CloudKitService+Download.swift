//
//  CloudKitService+Download.swift
//  OurStory
//

import Foundation
import CloudKit
import GRDB

extension CloudKitService {
    
    // MARK: - Download Profile
    
    func downloadProfile(from records: [CKRecord]) async throws {
        guard let cloudRecord = records.first else { return }
        
        let cloudName = cloudRecord["name"] as? String ?? ""
        let cloudColor = cloudRecord["color"] as? String ?? ""
        let cloudUserIDStr = cloudRecord["userID"] as? String
        let cloudUserID = cloudUserIDStr.flatMap { UUID(uuidString: $0) }
        
        let userDefaults = UserDefaultsManager()
        let localUser = userDefaults.getCurrentUser()
        
        // Reinstall scenario: local user has empty name but cloud has data
        if localUser.name.isEmpty && !cloudName.isEmpty {
            if let cloudID = cloudUserID {
                _ = userDefaults.restoreUser(id: cloudID, name: cloudName, color: cloudColor)
            } else {
                _ = userDefaults.editUser(name: cloudName, color: cloudColor)
            }
            Logger.log("Restored profile from cloud", location: .cloudKit, event: .success)
        }
    }
    
    // MARK: - Download Users
    
    func downloadUsers(from records: [CKRecord]) async throws {
        let lastSync = await getLastDownloadDate()
        
        try await dbPool.write { db in
            let localUsers = try UserModelGRDB.fetchAll(db)
            var cloudIDSet = Set<UUID>()
            
            for record in records {
                guard let id = UUID(uuidString: record.recordID.recordName) else { continue }
                cloudIDSet.insert(id)
                
                let cloudName = record["name"] as? String ?? ""
                let cloudColor = record["color"] as? String ?? ""
                let cloudUpdated = record["updatedDate"] as? Date ?? Date.distantPast
                
                if let existing = try UserModelGRDB.filter(key: id).fetchOne(db) {
                    let localUpdated = existing.updatedDate ?? Date.distantPast
                    if cloudUpdated > localUpdated {
                        var model = existing
                        model.name = cloudName
                        model.color = cloudColor
                        model.updatedDate = cloudUpdated
                        try model.update(db)
                    }
                } else {
                    var model = UserModelGRDB(from: User(id: id, name: cloudName, color: cloudColor))
                    model.updatedDate = cloudUpdated
                    try model.insert(db)
                }
            }
            
            // Handle remote deletions
            if let lastSync {
                for local in localUsers {
                    if !cloudIDSet.contains(local.id) {
                        let localUpdated = local.updatedDate ?? Date.distantPast
                        if localUpdated < lastSync {
                            try UserModelGRDB.deleteOne(db, key: local.id)
                        }
                    }
                }
            }
        }
        
        Logger.log("Downloaded \(records.count) users", location: .cloudKit, event: .success)
    }
    
    // MARK: - Download Friends
    
    func downloadFriends(from records: [CKRecord]) async throws {
        let lastSync = await getLastDownloadDate()
        
        try await dbPool.write { db in
            let localFriends = try FriendModelGRDB.fetchAll(db)
            var cloudIDSet = Set<UUID>()
            
            for record in records {
                guard let id = UUID(uuidString: record.recordID.recordName) else { continue }
                cloudIDSet.insert(id)
                
                let cloudName = record["name"] as? String ?? ""
                let cloudColor = record["color"] as? String ?? ""
                let cloudUserIDStr = record["userID"] as? String
                let cloudUserID = cloudUserIDStr.flatMap { UUID(uuidString: $0) }
                let cloudLastSync = record["lastSyncDate"] as? Date
                let cloudUpdated = record["updatedDate"] as? Date ?? Date.distantPast
                
                if let existing = try FriendModelGRDB.filter(key: id).fetchOne(db) {
                    let localUpdated = existing.updatedDate ?? Date.distantPast
                    if cloudUpdated > localUpdated {
                        var model = existing
                        model.name = cloudName
                        model.color = cloudColor
                        model.userID = cloudUserID
                        model.lastSyncDate = cloudLastSync
                        model.updatedDate = cloudUpdated
                        try model.update(db)
                    }
                } else {
                    let friend = Friend(id: id, name: cloudName, color: cloudColor, lastSyncDate: cloudLastSync)
                    var model = FriendModelGRDB(from: friend, userID: cloudUserID)
                    model.updatedDate = cloudUpdated
                    try model.insert(db)
                }
            }
            
            // Handle remote deletions
            if let lastSync {
                for local in localFriends {
                    if !cloudIDSet.contains(local.id) {
                        let localUpdated = local.updatedDate ?? Date.distantPast
                        if localUpdated < lastSync {
                            try FriendModelGRDB.deleteOne(db, key: local.id)
                        }
                    }
                }
            }
        }
        
        Logger.log("Downloaded \(records.count) friends", location: .cloudKit, event: .success)
    }
    
    // MARK: - Download Stories
    
    func downloadStories(from records: [CKRecord]) async throws {
        let lastSync = await getLastDownloadDate()
        
        try await dbPool.write { db in
            let localStories = try StoryModelGRDB.fetchAll(db)
            var cloudIDSet = Set<UUID>()
            
            for record in records {
                guard let id = UUID(uuidString: record.recordID.recordName) else { continue }
                cloudIDSet.insert(id)
                
                let cloudDate = record["date"] as? Date ?? Date()
                let cloudTitle = record["title"] as? String ?? ""
                let cloudIsUserTitle = (record["isUserTitle"] as? NSNumber)?.boolValue ?? false
                let cloudUpdated = record["updatedDate"] as? Date ?? Date.distantPast
                
                if let existing = try StoryModelGRDB.filter(key: id).fetchOne(db) {
                    let localUpdated = existing.updatedDate ?? Date.distantPast
                    if cloudUpdated > localUpdated {
                        var model = existing
                        model.date = cloudDate
                        model.title = cloudTitle
                        model.isUserTitle = cloudIsUserTitle
                        model.updatedDate = cloudUpdated
                        try model.update(db)
                    }
                } else {
                    let story = Story(id: id, date: cloudDate, title: cloudTitle, isUserTitle: cloudIsUserTitle)
                    var model = StoryModelGRDB(from: story)
                    model.updatedDate = cloudUpdated
                    try model.insert(db)
                }
            }
            
            // Handle remote deletions
            if let lastSync {
                for local in localStories {
                    if !cloudIDSet.contains(local.id) {
                        let localUpdated = local.updatedDate ?? Date.distantPast
                        if localUpdated < lastSync {
                            // CASCADE will delete associated notes and noteFriends
                            try StoryModelGRDB.deleteOne(db, key: local.id)
                        }
                    }
                }
            }
        }
        
        Logger.log("Downloaded \(records.count) stories", location: .cloudKit, event: .success)
    }
    
    // MARK: - Download Notes
    
    func downloadNotes(from records: [CKRecord]) async throws {
        let lastSync = await getLastDownloadDate()
        
        try await dbPool.write { db in
            let localNotes = try NoteModelGRDB.fetchAll(db)
            var cloudIDSet = Set<UUID>()
            
            for record in records {
                guard let id = UUID(uuidString: record.recordID.recordName) else { continue }
                cloudIDSet.insert(id)
                
                let cloudTitle = record["title"] as? String
                let cloudText = record["text"] as? String ?? ""
                let cloudDate = record["date"] as? Date ?? Date()
                let cloudRootStoryIDStr = record["rootStoryID"] as? String ?? ""
                let cloudOwnerIDStr = record["ownerID"] as? String
                let cloudUpdated = record["updatedDate"] as? Date ?? Date.distantPast
                
                guard let cloudRootStoryID = UUID(uuidString: cloudRootStoryIDStr) else { continue }
                let cloudOwnerID = cloudOwnerIDStr.flatMap { UUID(uuidString: $0) }
                
                // Verify that the referenced story exists
                guard try StoryModelGRDB.filter(key: cloudRootStoryID).fetchCount(db) > 0 else { continue }
                
                // Verify owner exists if specified
                if let ownerID = cloudOwnerID {
                    guard try FriendModelGRDB.filter(key: ownerID).fetchCount(db) > 0 else { continue }
                }
                
                if let existing = try NoteModelGRDB.filter(key: id).fetchOne(db) {
                    let localUpdated = existing.updatedDate ?? Date.distantPast
                    if cloudUpdated > localUpdated {
                        var model = existing
                        model.title = cloudTitle
                        model.text = cloudText
                        model.date = cloudDate
                        model.rootStoryID = cloudRootStoryID
                        model.ownerID = cloudOwnerID
                        model.updatedDate = cloudUpdated
                        try model.update(db)
                    }
                } else {
                    let note = Note(id: id, rootStoryID: cloudRootStoryID, title: cloudTitle, date: cloudDate, text: cloudText, friends: [], owner: nil)
                    var model = NoteModelGRDB(from: note)
                    model.ownerID = cloudOwnerID
                    model.updatedDate = cloudUpdated
                    try model.insert(db)
                }
            }
            
            // Handle remote deletions
            if let lastSync {
                for local in localNotes {
                    if !cloudIDSet.contains(local.id) {
                        let localUpdated = local.updatedDate ?? Date.distantPast
                        if localUpdated < lastSync {
                            try NoteModelGRDB.deleteOne(db, key: local.id)
                        }
                    }
                }
            }
        }
        
        Logger.log("Downloaded \(records.count) notes", location: .cloudKit, event: .success)
    }
    
    // MARK: - Download NoteFriends
    
    func downloadNoteFriends(from records: [CKRecord]) async throws {
        let lastSync = await getLastDownloadDate()
        
        try await dbPool.write { db in
            let localNoteFriends = try NoteFriend.fetchAll(db)
            var cloudKeySet = Set<String>()
            
            for record in records {
                let compositeKey = record.recordID.recordName
                cloudKeySet.insert(compositeKey)
                
                let noteIDStr = record["noteID"] as? String ?? ""
                let friendIDStr = record["friendID"] as? String ?? ""
                let cloudIsSent = (record["isSent"] as? NSNumber)?.boolValue ?? false
                let cloudUpdated = record["updatedDate"] as? Date ?? Date.distantPast
                
                guard let noteID = UUID(uuidString: noteIDStr),
                      let friendID = UUID(uuidString: friendIDStr) else { continue }
                
                // Verify references exist
                guard try NoteModelGRDB.filter(key: noteID).fetchCount(db) > 0,
                      try FriendModelGRDB.filter(key: friendID).fetchCount(db) > 0 else { continue }
                
                if let existing = try NoteFriend
                    .filter(Column("noteID") == noteID && Column("friendID") == friendID)
                    .fetchOne(db) {
                    let localUpdated = existing.updatedDate ?? Date.distantPast
                    if cloudUpdated > localUpdated {
                        var model = existing
                        model.isSent = cloudIsSent
                        model.updatedDate = cloudUpdated
                        try model.update(db)
                    }
                } else {
                    var model = NoteFriend(noteId: noteID, friendId: friendID, isSent: cloudIsSent, updatedDate: cloudUpdated)
                    try model.insert(db)
                }
            }
            
            // Handle remote deletions
            if let lastSync {
                for local in localNoteFriends {
                    let key = "\(local.noteId.uuidString)_\(local.friendId.uuidString)"
                    if !cloudKeySet.contains(key) {
                        let localUpdated = local.updatedDate ?? Date.distantPast
                        if localUpdated < lastSync {
                            try db.execute(
                                sql: "DELETE FROM noteFriend WHERE noteID = ? AND friendID = ?",
                                arguments: [local.noteId, local.friendId]
                            )
                        }
                    }
                }
            }
        }
        
        Logger.log("Downloaded \(records.count) noteFriends", location: .cloudKit, event: .success)
    }
}
