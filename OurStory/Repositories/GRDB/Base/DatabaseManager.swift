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
    
    
    
    /// Migration 7:
    /// - Removes rootStoryID from note
    /// - Drops obsolete story table
    private static func runMigration7IfNeeded(in db: Database) throws {
        
        // Fresh installation — nothing to migrate.
        guard try db.tableExists("note") else { return }
        
        // Already migrated.
        let columns = try db.columns(in: "note")
        
        guard columns.contains(where: { $0.name == "rootStoryID" }) else { return }
        
        // Disable FK checks before starting the transaction.
        try db.execute(sql: "PRAGMA foreign_keys = OFF")
        
        do {
            try db.execute(sql: "BEGIN EXCLUSIVE")
            
            do {
                // 1. Create a new note table without rootStoryID.
                try db.execute(sql: """
                    CREATE TABLE note_new (
                        id BLOB PRIMARY KEY NOT NULL,
                        title TEXT,
                        text TEXT NOT NULL,
                        date REAL NOT NULL,
                        ownerID BLOB REFERENCES friend(id)
                            ON DELETE RESTRICT
                            ON UPDATE CASCADE,
                        updatedDate REAL
                    )
                """)
                
                // 2. Copy existing notes.
                try db.execute(sql: """
                    INSERT INTO note_new (
                        id,
                        title,
                        text,
                        date,
                        ownerID,
                        updatedDate
                    )
                    SELECT
                        id,
                        title,
                        text,
                        date,
                        ownerID,
                        updatedDate
                    FROM note
                """)
                
                // 3. Replace the old note table.
                try db.execute(sql: "DROP TABLE note")
                
                try db.execute(sql: """
                    ALTER TABLE note_new RENAME TO note
                """)
                
                // 4. Remove obsolete Story table.
                try db.execute(sql: "DROP TABLE IF EXISTS story")
                
                // 5. Validate foreign key integrity.
                let violations = try Row.fetchAll(
                    db,
                    sql: "PRAGMA foreign_key_check"
                )
                
                guard violations.isEmpty else {
                    throw Migration7Error.foreignKeyViolation(
                        count: violations.count
                    )
                }
                
                // 6. Commit migration.
                try db.execute(sql: "COMMIT")
                
            } catch {
                try? db.execute(sql: "ROLLBACK")
                throw error
            }
            
            // Re-enable FK checks.
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            
            Logger.log(
                "Migration 7: removed rootStoryID and story",
                location: .GRDB,
                event: .success
            )
            
        } catch {
            // Make sure FK checks are enabled even after failure.
            try? db.execute(sql: "PRAGMA foreign_keys = ON")
            throw error
        }
    }
    
    private enum Migration7Error: Error {
        case foreignKeyViolation(count: Int)
    }
}
