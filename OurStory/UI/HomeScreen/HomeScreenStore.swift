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
            case .createNewNote: appStore.send(.toNote(nil))
            case .toFriendsList: appStore.send(.toFriendsList)
            case .toSettings: appStore.send(.toSettings)
            case .toCalendar: appStore.send(.toCalendar)
            }
        }
    }
}
