//
//  FriendScreenStore.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import Foundation

@Observable
final class FriendScreenStore: BaseStore {
    
    private let friend: Friend
    
    @ObservationIgnored
    private var noteRepositpry: NoteRepositoryProtocol
    
    var state: FriendScreenState { FriendScreenState(friend: friend) }
    
    init(appStore: AppStore, friend: Friend, noteRepositpry: NoteRepositoryProtocol) {
        self.friend = friend
        self.noteRepositpry = noteRepositpry
        super.init(appStore: appStore)
        
        loadData()
    }
    
    
    private func loadData() {
//        noteRepositpry.
    }
}
