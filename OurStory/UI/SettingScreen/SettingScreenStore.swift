//
//  SettingScreenStore.swift
//  OurStory
//
//  Created by Nebo on 22.09.2026.
//

import SwiftUI

@Observable
final class SettingScreenStore: BaseStore {
    
    var state: SettingScreenState {
        SettingScreenState(user: appStore.user)
    }
    
    func send(_ action: SettingScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .saveUser(name: let name, color: let color):
                appStore.send(.editProfile(name: name, color: color))
            }
        }
    }
}
