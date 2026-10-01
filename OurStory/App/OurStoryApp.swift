//
//  OurStoryApp.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI
import UIKit

@main
struct OurStoryApp: App {
    
    var screenBuilder: ScreenBuilder
    var appStore: AppStore
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        let repositoryFactory: RepositoryFactoryProtocol = RepositoryFactory()
        let appStore = AppStore(repositoryFactory: repositoryFactory)
        screenBuilder = ScreenBuilder(appStore: appStore, repositoryFactory: repositoryFactory)
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
        .task {
            // Initial sync on first launch (onChange doesn't fire for the initial scenePhase value)
            appStore.syncDownloadAndUpload()
        }
        .onChange(of: scenePhase, { oldValue, newValue in
            switch newValue {
            case .active:
                appStore.syncDownloadAndUpload()
            case .background:
                let backgroundTask = UIApplication.shared.beginBackgroundTask()
                Task {
                    await appStore.cloudKitService.uploadAll()
                    await MainActor.run {
                        UIApplication.shared.endBackgroundTask(backgroundTask)
                    }
                }
            default:
                break
            }
        })
    }
}
