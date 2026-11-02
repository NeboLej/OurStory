//
//  DatabaseManager.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    let dbPool: DatabasePool
    
    private init() {
        let databaseURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ourSroryApp.sqlite")
        
        var config = Configuration()
        
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        do {
            dbPool = try DatabasePool(path: databaseURL.path, configuration: config)
            
            try dbPool.write { db in
                try Self.createTablesIfNeeded(in: db)
                try Self.migrate(in: db)
            }
        } catch {
            fatalError("Ошибка создания DatabasePool: \(error)")
        }
    }
    
    private static func createTablesIfNeeded(in db: Database) throws {
        try db.create(table: "user", ifNotExists: true) { t in
            t.column("id", .blob).primaryKey()
            t.column("name", .text).notNull()
            t.column("color", .text).notNull()
        }
        
        try db.create(table: "friend", ifNotExists: true) { t in
            t.column("id", .blob).primaryKey()
            t.column("name", .text).notNull()
            t.column("color", .text).notNull()
            t.column("userID", .blob)
            t.column("lastSyncDate", .double)
            
            t.foreignKey(["userID"], references: "user", onDelete: .restrict, onUpdate: .cascade)
        }
        
        // story table removed in migration 7
        // For fresh installs, create note table directly without rootStoryID
        try db.create(table: "note", ifNotExists: true) { t in
            t.column("id", .blob).primaryKey()
            t.column("title", .text)
            t.column("text", .text).notNull()
            t.column("date", .double).notNull()
            t.column("ownerID", .blob)
            
            t.foreignKey(["ownerID"], references: "friend", onDelete: .restrict, onUpdate: .cascade)
        }
        
        try db.create(table: "noteFriend", ifNotExists: true) { t in
            t.column("noteID", .blob).notNull().references("note", onDelete: .cascade)
            t.column("friendID", .blob).notNull().references("friend", onDelete: .cascade)
            t.column("isSent", .boolean).notNull().defaults(to: false)
            
            t.primaryKey(["noteID", "friendID"])
        }
    }
    
    private static func migrate(in db: Database) throws {
        // Migration 1: Add updatedDate to all mutable tables
        let tablesToMigrate = ["user", "friend", "note", "noteFriend"]
        
        for table in tablesToMigrate {
            guard try db.tableExists(table) else { continue }
            if try db.columns(in: table).contains(where: { $0.name == "updatedDate" }) == false {
                try db.alter(table: table) { t in
                    t.add(column: "updatedDate", .double)
                }
                try db.execute(sql: "UPDATE \(table) SET updatedDate = ? WHERE updatedDate IS NULL",
                              arguments: [Date().timeIntervalSinceReferenceDate])
            }
        }
        
        // Migration 2: Create deletedRecord tracking table for cloud sync
        try db.create(table: "deletedRecord", ifNotExists: true) { t in
            t.column("recordType", .text).notNull()
            t.column("recordID", .text).notNull()
            t.column("deletionDate", .double).notNull()
            t.primaryKey(["recordType", "recordID"])
        }
        
        // Migration 3: Create cloudSyncMetadata table for tracking last sync times
        try db.create(table: "cloudSyncMetadata", ifNotExists: true) { t in
            t.column("key", .text).primaryKey()
            t.column("value", .text)
            t.column("dataValue", .blob)
        }
        
        // Migration 4: Mark all notes as unsent to force re-sync in next version
        let migrationKey = "migration_4_reset_isSent"
        let alreadyApplied = try CloudSyncMetadataGRDB
            .filter(Column("key") == migrationKey)
            .fetchOne(db) != nil
        
        if !alreadyApplied {
            try db.execute(sql: "UPDATE noteFriend SET isSent = 0, updatedDate = ?",
                          arguments: [Date().timeIntervalSinceReferenceDate])
            var metadata = CloudSyncMetadataGRDB(key: migrationKey, value: "1")
            try metadata.insert(db)
        }
        
        // Migration 5: Add isHidden column to friend table
        if try db.columns(in: "friend").contains(where: { $0.name == "isHidden" }) == false {
            try db.alter(table: "friend") { t in
                t.add(column: "isHidden", .boolean).notNull().defaults(to: false)
            }
        }
        
        // Migration 6: Add dataValue column to cloudSyncMetadata for binary data (CKServerChangeToken)
        if try db.columns(in: "cloudSyncMetadata").contains(where: { $0.name == "dataValue" }) == false {
            try db.alter(table: "cloudSyncMetadata") { t in
                t.add(column: "dataValue", .blob)
            }
        }
        
        // Migration 7: Remove story table, drop rootStoryID from note
        let migration7Key = "migration_7_remove_story"
        let migration7Applied = try CloudSyncMetadataGRDB
            .filter(Column("key") == migration7Key)
            .fetchOne(db) != nil
        
        if !migration7Applied {
            let noteCountBefore = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM note") ?? 0
            let nfCountBefore = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM noteFriend") ?? 0
            
            // Drop rootStoryID column from note using ALTER TABLE DROP COLUMN (SQLite 3.35+, iOS 15+).
            // This preserves all data and does NOT trigger CASCADE deletes on noteFriend.
            let noteColumns = try db.columns(in: "note").map(\.name)
            if noteColumns.contains("rootStoryID") {
                try db.execute(sql: "ALTER TABLE note DROP COLUMN rootStoryID")
            }
            
            // Drop story table — noteFriend has no FK to story, safe to drop.
            // note no longer references story either (rootStoryID column removed above).
            try db.execute(sql: "DROP TABLE IF EXISTS story")
            
            // Verify data integrity
            let noteCountAfter = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM note") ?? 0
            let nfCountAfter = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM noteFriend") ?? 0
            
            guard noteCountBefore == noteCountAfter else {
                fatalError("Migration 7 ABORTED: note count mismatch (\(noteCountBefore) -> \(noteCountAfter))")
            }
            guard nfCountBefore == nfCountAfter else {
                fatalError("Migration 7 ABORTED: noteFriend count mismatch (\(nfCountBefore) -> \(nfCountAfter))")
            }
            
            // Mark migration as applied
            var metadata = CloudSyncMetadataGRDB(key: migration7Key, value: "1")
            try metadata.insert(db)
            
            Logger.log("Migration 7: dropped rootStoryID column, removed story table (notes: \(noteCountAfter), noteFriends: \(nfCountAfter))", location: .GRDB, event: .success)
        }
    }
}
