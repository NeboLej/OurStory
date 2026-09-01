//
//  OurStoryApp.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

@main
struct OurStoryApp: App {
    
    var screenBuilder: ScreenBuilder
    var appStore: AppStore
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        let appStore = AppStore()
        screenBuilder = ScreenBuilder(appStore: appStore)
        self.appStore = appStore
    }
    
    
    var body: some Scene {
        WindowGroup {
            content()
        }
    }
    
    
    @ViewBuilder
    private func content() -> some View {
        let coordinator = Bindable(appStore.appCoordinator)
        ZStack {
            NavigationStack(path: coordinator.path) {
                screenBuilder.getScreen(type: .home)
                    .navigationDestination(for: ScreenType.self) {
                        screenBuilder.getScreen(type: $0)
                    }
            }
        }
        .sheet(item: coordinator.activeSheet) { screenType in
            screenBuilder.getScreen(type: screenType)
        }
        .fullScreenCover(item: coordinator.fullScreenCover) { screenType in
            screenBuilder.getScreen(type: screenType)
        }
        .onChange(of: scenePhase, { oldValue, newValue in
            guard newValue == .active else { return }
            Task {
                //TODO: Update data with open app
            }
        })
    }
}
