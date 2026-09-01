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
        withAnimation {
            switch action {
            case .openScreen: print("OpenScreen")
            case .createNewNote: appStore.send(.toCreateNote)
            }
        }
    }
}
