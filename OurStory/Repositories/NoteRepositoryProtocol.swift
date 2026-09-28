//
//  NoteRepositoryProtocol.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

protocol NoteRepositoryProtocol {
//    func getAllNotes() async -> [Note]
    func addNote(_ note: Note) async
    func saveOrUpdateNote(_ note: Note) async
    func updateNote(_ note: Note) async
    func getNotes(friendID: UUID) async -> [Note]
    func getUnsentNotes(friendID: UUID) async -> [Note]
    func getTotalNotesCount(friendID: UUID) async -> Int
    func getUnsentNotesCount(friendID: UUID) async -> Int
    func updateSentStatus(noteIDs: [UUID], friendID: UUID, isSent: Bool) async
    func resetSentStatus(noteID: UUID) async
}

final class NoteRepository: BaseRepository, NoteRepositoryProtocol {
    
    func addNote(_ note: Note) async {
        do {
            try await dbPool.write { db in
                if try NoteModelGRDB.filter(key: note.id).fetchOne(db) != nil {
                    Logger.log("note not unique", location: .GRDB, event: .error(nil))
                    return
                }
                
                var noteModel = NoteModelGRDB(from: note)
                try noteModel.insert(db)
               
                try note.friends.forEach { friend in
                    var link = NoteFriend(noteId: noteModel.id, friendId: friend.id, isSent: false)
                    try link.insert(db)
                }
                
                Logger.log("save new note", location: .GRDB, event: .success)
            }
        } catch {
            fatalError()
        }
    }
    
    func updateNote(_ note: Note) async {
        do {
            try await dbPool.write { db in
                if try NoteModelGRDB.filter(key: note.id).fetchCount(db) != 0 {
                    let mutable = NoteModelGRDB(from: note)
                    try mutable.update(db)
                    
                    // Пересоздаём связи noteFriend
                    try db.execute(sql: "DELETE FROM noteFriend WHERE noteID = ?", arguments: [note.id])
                    try note.friends.forEach { friend in
                        var link = NoteFriend(noteId: note.id, friendId: friend.id, isSent: false)
                        try link.insert(db)
                    }
                    
                    Logger.log("update note", location: .GRDB, event: .success)
                } else {
                    Logger.log("update note error. plant not found", location: .GRDB, event: .error(nil))
                }
            }
        } catch {
            fatalError()
        }
    }
    
    private func getAllNotes() async -> [Note] {
        do {
            return try await dbPool.read { db in
                let request = NoteModelGRDB.including(all: NoteModelGRDB.friends.including(optional: FriendModelGRDB.user))
                    .including(optional: NoteModelGRDB.owner.including(optional: FriendModelGRDB.user))
                let results = try NoteWithFriends.fetchAll(db, request)
                
                return results.map { Note(from: $0) }
            }
        } catch {
            fatalError()
        }
    }
    
    func getNotes(friendID: UUID) async -> [Note] {
        do {
            return try await dbPool.read { db in
                let request = NoteModelGRDB
                    .joining(
                        required: NoteModelGRDB.noteFriends
                            .filter(Column("friendID") == friendID)
                    )
                    .including(optional: NoteModelGRDB.owner)
                    .including(all: NoteModelGRDB.friends)

                let notes = try NoteWithFriends.fetchAll(db, request)
                return notes.map { Note(from: $0) }
            }
        } catch {
            Logger.log("getNotes error", location: .GRDB, event: .error(error))
            fatalError("\(error)")
        }
    }
    
    func getUnsentNotes(friendID: UUID) async -> [Note] {
        do {
            return try await dbPool.read { db in
                let request = NoteModelGRDB
                    .joining(
                        required: NoteModelGRDB.noteFriends
                            .filter(Column("friendID") == friendID)
                            .filter(Column("isSent") == false)
                    )
                    .including(optional: NoteModelGRDB.owner)
                    .including(all: NoteModelGRDB.friends)

                let notes = try NoteWithFriends.fetchAll(db, request)
                return notes.map { Note(from: $0) }
            }
        } catch {
            Logger.log("getUnsentNotes error", location: .GRDB, event: .error(error))
            fatalError("\(error)")
        }
    }
    
    func getTotalNotesCount(friendID: UUID) async -> Int {
        do {
            return try await dbPool.read { db in
                // Мои заметки где друг в списке friends (через noteFriend)
                let myNotesCount = try NoteModelGRDB
                    .joining(
                        required: NoteModelGRDB.noteFriends
                            .filter(Column("friendID") == friendID)
                    )
                    .fetchCount(db)
                
                // Заметки где друг является owner
                let ownerNotesCount = try NoteModelGRDB
                    .filter(Column("ownerID") == friendID)
                    .fetchCount(db)
                
                return myNotesCount + ownerNotesCount
            }
        } catch {
            Logger.log("getTotalNotesCount error", location: .GRDB, event: .error(error))
            return 0
        }
    }
    
    func getUnsentNotesCount(friendID: UUID) async -> Int {
        do {
            return try await dbPool.read { db in
                try NoteModelGRDB
                    .joining(
                        required: NoteModelGRDB.noteFriends
                            .filter(Column("friendID") == friendID)
                            .filter(Column("isSent") == false)
                    )
                    .fetchCount(db)
            }
        } catch {
            Logger.log("getUnsentNotesCount error", location: .GRDB, event: .error(error))
            return 0
        }
    }
    
    func updateSentStatus(noteIDs: [UUID], friendID: UUID, isSent: Bool) async {
        guard !noteIDs.isEmpty else { return }
        do {
            try await dbPool.write { db in
                let placeholders = noteIDs.map { _ in "?" }.joined(separator: ",")
                try db.execute(
                    sql: "UPDATE noteFriend SET isSent = ? WHERE friendID = ? AND noteID IN (\(placeholders))",
                    arguments: StatementArguments([isSent.databaseValue, friendID.databaseValue] + noteIDs.map { $0.databaseValue })
                )
                Logger.log("updateSentStatus isSent=\(isSent)", location: .GRDB, event: .success)
            }
        } catch {
            Logger.log("updateSentStatus error", location: .GRDB, event: .error(error))
        }
    }
    
    func resetSentStatus(noteID: UUID) async {
        do {
            try await dbPool.write { db in
                try db.execute(
                    sql: "UPDATE noteFriend SET isSent = 0 WHERE noteID = ?",
                    arguments: [noteID]
                )
                Logger.log("resetSentStatus", location: .GRDB, event: .success)
            }
        } catch {
            Logger.log("resetSentStatus error", location: .GRDB, event: .error(error))
        }
    }
    
    func saveOrUpdateNote(_ note: Note) async {
        do {
            try await dbPool.write { db in
                if try NoteModelGRDB.filter(key: note.id).fetchOne(db) != nil {
                    let mutable = NoteModelGRDB(from: note)
                    try mutable.update(db)
                    Logger.log("saveOrUpdateNote: updated existing note", location: .GRDB, event: .success)
                } else {
                    var noteModel = NoteModelGRDB(from: note)
                    try noteModel.insert(db)
                    Logger.log("saveOrUpdateNote: inserted new note", location: .GRDB, event: .success)
                }
                
                try db.execute(sql: "DELETE FROM noteFriend WHERE noteID = ?", arguments: [note.id])
                
                try note.friends.forEach { friend in
                    var link = NoteFriend(noteId: note.id, friendId: friend.id, isSent: false)
                    try link.insert(db)
                }
            }
        } catch {
            Logger.log("saveOrUpdateNote error", location: .GRDB, event: .error(error))
        }
    }
}
