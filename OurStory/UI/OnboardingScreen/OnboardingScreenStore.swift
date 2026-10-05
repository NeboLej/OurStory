//
//  OnboardingScreenStore.swift
//  OurStory
//

import Foundation

@Observable
final class OnboardingScreenStore: BaseStore {
    
    var state = OnboardingScreenState()
    
    func send(_ action: OnboardingScreenAction) {
        switch action {
        case .saveProfile(name: let name, color: let color):
            appStore.send(.editProfile(name: name, color: color))
            appStore.appCoordinator.fullScreenCover = nil
        }
    }
}
