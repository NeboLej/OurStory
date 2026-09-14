//
//  NoteRepositoryProtocol.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

protocol NoteRepositoryProtocol {
    func getAllNotes() async -> [Note]
    func addNote(_ note: Note) async
}

final class NoteRepository: BaseRepository, NoteRepositoryProtocol {
    
    func addNote(_ note: Note) async {
        do {
            try await dbPool.write { db in
                var noteModel = NoteModelGRDB(from: note)
                try noteModel.insert(db)
               
                try note.friends.forEach { friend in
                    var link = NoteFriend(noteId: noteModel.id, friendId: friend.id)
                    try link.insert(db)
                }
                
                Logger.log("save new note", location: .GRDB, event: .success)
            }
        } catch {
            fatalError()
        }
    }
    
    func getAllNotes() async -> [Note] {
        do {
            return try await dbPool.read { db in
                let request = NoteModelGRDB.including(all: NoteModelGRDB.friends.including(optional: FriendModelGRDB.user))
                let results = try NoteWithFriends.fetchAll(db, request)
                
                return results.map { Note(from: $0) }
            }
        } catch {
            fatalError()
        }
    }
}
