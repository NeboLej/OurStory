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
    
    static let friend = belongsTo(FriendModelGRDB.self)
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
    
    mutating func didInsert(with rowID: Int64, for column: String?) { }
    
    init(from: Note) {
        id = from.id
        title = from.title
        date = from.date
        text = from.text
        rootStoryID = from.rootStoryID
        ownerID = from.owner?.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, date, text, rootStoryID, ownerID
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
    }
}

extension NoteModelGRDB {
    static let noteFriends = hasMany(NoteFriend.self)
    static let friends = hasMany(FriendModelGRDB.self, through: noteFriends, using: NoteFriend.friend)
    static let owner = belongsTo(FriendModelGRDB.self, using: ForeignKey(["ownerID"])).forKey("owner")
}
