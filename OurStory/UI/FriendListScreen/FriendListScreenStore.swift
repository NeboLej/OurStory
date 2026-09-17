//
//  FriendListScreenStore.swift
//  OurStory
//
//  Created by Nebo on 17.09.2026.
//

import SwiftUI

@Observable
final class FriendListScreenStore: BaseStore {
    
    var state: FriendListScreenState  {
        FriendListScreenState(allFriends: appStore.allFriends)
    }
    
    func send(_ action: FriendListScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .addNewRandomFriend:
                appStore.send(.addRandomFriend)
            }
        }
    }
}
