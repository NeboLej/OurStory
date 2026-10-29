//
//  FriendScreenStore.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import SwiftUI

@Observable
final class FriendScreenStore: BaseStore {
    
    private var friend: Friend
    
    private var syncService: SyncService3
    private var totalNotes: [Note] = []
    private var unsentNotes: [Note] = []
    
    private var searchStatus: FriendSearchStatus = .idle
    private var showUserSuggestion: Bool = false
    
    @ObservationIgnored
    private var noteRepositpry: NoteRepositoryProtocol
    
    /// true когда discovery-фаза активна (ищем друга или нашли и ждём кнопку)
    @ObservationIgnored
    private var discoveryActive = false
    
    /// Таймер таймаута поиска
    @ObservationIgnored
    private var searchTimeoutTask: Task<Void, Never>?
    
    /// Таймер задержки перед повторной попыткой discovery
    @ObservationIgnored
    private var discoveryRetryTask: Task<Void, Never>?
    
    /// Таймер периодической проверки (30 секунд после успешного обнаружения)
    @ObservationIgnored
    private var recheckTask: Task<Void, Never>?
    
    private var hasUserProfileDifference: Bool {
        guard let user = friend.user else { return false }
        return user.name != friend.name || user.color != friend.color
    }
    
    var state: FriendScreenState {
        FriendScreenState(
            friend: friend,
            allStoriesCount: totalNotes.count,
            notSeenStoriesCount: unsentNotes.count,
            lastSyncDate: friend.lastSyncDate,
            searchStatus: searchStatus,
            showUserSuggestion: showUserSuggestion,
            hasUserProfileDifference: hasUserProfileDifference
        )
    }
    
    init(appStore: AppStore, friend: Friend, noteRepositpry: NoteRepositoryProtocol) {
        self.friend = friend
        self.noteRepositpry = noteRepositpry
        self.syncService = SyncService3(profile: appStore.user)
        super.init(appStore: appStore)
        
        loadData()
    }
    
