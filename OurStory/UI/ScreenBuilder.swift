//
//  ScreenBuilder.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

enum ScreenType: Identifiable, Hashable {
    
    case home, note(Note?), friendList, friend(Friend), newFriend, setting, editProfile, notes(title: String?, notes: [Note], isShowFriendsList: Binding<Bool>)
    
    var id: String {
        switch self {
        case .home: "home"
        case .note: "note"
        case .friendList: "friendList"
        case .friend: "friend"
        case .newFriend: "newFriend"
        case .setting: "setting"
        case .editProfile: "editProfile"
        case .notes: "notes___1"
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
        case (.newFriend, .newFriend):
            true
        case (.setting, .setting):
            true
        case (.editProfile, .editProfile):
            true
        case (.notes, .notes):
            true
        default:
            false
        }
    }
}

enum ComponentType: Hashable {
    case horizontalCalendar
    case notesList(notes: [Note], storyID: UUID, isShowFriendsList: Binding<Bool>)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .horizontalCalendar: hasher.combine("horizontalCalendar")
        case .notesList: hasher.combine("notesList")
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.horizontalCalendar, .horizontalCalendar): true
        case (.notesList, .notesList): true
        default: false
        }
    }
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
        case .newFriend: NewFriendScreen(store: NewFriendScreenStore(appStore: appStore))
        case .setting: SettingScreen(store: SettingScreenStore(appStore: appStore))
        case .editProfile: EditProfileScreen(store: SettingScreenStore(appStore: appStore))
        case .notes(title: let title, notes: let notes, isShowFriendsList: let isShowFriendsList):
            NoteListScreen(title: title,
                           store: NoteListScreenStore(appStore: appStore, notes: notes),
                           isShowFriendsList: isShowFriendsList)
        }
    }
    
    @ViewBuilder
    func getComponent(type: ComponentType) -> some View {
        switch type {
        case .horizontalCalendar: HorizontalCalendar(store: HorizontalCalendarStore(appStore: appStore))
        case .notesList(notes: let notes, storyID: let storyID, isShowFriendsList: let isShowFriendsList):
            NoteListContent(store: NoteListScreenStore(appStore: appStore, notes: notes, storyID: storyID),
                            isShowFriendsList: isShowFriendsList,
                            isShowDate: false)
        }
    }
}



