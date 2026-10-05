//
//  NoteListScreenStore.swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import SwiftUI

@Observable
final class NoteListScreenStore: BaseStore {
    
    private var localNotes: [Note]
    private var storyID: UUID?
    private(set) var showMenuNoteId: UUID? = nil
    private(set) var showFriendsNote: Note? = nil
    
    private var notes: [Note] {
        if let storyID,
           let story = appStore.stories.values.first(where: { $0.id == storyID }) {
            return story.notes
        }
        return localNotes
    }
    
    var showMenuNote: Note? {
        notes.first(where: { $0.id == showMenuNoteId })
    }
    
    var state: NoteListScreenState {
        NoteListScreenState(notes: notes, allFriends: appStore.allFriends)
    }
    
    init(appStore: AppStore, notes: [Note] = [], storyID: UUID? = nil) {
        self.localNotes = notes
        self.storyID = storyID
        super.init(appStore: appStore)
    }
    
    func send(_ action: NoteListScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .editNote(let note):
                appStore.send(.toNote(note))
            case .updateFriendInNote(let note, let friend):
                let newNote = note.copy(friends: note.friends.deleteOrAppend(friend))
                appStore.send(.editNote(newNote))
            case .selectMenuNote(let id):
                showMenuNoteId = id
            case .selectFriendsNote(let note):
                showFriendsNote = note
            case .updateNotes(let notes):
                self.localNotes = notes.sorted { $0.date > $1.date }
            case .addNewFriend:
                appStore.send(.toNewFriend)
            }
        }
    }
}
