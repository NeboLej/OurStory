//
//  NewFriendScreenStore.swift
//  OurStory
//
//  Created by Nebo on 21.09.2026.
//

import SwiftUI

@Observable
final class NewFriendScreenStore: BaseStore {
    
    private let noteRepository: NoteRepositoryProtocol
    
    init(appStore: AppStore, noteRepository: NoteRepositoryProtocol) {
        self.noteRepository = noteRepository
        super.init(appStore: appStore)
    }
    
    var state: NewFriendScreenState {
        NewFriendScreenState()
    }
    
    func send(_ action: NewFriendScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .saveNewFriend(name: let name, color: let color):
                let newFriend = Friend(name: name, color: color)
                appStore.send(.addNewFriend(newFriend))
            case .startSyncNewFriend:
                startSyncNewFriend()
            }
        }
    }
    
    private func navigateToFriend(_ friend: Friend) {
        guard !appStore.appCoordinator.path.isEmpty else { return }
        appStore.appCoordinator.path.removeLast()
        appStore.appCoordinator.navigate(to: .friend(friend))
    }
    
    private func startSyncNewFriend() {
        let tempFriend = Friend(name: "—", color: "#AAAAAA")
        let syncService = SyncService3(profile: appStore.user)
        
        let config = SyncProgressConfig(
            friend: tempFriend,
            unsentNotes: [],
            syncService: syncService,
            isDiscoveryActive: false,
            isNewFriend: true,
            noteRepository: noteRepository,
            onSyncFinished: { [weak self] result in
                self?.navigateToFriend(result.updatedFriend)
            }
        )
        
        appStore.appCoordinator.present(to: .syncProgress(config))
    }
}
