//
//  NoteModelGRDB.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

struct NoteFriend: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "noteFriend"
    var noteId: UUID
    var friendId: UUID
    var isSent: Bool
    var updatedDate: Date?
    
    static let friend = belongsTo(FriendModelGRDB.self)
    
    func encode(to container: inout PersistenceContainer) {
        container["noteID"] = noteId
        container["friendID"] = friendId
        container["isSent"] = isSent
        container["updatedDate"] = updatedDate
    }
}

struct NoteWithFriends: FetchableRecord, Decodable {
    var note: NoteModelGRDB
    var friends: [FriendModelGRDB]
}

struct NoteModelGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "note"
    
    var id: UUID
    var title: String?
    var date: Date
    var text: String
    
    var rootStoryID: UUID
    var ownerID: UUID?
    var owner: FriendModelGRDB?
    var updatedDate: Date?
    
    mutating func didInsert(with rowID: Int64, for column: String?) { }
    
    init(from: Note) {
        id = from.id
        title = from.title
        date = from.date
        text = from.text
        rootStoryID = from.rootStoryID
        ownerID = from.owner?.id
        updatedDate = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, date, text, rootStoryID, ownerID, updatedDate
        case owner
    }
}

extension NoteModelGRDB {
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["title"] = title
        container["date"] = date
        container["text"] = text
        container["rootStoryID"] = rootStoryID
        container["ownerID"] = ownerID
        container["updatedDate"] = updatedDate
    }
}

extension NoteModelGRDB {
    static let noteFriends = hasMany(NoteFriend.self)
    static let friends = hasMany(FriendModelGRDB.self, through: noteFriends, using: NoteFriend.friend)
    static let owner = belongsTo(FriendModelGRDB.self, using: ForeignKey(["ownerID"])).forKey("owner")
}
