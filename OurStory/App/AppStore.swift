//
//  AppStore.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

@MainActor
protocol AppStoreProtocol: AnyObject {
    var selectedDate: Date { get }
    var currentNotes: [Note] { get }
    var allNotes: [Note] { get }
    var allFriends: [Friend] { get }
    var user: User { get }
    var notesByDate: [BaseDate: [Note]] { get }
    var cloudSyncState: CloudSyncState { get }
    
    var appCoordinator: AppCoordinator { get }
    
    func send(_ action: AppAction)
    func send(_ action: NavigateAction)
    func notes(for filter: NoteFilter) -> [Note]
    func searchNotes(query: String) -> [Note]
    func syncDownload()
}

@MainActor
@Observable
final class AppStoreMock: AppStoreProtocol {
    var selectedDate: Date = .now
    var currentNotes: [Note] = Note.tmpNotes
    
    var allNotes: [Note] = [] {
        didSet {
            notesByDate = Dictionary(grouping: allNotes, by: \.baseDate)
                .mapValues { $0.sorted { $0.date > $1.date } }
        }
    }
    
    var allFriends: [Friend] = Friend.mock
    var user: User = User.init(name: "Nebo", color: "fc33dd")
    
    var notesByDate: [BaseDate : [Note]] = [:]
    
    var cloudSyncState: CloudSyncState = .completed
    
    var appCoordinator: AppCoordinator = AppCoordinator()
    
    func send(_ action: AppAction) {
        
    }
    
    func send(_ action: NavigateAction) {
        
    }
    
    func notes(for filter: NoteFilter) -> [Note] {
        Note.tmpNotes
    }
    
    func searchNotes(query: String) -> [Note] {
        Note.tmpNotes
    }
    
    func syncDownload() {
        
    }
}


@MainActor
@Observable
final class AppStore: AppStoreProtocol {
    
    var selectedDate: Date = .now
    
    var currentNotes: [Note] {
        notesByDate[BaseDate(date: selectedDate)] ?? []
    }
    
    private(set) var notesByDate: [BaseDate: [Note]] = [:]
    
    var allFriends: [Friend] = []
    var user: User
    var sortedNotes: [Note] = []
    var isShowNoteFriendsList: Bool = false
    
    var allNotes: [Note] = [] {
        didSet {
            notesByDate = Dictionary(grouping: allNotes, by: \.baseDate)
                .mapValues { $0.sorted { $0.date > $1.date } }
        }
    }
    
    var appCoordinator: AppCoordinator = AppCoordinator()
    var cloudSyncState: CloudSyncState = .idle
    
    @ObservationIgnored
    let cloudKitService = CloudKitService.shared
    @ObservationIgnored
    let userRepository: UserRepositoryProtocol
    @ObservationIgnored
    let friendsRepository: FriendRepositoryProtocol
    @ObservationIgnored
    let noteRepository: NoteRepositoryProtocol
    @ObservationIgnored
    let userDefaultsManager: UserDefaultsManager = UserDefaultsManager()
    
    @ObservationIgnored
    var isSyncing = false
    @ObservationIgnored
    var lastSyncDate: Date?
    /// Minimum interval between cloud syncs (seconds)
    @ObservationIgnored
    let syncCooldown: TimeInterval = 120
    
    init(repositoryFactory: RepositoryFactoryProtocol) {
        self.userRepository = repositoryFactory.userRepository
        self.friendsRepository = repositoryFactory.friendRepository
        self.noteRepository = repositoryFactory.noteRepository
        
        user = userDefaultsManager.getCurrentUser()
        
        cloudKitService.onStateChange = { [weak self] state in
            self?.cloudSyncState = state
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadData()
        }
    }
    
    func send(_ action: AppAction) {
        switch action {
        case .selectedDate(let date):
            selectedDate = date
        case .addNewNote(let newNote):
            addNewNote(newNote)
        case .editNote(let note):
            if let index = allNotes.firstIndex(where: { $0.id == note.id }) {
                allNotes[index] = note
            }
            updateNote(note)
        case .deleteNote(let note):
            deleteNote(note)
        case .syncNotes(let notes, let friend):
            syncNotes(notes, friend: friend)
        case .addNewFriend(let friend):
            addNewFriend(friend)
        case .editFriend(let friend):
            editFriend(friend)
        case .deleteFriend(let friend):
            deleteFriend(friend)
        case .deleteFriendWithNotes(let friend):
            deleteFriendWithNotes(friend)
        case .hideFriend(let friend):
            hideFriend(friend)
        case .editProfile(name: let name, color: let color):
            user = userDefaultsManager.editUser(name: name, color: color)
            createWelcomeMessageIfNeeded()
        }
    }
    
    func notes(for filter: NoteFilter) -> [Note] {
        switch filter {
        case .byDate(let baseDate):
            return notesByDate[baseDate] ?? []
        case .byFriend(let friendID):
            return allNotes
                .filter { $0.friends.contains(where: { $0.id == friendID }) || $0.owner?.id == friendID }
                .sorted { $0.date > $1.date }
        case .bySearch(let query):
            guard query.count >= 3 else { return [] }
            return searchNotes(query: query)
        case .every(noteID: let noteIDs):
            return allNotes
                .filter { noteIDs.contains($0.id) }
                .sorted { $0.date > $1.date }
        }
    }
    
    func send(_ action: NavigateAction) {
        switch action {
        case .toNote(let note):
            appCoordinator.navigate(to: .note(note))
        case .toFriendsList:
            appCoordinator.navigate(to: .friendList)
            if !userDefaultsManager.isShowSupportEvent(.addFriend) {
                appCoordinator.navigate(to: .help(HelpType.addedFriend))
                userDefaultsManager.setShowSupportEvent(.addFriend)
            }
        case .toFriend(let friend):
            appCoordinator.navigate(to: .friend(friend))
            if !userDefaultsManager.isShowSupportEvent(.exchangeStory) {
                appCoordinator.navigate(to: .help(HelpType.exhangeStory))
                userDefaultsManager.setShowSupportEvent(.exchangeStory)
            }
        case .toNewFriend:
            appCoordinator.navigate(to: .newFriend)
        case .toSettings:
            appCoordinator.navigate(to: .setting)
        case .toEditProfile:
            appCoordinator.navigate(to: .editProfile)
        case .toNotesList(title: let title, filter: let filter):
            appCoordinator.navigate(to: .notes(title: title, filter: filter, isShowFriendsList: Binding(get: { self.isShowNoteFriendsList }, set: { self.isShowNoteFriendsList = $0 })))
        case .toLogs:
            appCoordinator.navigate(to: .log)
        case .toCalendar:
            appCoordinator.navigate(to: .calendar)
        case .toSearch:
            appCoordinator.navigate(to: .search)
        case .toHelpListScreen:
            appCoordinator.navigate(to: .helpList)
        }
    }
    
    func loadData() {
        Task {
            allFriends = await friendsRepository.getAllFriends()
            allNotes = await noteRepository.getAllNotes()
        }
    }
}