    func send(_ action: FriendScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .editFriend(name: let name, color: let color):
                let newFriend = Friend(id: friend.id, name: name, color: color, user: friend.user, lastSyncDate: friend.lastSyncDate)
                friend = newFriend
                appStore.send(.editFriend(newFriend))
            case .deleteFriendWithStories:
                stopSearching()
                appStore.send(.deleteFriendWithStories(friend))
            case .hideFriend:
                stopSearching()
                appStore.send(.hideFriend(friend))
            case .syncFriend:
                presentSyncProgress()
            case .applyUserProfile:
                guard let user = friend.user else { return }
                let newFriend = Friend(id: friend.id, name: user.name, color: user.color, user: friend.user, lastSyncDate: friend.lastSyncDate)
                friend = newFriend
                showUserSuggestion = false
                appStore.send(.editFriend(newFriend))
            case .startSearching:
                startSearching()
            case .stopSearching:
                stopSearching()
            case .retrySearching:
                retrySearching()
            case .toAllNotes:
                if totalNotes.count > 0 {
                    appStore.send(.toNotesList(title: "Наши с \(friend.name) истории", notes: totalNotes))
                }
            case .toUnsentNotes:
                if unsentNotes.count > 0 {
                    appStore.send(.toNotesList(title: "Мои нерасказанные истории", notes: unsentNotes))
                }
            case .dismissUserSuggestion:
                showUserSuggestion = false
            case .unlinkFriend:
                stopSearching()
                let unlinked = Friend(id: friend.id, name: friend.name, color: friend.color, user: nil, lastSyncDate: friend.lastSyncDate)
                friend = unlinked
                searchStatus = .idle
                appStore.send(.editFriend(unlinked))
            }
        }
    }
    
    // MARK: - Sync Presentation
    
    private func presentSyncProgress() {
        let config = SyncProgressConfig(
            friend: friend,
            unsentNotes: unsentNotes,
            syncService: syncService,
            isDiscoveryActive: discoveryActive,
            noteRepository: noteRepositpry,
            onSyncFinished: { [weak self] result in
                self?.handleSyncFinished(result)
            }
        )
        
        recheckTask?.cancel()
        recheckTask = nil
        if discoveryActive {
            discoveryActive = false
        }
        
        appStore.appCoordinator.present(to: .syncProgress(config))
    }
    
    private func handleSyncFinished(_ result: SyncCompletedResult) {
        friend = result.updatedFriend
        showUserSuggestion = hasUserProfileDifference
        searchStatus = .idle
        loadData()
        
        // Restart discovery after a delay
        discoveryRetryTask?.cancel()
        discoveryRetryTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let self, !Task.isCancelled else { return }
            self.startSearching()
        }
    }
    
    // MARK: - Поиск друга поблизости (через SyncService3)
    
    private func startSearching() {
        guard searchStatus == .idle || searchStatus == .notFound else { return }
        guard friend.user?.id != nil else { return }
        
        searchStatus = .searching
        discoveryActive = true
        
        setupSyncCallbacks()
        syncService.startDiscovery(friend: friend, notes: unsentNotes)
        startSearchTimeout()
    }
    
    private func retrySearching() {
        syncService.cancelSync()
        searchTimeoutTask?.cancel()
        searchTimeoutTask = nil
        discoveryRetryTask?.cancel()
        discoveryRetryTask = nil
        recheckTask?.cancel()
        recheckTask = nil
        discoveryActive = false
        searchStatus = .idle
        startSearching()
    }
    
    private func setupSyncCallbacks() {
        syncService.onStateChanged = { [weak self] event in
            guard let self else { return }
            self.handleDiscoveryEvent(event)
        }
        
        syncService.onSyncCompleted = { [weak self] _ in
            guard self != nil else { return }
            Logger.log("FriendScreenStore: unexpected onSyncCompleted during discovery")
        }
        
        syncService.onFriendReady = { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                self.searchStatus = .friendReady
            }
        }
    }
    
    private func startSearchTimeout() {
        searchTimeoutTask?.cancel()
        searchTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 секунд
            guard let self, !Task.isCancelled else { return }
            guard self.discoveryActive, self.searchStatus == .searching else { return }
            
            self.syncService.cancelSync()
            self.discoveryActive = false
            withAnimation(.easeInOut(duration: 0.4)) {
                self.searchStatus = .notFound
            }
        }
    }
    
    private func handleDiscoveryEvent(_ event: SyncProgressState) {
        guard discoveryActive else { return }
        
        switch event {
        case .friendNearby:
            searchTimeoutTask?.cancel()
            searchTimeoutTask = nil
            withAnimation(.easeInOut(duration: 0.5)) {
                self.searchStatus = .found
            }
            scheduleRecheck()
            
        case .searching:
            // SyncSession is reconnecting after a disconnect
            if searchStatus == .found {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.searchStatus = .searching
                }
                startSearchTimeout()
            }
            
        case .failed:
            guard friend.user?.id != nil else { return }
            searchTimeoutTask?.cancel()
            withAnimation(.easeInOut(duration: 0.4)) {
                self.searchStatus = .notFound
            }
            discoveryActive = false
            
        default:
            break
        }
    }
    
    /// SyncSession2 handles reconnection internally, so recheck just verifies the status
    private func scheduleRecheck() {
        recheckTask?.cancel()
        recheckTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let self, !Task.isCancelled, self.discoveryActive else { return }
            guard self.syncService.isFriendNearby else {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.searchStatus = .searching
                }
                return
            }
        }
    }
    
    func stopSearching() {
        syncService.cancelSync()
        searchTimeoutTask?.cancel()
        searchTimeoutTask = nil
        discoveryRetryTask?.cancel()
        discoveryRetryTask = nil
        recheckTask?.cancel()
        recheckTask = nil
        discoveryActive = false
    }
    
    private func loadData() {
        Task {
            totalNotes = await noteRepositpry.getTotalNotes(friendID: friend.id)
            unsentNotes = await noteRepositpry.getUnsentNotes(friendID: friend.id)
        }
    }
}
