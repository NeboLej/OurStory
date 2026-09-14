//
//  ScreenBuilder.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

enum ScreenType: Identifiable, Hashable {
    
    case home, note(Note?)
    
    var id: String {
        switch self {
        case .home: "home"
        case .note: "note"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ComponentType: Hashable {
    case horizontalCalendar
}


final class ScreenBuilder {
    
    static let previewBuilder: ScreenBuilder = {
        let appStoreMock = AppStore(repositoryFactory: RepositoryFactory())
        return ScreenBuilder(appStore: appStoreMock, repositoryFactory: RepositoryFactory())
    }()
    
    private let appStore: AppStore
    private let repositories: RepositoryFactoryProtocol
    
    init(appStore: AppStore, repositoryFactory: RepositoryFactoryProtocol) {
        self.appStore = appStore
        self.repositories = repositoryFactory
    }
    
    @ViewBuilder
    func getScreen(type: ScreenType) -> some View {
        switch type {
        case .home: HomeScreen(store: HomeScreenStore(appStore: appStore), screenBuilder: self)
        case .note(let note): NoteScreen(store: NoteScreenStore(appStore: appStore, note: note))
        }
    }
    
    @ViewBuilder
    func getComponent(type: ComponentType) -> some View {
        switch type {
        case .horizontalCalendar: HorizontalCalendar(store: HorizontalCalendarStore(appStore: appStore))
        }
    }
}



