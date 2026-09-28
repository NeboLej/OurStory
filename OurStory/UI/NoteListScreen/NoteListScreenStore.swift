//
//  NoteListScreenStore.swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import SwiftUI

@Observable
final class NoteListScreenStore: BaseStore {
    
    private var notes: [Note]
    
    var showMenuNoteId: UUID? = nil
    var showFriendsNote: Note? = nil
    var isShowFriendsList: Bool = false
    
    var showMenuNote: Note? {
        notes.first(where: { $0.id == showMenuNoteId })
    }
    
    var state: NoteListScreenState {
        NoteListScreenState(notes: notes, allFriends: appStore.allFriends)
    }
    
    init(appStore: AppStore, notes: [Note] = []) {
        self.notes = notes
        super.init(appStore: appStore)
    }
    
    func updateNotes(_ notes: [Note]) {
        self.notes = notes
    }
    
    func send(_ action: NoteListScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .editNote(let note):
                appStore.send(.toNote(note))
            case .updateFriendInNote(let note, let friend):
                let newNote = note.copy(friends: note.friends.deleteOrAppend(friend))
                appStore.send(.editNote(newNote))
            }
        }
    }
}
