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
            // Disable foreign keys to prevent CASCADE deletion
            try db.execute(sql: "PRAGMA foreign_keys = OFF")
            
            // Clean up any leftover temp tables from a previous failed attempt
            try db.execute(sql: "DROP TABLE IF EXISTS note_new")
            try db.execute(sql: "DROP TABLE IF EXISTS noteFriend_new")
            
            let noteCountBefore = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM note") ?? 0
            let nfCountBefore = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM noteFriend") ?? 0
            
            // Check if note table still has rootStoryID (might already be migrated from a partial run)
            let noteColumns = try db.columns(in: "note").map(\.name)
            let needsNoteMigration = noteColumns.contains("rootStoryID")
            
            if needsNoteMigration {
                try db.execute(sql: """
                    CREATE TABLE note_new (
                        id BLOB PRIMARY KEY,
                        title TEXT,
                        text TEXT NOT NULL,
                        date DOUBLE NOT NULL,
                        ownerID BLOB REFERENCES friend(id) ON DELETE RESTRICT ON UPDATE CASCADE,
                        updatedDate DOUBLE
                    )
                """)
                
                try db.execute(sql: """
                    INSERT INTO note_new (id, title, text, date, ownerID, updatedDate)
                    SELECT id, title, text, date, ownerID, updatedDate FROM note
                """)
                
                // Verify note count
                let noteCountAfter = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM note_new") ?? 0
                guard noteCountBefore == noteCountAfter else {
                    try db.execute(sql: "DROP TABLE IF EXISTS note_new")
                    try db.execute(sql: "PRAGMA foreign_keys = ON")
                    fatalError("Migration 7 ABORTED: note count mismatch (\(noteCountBefore) -> \(noteCountAfter))")
                }
                
                try db.execute(sql: "DROP TABLE note")
                try db.execute(sql: "ALTER TABLE note_new RENAME TO note")
            }
            
            // Recreate noteFriend to point FK to the new note table
            try db.execute(sql: """
                CREATE TABLE noteFriend_new (
                    noteID BLOB NOT NULL REFERENCES note(id) ON DELETE CASCADE,
                    friendID BLOB NOT NULL REFERENCES friend(id) ON DELETE CASCADE,
                    isSent BOOLEAN NOT NULL DEFAULT 0,
                    updatedDate DOUBLE,
                    PRIMARY KEY (noteID, friendID)
                )
            """)
            
            // Copy all noteFriend rows as-is (FK checks are OFF, orphans are harmless)
            try db.execute(sql: """
                INSERT INTO noteFriend_new (noteID, friendID, isSent, updatedDate)
                SELECT noteID, friendID, isSent, updatedDate FROM noteFriend
            """)
            
            let nfCountAfter = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM noteFriend_new") ?? 0
            guard nfCountBefore == nfCountAfter else {
                try db.execute(sql: "DROP TABLE IF EXISTS noteFriend_new")
                try db.execute(sql: "PRAGMA foreign_keys = ON")
                fatalError("Migration 7 ABORTED: noteFriend count mismatch (\(nfCountBefore) -> \(nfCountAfter))")
            }
            
            try db.execute(sql: "DROP TABLE noteFriend")
            try db.execute(sql: "ALTER TABLE noteFriend_new RENAME TO noteFriend")
            
            // Drop story table (safe — no more FKs pointing to it)
            try db.execute(sql: "DROP TABLE IF EXISTS story")
            
            // Re-enable foreign keys
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            
            // Mark migration as applied
            var metadata = CloudSyncMetadataGRDB(key: migration7Key, value: "1")
            try metadata.insert(db)
            
            Logger.log("Migration 7: removed story table, dropped rootStoryID from note (notes: \(noteCountBefore), noteFriends: \(nfCountAfter))", location: .GRDB, event: .success)
        }
    }
}
