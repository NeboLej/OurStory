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
    var syncPgogressStates: [SyncProgressState] = []
    var sendNotes: [Note] = []
    var newNoteCount: Int = 0
    
    @ObservationIgnored
    private var noteRepositpry: NoteRepositoryProtocol
    
    var state: FriendScreenState { FriendScreenState(friend: friend,
                                                     notSeenStoriesCount: sendNotes.count,
                                                     syncPgogressStates: syncPgogressStates,
                                                     newNotesCount: newNoteCount) }
    
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
//                testSyncFriends()
                syncFriend()
            case .confirmSyncFriend(let isConfirm):
                syncService.confirmUser(isConfirm)
            case .toNewNotes:
                appStore.send(.toNotesList(title: "Истории от \(friend.name)", notes: appStore.sortedNotes))
            case .exitSync:
                syncPgogressStates = []
            }
        }
    }
    
    func testSyncFriends() {
        newNoteCount = 0
        let eventList: [SyncProgressState] = [.searching, .connecting, .exchangingUsers, .exchangingNotes, .completed]
        
        (1...5).forEach { ddd in
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(ddd)) {
                if eventList[ddd - 1] == .completed {
                    self.newNoteCount = self.sendNotes.count
                }
                self.syncPgogressStates.append((eventList[ddd - 1]))
            }
        }
    }
    
    func syncFriend() {
        newNoteCount = 0
        Task {
            do {
                var eventDebounse: Double = 0
                
                syncService.onEvent = { event in
                    DispatchQueue.main.asyncAfter(deadline: .now() + eventDebounse) {
                        self.syncPgogressStates.append(event)
                    }
                    eventDebounse += 0.8
                }
                
                let syncResult = try await syncService.syncFriend(friend: friend, notes: sendNotes)
                
                let newNotes = syncResult.notes
                let updateFriend = friend.copy(user: syncResult.user)
                friend = updateFriend
                appStore.send(.editFriend(updateFriend))
                appStore.send(.syncNotes(newNotes, updateFriend))
                newNoteCount = newNotes.count
            } catch {
                print("Sync failed:", error)
            }
        }
    }
    
    private func loadData() {
        Task {
            sendNotes = await noteRepositpry.getNotes(friendID: friend.id)
        }
    }
}
