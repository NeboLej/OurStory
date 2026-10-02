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
    func getTotalNotes(friendID: UUID) async -> [Note]
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
                noteModel.updatedDate = Date()
                try noteModel.insert(db)
               
                try note.friends.forEach { friend in
                    var link = NoteFriend(noteId: noteModel.id, friendId: friend.id, isSent: false, updatedDate: Date())
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
                    var mutable = NoteModelGRDB(from: note)
                    mutable.updatedDate = Date()
                    try mutable.update(db)
                    
                    // Пересоздаём связи noteFriend
                    try db.execute(sql: "DELETE FROM noteFriend WHERE noteID = ?", arguments: [note.id])
                    try note.friends.forEach { friend in
                        var link = NoteFriend(noteId: note.id, friendId: friend.id, isSent: false, updatedDate: Date())
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
    
    func getTotalNotes(friendID: UUID) async -> [Note] {
        do {
            return try await dbPool.read { db in
                // Мои заметки где друг в списке friends (через noteFriend)
                let myNotesRequest = NoteModelGRDB
                    .joining(
                        required: NoteModelGRDB.noteFriends
                            .filter(Column("friendID") == friendID)
                    )
                    .including(optional: NoteModelGRDB.owner)
                    .including(all: NoteModelGRDB.friends)
                let myNotes = try NoteWithFriends.fetchAll(db, myNotesRequest)
                
                // Заметки где друг является owner
                let ownerNotesRequest = NoteModelGRDB
                    .filter(Column("ownerID") == friendID)
                    .including(optional: NoteModelGRDB.owner)
                    .including(all: NoteModelGRDB.friends)
                let ownerNotes = try NoteWithFriends.fetchAll(db, ownerNotesRequest)
                
                // Объединяем и убираем дубликаты по id
                let allNotes = myNotes + ownerNotes
                var seen = Set<UUID>()
                return allNotes.compactMap { noteWithFriends -> Note? in
                    let note = Note(from: noteWithFriends)
                    guard seen.insert(note.id).inserted else { return nil }
                    return note
                }
            }
        } catch {
            Logger.log("getTotalNotes error", location: .GRDB, event: .error(error))
            return []
        }
    }
    
    func updateSentStatus(noteIDs: [UUID], friendID: UUID, isSent: Bool) async {
        guard !noteIDs.isEmpty else { return }
        do {
            try await dbPool.write { db in
                let placeholders = noteIDs.map { _ in "?" }.joined(separator: ",")
                let now = Date().timeIntervalSinceReferenceDate
                try db.execute(
                    sql: "UPDATE noteFriend SET isSent = ?, updatedDate = ? WHERE friendID = ? AND noteID IN (\(placeholders))",
                    arguments: StatementArguments([isSent.databaseValue, now.databaseValue, friendID.databaseValue] + noteIDs.map { $0.databaseValue })
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
                let now = Date().timeIntervalSinceReferenceDate
                try db.execute(
                    sql: "UPDATE noteFriend SET isSent = 0, updatedDate = ? WHERE noteID = ?",
                    arguments: [now, noteID]
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
                    var mutable = NoteModelGRDB(from: note)
                    mutable.updatedDate = Date()
                    try mutable.update(db)
                    Logger.log("saveOrUpdateNote: updated existing note", location: .GRDB, event: .success)
                } else {
                    var noteModel = NoteModelGRDB(from: note)
                    noteModel.updatedDate = Date()
                    try noteModel.insert(db)
                    Logger.log("saveOrUpdateNote: inserted new note", location: .GRDB, event: .success)
                }
                
                try db.execute(sql: "DELETE FROM noteFriend WHERE noteID = ?", arguments: [note.id])
                
                try note.friends.forEach { friend in
                    var link = NoteFriend(noteId: note.id, friendId: friend.id, isSent: false, updatedDate: Date())
                    try link.insert(db)
                }
            }
        } catch {
            Logger.log("saveOrUpdateNote error", location: .GRDB, event: .error(error))
        }
    }
}
