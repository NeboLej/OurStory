//
//  FriendScreenStore.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import SwiftUI

@Observable
final class FriendScreenStore: BaseStore {
    
    private var friend: Friend
    
    var syncService: SyncService!
    
    @ObservationIgnored
    private var noteRepositpry: NoteRepositoryProtocol
    
    var state: FriendScreenState { FriendScreenState(friend: friend) }
    
    init(appStore: AppStore, friend: Friend, noteRepositpry: NoteRepositoryProtocol) {
        self.friend = friend
        self.noteRepositpry = noteRepositpry
        super.init(appStore: appStore)
        
        syncService = SyncService(profile: self.appStore.user)
        loadData()
    }
    
    func send(_ action: FriendScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .editFriend(name: let name, color: let color):
                let newFriend = Friend(id: friend.id, name: name, color: color, user: friend.user)
                friend = newFriend
                appStore.send(.editFriend(newFriend))
            case .deleteFriend:
                appStore.send(.deleteFriend(friend))
            case .syncFriend:
                syncFriend()
            }
        }
    }
    
    func syncFriend() {
        Task {
            do {
                let sentNotes = appStore.stories[BaseDate(date: Date())]?.notes ?? []
                let syncResult = try await syncService.syncFriend(friend: friend, notes: sentNotes)
                
                let newNotes = syncResult.notes
                print(newNotes)
                let updateFriend = friend.copy(user: syncResult.user)
                friend = updateFriend
                appStore.send(.editFriend(updateFriend))
                appStore.send(.syncNotes(newNotes, updateFriend))
                
                print("Received:", syncResult)
            } catch {
                print("Sync failed:", error)
            }
        }
    }
    
    private func loadData() {
//        noteRepositpry.
    }
}
