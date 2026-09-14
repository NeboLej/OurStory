//
//  UserModelGRDB.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

struct UserModelGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "user"
    
    var id: UUID
    var name: String
    var color: String
    
    mutating func didInsert(with rowID: Int64, for column: String?) { }
    
    init(from: User) {
        id = from.id
        name = from.name
        color = from.color
    }
}

//extension UserModelGRDB: UserProtocol {}

//extension UserModelGRDB {
//    func encode(to container: inout PersistenceContainer) {
//        container["id"] = id
//        container["name"] = name
//        container["color"] = color
//    }
//}
