//
//  HomeScreenStore.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import SwiftUI

@Observable
final class HomeScreenStore: BaseStore {
    
    var state: HomeScreenState { HomeScreenState(appStore: appStore) }
    
    func send(_ action: HomeScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .openScreen: print("OpenScreen")
            case .createNewNote: appStore.send(.toNote(nil))
            case .updateFriendInNote(let note, let friend):
                let newNote = note.copy(friends: note.friends.deleteOrAppend(friend))
                appStore.send(.editNote(newNote))
            case .editNote(let note): appStore.send(.toNote(note))
                
            }
        }
    }
}
