//
//  ScreenBuilder.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

enum ScreenType: Identifiable, Hashable {
    
    case home, note(Note?), friendList, friend(Friend)
    
    var id: String {
        switch self {
        case .home: "home"
        case .note: "note"
        case .friendList: "friendList"
        case .friend: "friend"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home):
            true
        case (.note, .note):
            true
        case (.friendList, .friendList):
            true
        case (.friend, .friend):
            true
        default:
            false
        }
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
        case .friendList: FriendListScreen(store: FriendListScreenStore(appStore: appStore))
        case .friend(let friend): FriendScreen(store: FriendScreenStore(appStore: appStore, friend: friend, noteRepositpry: repositories.noteRepository))
        }
    }
    
    @ViewBuilder
    func getComponent(type: ComponentType) -> some View {
        switch type {
        case .horizontalCalendar: HorizontalCalendar(store: HorizontalCalendarStore(appStore: appStore))
        }
    }
}



