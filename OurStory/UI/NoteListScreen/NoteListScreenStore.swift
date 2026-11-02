//
//  NoteListScreenStore.swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import SwiftUI

@Observable
final class NoteListScreenStore: BaseStore {
    
    private(set) var filter: NoteFilter
    private(set) var showMenuNoteId: UUID? = nil
    private(set) var showFriendsNote: Note? = nil
    
    private var notes: [Note] {
        appStore.notes(for: filter)
    }
    
    var showMenuNote: Note? {
        notes.first(where: { $0.id == showMenuNoteId })
    }
    
    var state: NoteListScreenState {
        NoteListScreenState(notes: notes, allFriends: appStore.allFriends)
    }
    
    init(appStore: AppStore, filter: NoteFilter) {
        self.filter = filter
        super.init(appStore: appStore)
    }
    
    func send(_ action: NoteListScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .editNote(let note):
                appStore.send(.toNote(note))
            case .deleteNote(let note):
                showMenuNoteId = nil
                appStore.send(.deleteNote(note))
            case .updateFriendInNote(let note, let friend):
                let newNote = note.copy(friends: note.friends.deleteOrAppend(friend))
                appStore.send(.editNote(newNote))
            case .selectMenuNote(let id):
                showMenuNoteId = id
            case .selectFriendsNote(let note):
                showFriendsNote = note
            case .updateFilter(let newFilter):
                self.filter = newFilter
            case .addNewFriend:
                appStore.send(.toNewFriend)
            }
        }
    }
}
