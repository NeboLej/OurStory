//
//  DeletedRecordModelGRDB.swift
//  OurStory
//

import Foundation
import GRDB

struct DeletedRecordModelGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "deletedRecord"
    
    var recordType: String
    var recordID: String
    var deletionDate: Date
    
    func encode(to container: inout PersistenceContainer) {
        container["recordType"] = recordType
        container["recordID"] = recordID
        container["deletionDate"] = deletionDate
    }
}
