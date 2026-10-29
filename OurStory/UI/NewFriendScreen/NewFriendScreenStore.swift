//
//  NewFriendScreenStore.swift
//  OurStory
//
//  Created by Nebo on 21.09.2026.
//

import SwiftUI

@Observable
final class NewFriendScreenStore: BaseStore {
    
    var state: NewFriendScreenState {
        NewFriendScreenState(profileNumber: appStore.allFriends.count + 1)
    }
    
    func send(_ action: NewFriendScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .saveNewFriend(name: let name, color: let color):
                let newFriend = Friend(name: name, color: color)
                appStore.send(.addNewFriend(newFriend))
            }
        }
    }
}
