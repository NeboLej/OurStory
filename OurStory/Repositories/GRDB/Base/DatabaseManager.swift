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
        
        try db.create(table: "story", ifNotExists: true) { t in
            t.column("id", .blob).primaryKey()
            t.column("date", .double).notNull()
            t.column("title", .text)
            t.column("isUserTitle", .boolean).notNull()
        }
        
        try db.create(table: "note", ifNotExists: true) { t in
            t.column("id", .blob).primaryKey()
            t.column("title", .text)
            t.column("text", .text).notNull()
            t.column("date", .double).notNull()
            t.column("ownerID", .blob)
            
            t.column("rootStoryID", .blob).notNull()
            t.foreignKey(["rootStoryID"], references: "story", onDelete: .cascade, onUpdate: .cascade)
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
        let tablesToMigrate = ["user", "friend", "story", "note", "noteFriend"]
        
        for table in tablesToMigrate {
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
        }
    }
}
