//
//  CloudSyncMetadataGRDB.swift
//  OurStory
//

import Foundation
import GRDB

struct CloudSyncMetadataGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "cloudSyncMetadata"
    
    var key: String
    var value: String?
    
    func encode(to container: inout PersistenceContainer) {
        container["key"] = key
        container["value"] = value
    }
}
