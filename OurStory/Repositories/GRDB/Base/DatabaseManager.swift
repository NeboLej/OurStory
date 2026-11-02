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
            
            // Migration 7 requires PRAGMA foreign_keys = OFF which only works outside transactions.
            // barrierWriteWithoutTransaction gives us a connection without auto-wrapping in a transaction.
            try dbPool.barrierWriteWithoutTransaction { db in
                try Self.runMigration7IfNeeded(in: db)
            }
            
            try dbPool.write { db in
                try Self.createTablesIfNeeded(in: db)
                try Self.migrate(in: db)
            }
        } catch {
            fatalError("Ошибка создания DatabasePool: \(error)")
        }
    }
    
    /// Creates all tables in their FINAL schema.
    /// Fresh installs get the complete schema; migrations only patch old installs.
    private static func createTablesIfNeeded(in db: Database) throws {
        try db.create(table: "user", ifNotExists: true) { t in
            t.column("id", .blob).primaryKey()
            t.column("name", .text).notNull()
            t.column("color", .text).notNull()
            t.column("updatedDate", .double)
        }
        
        try db.create(table: "friend", ifNotExists: true) { t in
            t.column("id", .blob).primaryKey()
            t.column("name", .text).notNull()
            t.column("color", .text).notNull()
            t.column("userID", .blob)
            t.column("lastSyncDate", .double)
            t.column("updatedDate", .double)
            t.column("isHidden", .boolean).notNull().defaults(to: false)
            
            t.foreignKey(["userID"], references: "user", onDelete: .restrict, onUpdate: .cascade)
        }
        
        try db.create(table: "note", ifNotExists: true) { t in
            t.column("id", .blob).primaryKey()
            t.column("title", .text)
            t.column("text", .text).notNull()
            t.column("date", .double).notNull()
            t.column("ownerID", .blob)
            t.column("updatedDate", .double)
            
            t.foreignKey(["ownerID"], references: "friend", onDelete: .restrict, onUpdate: .cascade)
        }
        
        try db.create(table: "noteFriend", ifNotExists: true) { t in
            t.column("noteID", .blob).notNull().references("note", onDelete: .cascade)
            t.column("friendID", .blob).notNull().references("friend", onDelete: .cascade)
            t.column("isSent", .boolean).notNull().defaults(to: false)
            t.column("updatedDate", .double)
            
            t.primaryKey(["noteID", "friendID"])
        }
        
        try db.create(table: "deletedRecord", ifNotExists: true) { t in
            t.column("recordType", .text).notNull()
            t.column("recordID", .text).notNull()
            t.column("deletionDate", .double).notNull()
            t.primaryKey(["recordType", "recordID"])
        }
        
        try db.create(table: "cloudSyncMetadata", ifNotExists: true) { t in
            t.column("key", .text).primaryKey()
            t.column("value", .text)
            t.column("dataValue", .blob)
        }
    }
    
    /// Patches existing installs to match final schema. Safe to run on fresh installs (no-ops).
    /// Migration 7 runs separately in runMigration7IfNeeded (needs FK OFF outside transaction).
    private static func migrate(in db: Database) throws {
        // Migration 1: Add updatedDate to tables that were created without it
        for table in ["user", "friend", "note", "noteFriend"] {
            guard try db.tableExists(table) else { continue }
            if try !db.columns(in: table).contains(where: { $0.name == "updatedDate" }) {
                try db.alter(table: table) { t in
                    t.add(column: "updatedDate", .double)
                }
            }
        }
        
        // Migration 5: Add isHidden to friend
        if try db.tableExists("friend"),
           try !db.columns(in: "friend").contains(where: { $0.name == "isHidden" }) {
            try db.alter(table: "friend") { t in
                t.add(column: "isHidden", .boolean).notNull().defaults(to: false)
            }
        }
        
        // Migration 6: Add dataValue to cloudSyncMetadata
        if try db.tableExists("cloudSyncMetadata"),
           try !db.columns(in: "cloudSyncMetadata").contains(where: { $0.name == "dataValue" }) {
            try db.alter(table: "cloudSyncMetadata") { t in
                t.add(column: "dataValue", .blob)
            }
        }
    }
    
    /// Runs outside a transaction so PRAGMA foreign_keys = OFF actually takes effect.
    /// Recreates `note` table without `rootStoryID`, preserving all data and noteFriend FK integrity.
    private static func runMigration7IfNeeded(in db: Database) throws {
        // Check if note table exists (fresh install — nothing to migrate)
        guard try db.tableExists("note") else { return }
        
        let migration7Key = "migration_7_remove_story"
        
        // cloudSyncMetadata may not exist yet on first launch after update
        if try db.tableExists("cloudSyncMetadata") {
            let applied = try CloudSyncMetadataGRDB
                .filter(Column("key") == migration7Key)
                .fetchOne(db) != nil
            if applied { return }
        }
        
        // Check if column exists
        let noteColumns = try db.columns(in: "note").map(\.name)
        guard noteColumns.contains("rootStoryID") else {
            // Column already gone (e.g. partial migration) — just mark done
            if try db.tableExists("cloudSyncMetadata") {
                var metadata = CloudSyncMetadataGRDB(key: migration7Key, value: "1")
                try metadata.insert(db)
            }
            return
        }
        
        let noteCountBefore = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM note") ?? 0
        let nfCountBefore = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM noteFriend") ?? 0
        
        // FK OFF must be outside any transaction to take effect
        try db.execute(sql: "PRAGMA foreign_keys = OFF")
        
        defer {
            try? db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        try db.execute(sql: "BEGIN EXCLUSIVE")
        
        do {
            // 1. Recreate note without rootStoryID
            try db.execute(sql: """
                CREATE TABLE note_new (
                    id BLOB PRIMARY KEY,
                    title TEXT,
                    text TEXT NOT NULL,
                    date REAL NOT NULL,
                    ownerID BLOB REFERENCES friend(id) ON DELETE RESTRICT ON UPDATE CASCADE,
                    updatedDate REAL
                )
            """)
            
            try db.execute(sql: """
                INSERT INTO note_new (id, title, text, date, ownerID, updatedDate)
                SELECT id, title, text, date, ownerID, updatedDate FROM note
            """)
            
            let noteCountNew = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM note_new") ?? 0
            guard noteCountBefore == noteCountNew else {
                try db.execute(sql: "ROLLBACK")
                fatalError("Migration 7: note count mismatch (\(noteCountBefore) -> \(noteCountNew))")
            }
            
            // 2. Recreate noteFriend pointing to note_new
            try db.execute(sql: """
                CREATE TABLE noteFriend_new (
                    noteID BLOB NOT NULL REFERENCES note_new(id) ON DELETE CASCADE,
                    friendID BLOB NOT NULL REFERENCES friend(id) ON DELETE CASCADE,
                    isSent BOOLEAN NOT NULL DEFAULT 0,
                    updatedDate REAL,
                    PRIMARY KEY (noteID, friendID)
                )
            """)
            
            try db.execute(sql: "INSERT INTO noteFriend_new SELECT * FROM noteFriend")
            
            let nfCountNew = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM noteFriend_new") ?? 0
            guard nfCountBefore == nfCountNew else {
                try db.execute(sql: "ROLLBACK")
                fatalError("Migration 7: noteFriend count mismatch (\(nfCountBefore) -> \(nfCountNew))")
            }
            
            // 3. Swap tables
            try db.execute(sql: "DROP TABLE noteFriend")
            try db.execute(sql: "DROP TABLE note")
            try db.execute(sql: "DROP TABLE IF EXISTS story")
            try db.execute(sql: "ALTER TABLE note_new RENAME TO note")
            try db.execute(sql: "ALTER TABLE noteFriend_new RENAME TO noteFriend")
            
            // 4. Mark migration applied (table might not exist yet)
            if try db.tableExists("cloudSyncMetadata") {
                var metadata = CloudSyncMetadataGRDB(key: migration7Key, value: "1")
                try metadata.insert(db)
            }
            
            try db.execute(sql: "COMMIT")
            
            Logger.log("Migration 7: removed rootStoryID, dropped story (notes: \(noteCountNew), noteFriends: \(nfCountNew))", location: .GRDB, event: .success)
        } catch {
            try? db.execute(sql: "ROLLBACK")
            throw error
        }
    }
}
