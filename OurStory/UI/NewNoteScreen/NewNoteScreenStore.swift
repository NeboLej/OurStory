//
//  NewNoteScreenStore.swift
//  OurStory
//
//  Created by Nebo on 04.09.2026.
//

import SwiftUI

@Observable
final class NewNoteScreenStore: BaseStore {
    
    private var title: String? = nil
    private var text: String = ""
    private var date: Date = Date()
    private var allFriends: [Friend] = []
    private var selectedFriends: [Friend] = []
    
    var state: NewNoteScreenState {
        NewNoteScreenState(title: title, text: text, date: date, allFriends: appStore.allFriends, selectedFriends: selectedFriends)
    }
    
    override init(appStore: AppStore) {
        super.init(appStore: appStore)
         
        if let localNote = loadLocalNote() {
            title = localNote.title
            text = localNote.text
            date = localNote.date
            selectedFriends = localNote.friends
        }
    }
    
    func send(_ action: NewNoteScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .selectFriends(let friends):
                selectedFriends = friends
            case .saveNote(title: let title, text: let text):
                let newNote = Note(title: title, date: date, text: text, friends: selectedFriends, owner: nil)
                appStore.send(.addNewNote(newNote))
            }
        }
    }
    
    private func loadLocalNote() -> Note? {
        nil
    }
}
