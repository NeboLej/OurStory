//
//  StoryModelGRDB.swift
//  OurStory
//
//  Created by Nebo on 15.09.2026.
//

import Foundation
import GRDB

struct StoryWithNotes: FetchableRecord, Decodable {
    var story: StoryModelGRDB
    var notes: [NoteWithFriends]
}

struct StoryModelGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord   {
    
    static let databaseTableName = "story"
    
    var id: UUID
    var date: Date
    var title: String
    var isUserTitle: Bool
    
    var notes: [NoteModelGRDB]?
    
    mutating func didInsert(with rowID: Int64, for column: String?) { }
    
    enum CodingKeys: CodingKey {
        case id, date, title, isUserTitle
        case notes
    }
    
    init(from: Story) {
        id = from.id
        date = from.date
        title = from.title
        isUserTitle = from.isUserTitle
    }
}

extension StoryModelGRDB {
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["date"] = date
        container["title"] = title
        container["isUserTitle"] = isUserTitle
    }
}

extension StoryModelGRDB {
    static let notes = hasMany(NoteModelGRDB.self, using: ForeignKey(["rootStoryID"]))
}
