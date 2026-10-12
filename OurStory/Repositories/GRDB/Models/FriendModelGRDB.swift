//
//  FriendModelGRDB.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

struct FriendModelGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "friend"
    
    var id: UUID
    var name: String
    var color: String
    
    var userID: UUID?
    var user: UserModelGRDB?
    var lastSyncDate: Date?
    var updatedDate: Date?
    var isHidden: Bool
    
    mutating func didInsert(with rowID: Int64, for column: String?) { }
    
    init(from: Friend, userID: UUID?) {
        id = from.id
        name = from.name
        color = from.color
        self.userID = userID
        self.lastSyncDate = from.lastSyncDate
        self.updatedDate = Date()
        self.isHidden = from.isHidden
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, color, userID, user, lastSyncDate, updatedDate, isHidden
    }
}

extension FriendModelGRDB {
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["name"] = name
        container["color"] = color
        container["userID"] = userID
        container["lastSyncDate"] = lastSyncDate
        container["updatedDate"] = updatedDate
        container["isHidden"] = isHidden
    }
}

extension FriendModelGRDB {
    static let user = belongsTo(UserModelGRDB.self, using: ForeignKey(["userID"]))
}
