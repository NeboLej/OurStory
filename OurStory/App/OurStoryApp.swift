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
        screenBuilder.getScreen(type: .home)
    }
}
