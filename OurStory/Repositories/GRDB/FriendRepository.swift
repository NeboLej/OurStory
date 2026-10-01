//
//  FriendRepository.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

final class FriendRepository: BaseRepository, FriendRepositoryProtocol {
    
    func getAllFriends() async -> [Friend] {
        do {
            return try await dbPool.read { db in
                let friends = try FriendModelGRDB
                    .including(optional: FriendModelGRDB.user)
                    .fetchAll(db).map { Friend(from: $0) }
                Logger.log("get \(friends.count) friends", location: .GRDB, event: .success)
                return friends
            }
        } catch {
            Logger.log("Failed to get all friends", location: .GRDB, event: .error(error))
            return []
        }
    }
    
    func addNewFriend(_ friend: Friend) async {
        do {
            try await dbPool.write { db in
                var model = FriendModelGRDB(from: friend, userID: friend.user?.id)
                model.updatedDate = Date()
                try model.insert(db)
                Logger.log("save new friend", location: .GRDB, event: .success)
            }
        } catch {
            Logger.log("save new user", location: .GRDB, event: .error(error))
            fatalError()
        }
    }
    
    func editFriend(_ friend: Friend) async {
        do {
            try await dbPool.write { db in
                if try FriendModelGRDB.filter(key: friend.id).fetchCount(db) != 0 {
                    var model = FriendModelGRDB(from: friend, userID: friend.user?.id)
                    model.updatedDate = Date()
                    try model.update(db)
                    Logger.log("edit friend \(friend.name)", location: .GRDB, event: .success)
                } else {
                    Logger.log("edit friend error. friend not found", location: .GRDB, event: .error(nil))
                }
            }
        } catch {
            Logger.log("save new user", location: .GRDB, event: .error(error))
            fatalError()
        }
    }
    
    func deleteFriend(_ friend: Friend) async {
        do {
            try await dbPool.write { db in
                // Track noteFriend deletions for cloud sync before cascade
                let noteFriendRows = try NoteFriend
                    .filter(Column("friendID") == friend.id)
                    .fetchAll(db)
                
                let now = Date().timeIntervalSinceReferenceDate
                for nf in noteFriendRows {
                    let compositeKey = "\(nf.noteId.uuidString)_\(nf.friendId.uuidString)"
                    try db.execute(
                        sql: "INSERT OR REPLACE INTO deletedRecord (recordType, recordID, deletionDate) VALUES (?, ?, ?)",
                        arguments: ["CD_NoteFriend", compositeKey, now]
                    )
                }
                
                // Track friend deletion for cloud sync
                try db.execute(
                    sql: "INSERT OR REPLACE INTO deletedRecord (recordType, recordID, deletionDate) VALUES (?, ?, ?)",
                    arguments: ["CD_Friend", friend.id.uuidString, now]
                )
                
                if try FriendModelGRDB.deleteOne(db, key: friend.id) {
                    Logger.log("Success to delete friend", location: .GRDB, event: .success)
                }
            }
        } catch {
            Logger.log("Failed to delete friend", location: .GRDB, event: .error(error))
        }
    }
}
