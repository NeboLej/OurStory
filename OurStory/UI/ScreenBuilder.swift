//
//  ScreenBuilder.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

enum ScreenType: Identifiable, Hashable {
    
    case home
    
    var id: String {
        switch self {
        case .home: "home"
        }
    }
}

enum ComponentType: Hashable {
    case horizontalCalendar
}


final class ScreenBuilder {
    
    static let previewBuilder: ScreenBuilder = {
        let appStoreMock = AppStore()
        return ScreenBuilder(appStore: appStoreMock)
    }()
    
    private let appStore: AppStore
    
    init(appStore: AppStore) {
        self.appStore = appStore
    }
    
    @ViewBuilder
    func getScreen(type: ScreenType) -> some View {
        switch type {
        case .home: HomeScreen(store: HomeScreenStore(appStore: appStore), screenBuilder: self)
        }
    }
    
    @ViewBuilder
    func getComponent(type: ComponentType) -> some View {
        switch type {
        case .horizontalCalendar: HorizontalCalendar(store: HorizontalCalendarStore(appStore: appStore))
        }
    }
}



