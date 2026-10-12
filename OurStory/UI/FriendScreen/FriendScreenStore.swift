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
    
    var syncService: SyncService3!
    var syncPgogressStates: [SyncProgressState] = []
    var newNoteCount: Int = 0
    var totalNotes: [Note] = []
    var unsentNotes: [Note] = []
    
    // Новое: состояние поиска и анимации
    var searchStatus: FriendSearchStatus = .idle
    var syncPhase: SyncPhase = .idle
    
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
    
    /// Цепочка анимаций (approaching → merging → completed)
    @ObservationIgnored
    private var syncAnimationTask: Task<Void, Never>?
    
    var state: FriendScreenState { FriendScreenState(friend: friend,
                                                     allStoriesCount: totalNotes.count,
                                                     notSeenStoriesCount: unsentNotes.count,
                                                     lastSyncDate: friend.lastSyncDate,
                                                     syncPgogressStates: syncPgogressStates,
                                                     newNotesCount: newNoteCount,
                                                     searchStatus: searchStatus,
                                                     syncPhase: syncPhase) }
    
    init(appStore: AppStore, friend: Friend, noteRepositpry: NoteRepositoryProtocol) {
        self.friend = friend
        self.noteRepositpry = noteRepositpry
        super.init(appStore: appStore)
        
        syncService = SyncService3(profile: self.appStore.user)
        loadData()
    }
    
    var hasUserProfileDifference: Bool {
        guard let user = friend.user else { return false }
        return user.name != friend.name || user.color != friend.color
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
                syncFriend()
            case .confirmSyncFriend(let isConfirm):
                syncService?.confirmUser(isConfirm)
            case .toNewNotes:
                appStore.send(.toNotesList(title: "Истории от \(friend.name)", notes: appStore.sortedNotes))
            case .exitSync:
                syncAnimationTask?.cancel()
                syncAnimationTask = nil
                approachingDelayTask?.cancel()
                approachingDelayTask = nil
                syncService?.cancelSync()
                syncPgogressStates = []
                syncPhase = .idle
                searchStatus = .idle
                loadData()
                // Delay before restarting discovery to let Bonjour fully deregister
                discoveryRetryTask?.cancel()
                discoveryRetryTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    guard let self, !Task.isCancelled else { return }
                    self.startSearching()
                }
            case .applyUserProfile:
                guard let user = friend.user else { return }
                let newFriend = Friend(id: friend.id, name: user.name, color: user.color, user: friend.user, lastSyncDate: friend.lastSyncDate)
                friend = newFriend
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
            case .unlinkFriend:
                stopSearching()
                let unlinked = Friend(id: friend.id, name: friend.name, color: friend.color, user: nil, lastSyncDate: friend.lastSyncDate)
                friend = unlinked
                searchStatus = .idle
                appStore.send(.editFriend(unlinked))
            }
        }
    }
    
    // MARK: - Поиск друга поблизости (через PeerExchangeManager)
    
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
        syncService?.cancelSync()
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
        
        syncService.onSyncCompleted = { [weak self] result in
            guard let self else { return }
            self.handleSyncCompleted(result)
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
        if discoveryActive {
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
        } else {
            syncPgogressStates.append(event)
            mapSyncEventToAnimationPhase(event)
        }
    }
    
    private func handleSyncCompleted(_ result: SyncResult) {
        let sentNoteIDs = unsentNotes.map { $0.id }
        
        Task {
            await noteRepositpry.updateSentStatus(noteIDs: sentNoteIDs, friendID: friend.id, isSent: true)
        }
        
        let newNotes = result.notes
        let updateFriend = friend.copy(user: result.user, lastSyncDate: Date())
        friend = updateFriend
        appStore.send(.editFriend(updateFriend))
        appStore.send(.syncNotes(newNotes, updateFriend))
        newNoteCount = newNotes.count
    }
    
    /// SyncSession2 handles reconnection internally, so recheck just verifies the status
    private func scheduleRecheck() {
        recheckTask?.cancel()
        recheckTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let self, !Task.isCancelled, self.discoveryActive else { return }
            // SyncService2 handles keep-alive internally;
            // if friend is no longer nearby, SyncSession will transition to .searching and
            // handleDiscoveryEvent will update searchStatus accordingly
            guard self.syncService.isFriendNearby else {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.searchStatus = .searching
                }
                return
            }
        }
    }
    
    func stopSearching() {
        syncService?.cancelSync()
        searchTimeoutTask?.cancel()
        searchTimeoutTask = nil
        discoveryRetryTask?.cancel()
        discoveryRetryTask = nil
        recheckTask?.cancel()
        recheckTask = nil
        discoveryActive = false
    }
    
    // MARK: - Синхронизация с анимацией
    
    func syncFriend() {
        newNoteCount = 0
        recheckTask?.cancel()
        recheckTask = nil
        
        Logger.log("SyncFriend: started, discoveryActive: \(discoveryActive), friend.user: \(friend.user?.name ?? "nil"), sendNotes: \(unsentNotes.count)")
        
        if discoveryActive {
            // Discovery нашла друга — начинаем обмен
            discoveryActive = false
            syncPhase = .searching
            
            syncService.onStateChanged = { [weak self] event in
                guard let self else { return }
                Logger.log("SyncFriend: received event: \(event.descriptionText)")
                self.syncPgogressStates.append(event)
                self.mapSyncEventToAnimationPhase(event)
            }
            
            syncService.onSyncCompleted = { [weak self] result in
                guard let self else { return }
                Logger.log("SyncFriend: sync completed, received \(result.notes.count) notes from \(result.user.name)")
                self.handleSyncCompleted(result)
            }
            
            syncService.beginExchange(notes: unsentNotes)
            
        } else {
            // Первая синхронизация (friend.user == nil) — запускаем полный sync
            Logger.log("SyncFriend: first sync path (no discovery), starting full sync")
            syncPhase = .searching
            
            syncService.onStateChanged = { [weak self] event in
                guard let self else { return }
                Logger.log("SyncFriend: received event: \(event.descriptionText)")
                self.syncPgogressStates.append(event)
                self.mapSyncEventToAnimationPhase(event)
            }
            
            syncService.onSyncCompleted = { [weak self] result in
                guard let self else { return }
                Logger.log("SyncFriend: sync completed, received \(result.notes.count) notes from \(result.user.name)")
                self.handleSyncCompleted(result)
            }
            
            syncService.startFirstSync(friend: friend, notes: unsentNotes)
        }
    }
    
    /// Задача отложенного перехода в .approaching (из .connecting / .exchangingUsers)
    @ObservationIgnored
    private var approachingDelayTask: Task<Void, Never>?
    
    private func mapSyncEventToAnimationPhase(_ event: SyncProgressState) {
        switch event {
        case .searching:
            withAnimation(.easeInOut(duration: 0.8)) {
                syncPhase = .searching
            }
        case .connecting, .exchangingUsers:
            // Запускаем с задержкой, но только если фаза ещё не продвинулась дальше
            approachingDelayTask?.cancel()
            approachingDelayTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 600_000_000) // 0.6с задержка
                guard let self, !Task.isCancelled else { return }
                // Не перезаписываем, если уже перешли к waitingForConfirmation или дальше
                guard self.syncPhase == .searching else { return }
                withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                    self.syncPhase = .approaching
                }
            }
        case .friendNearby:
            break
        case .waitingForUserConfirmation(let user):
            // Отменяем отложенный переход в .approaching
            approachingDelayTask?.cancel()
            approachingDelayTask = nil
            withAnimation(.easeInOut(duration: 0.6)) {
                syncPhase = .waitingForConfirmation(user)
            }
        case .exchangingNotes:
            // Сначала показываем сближение, потом слияние, потом завершение
            // Вся цепочка анимаций идёт последовательно, чтобы фазы не перекрывали друг друга
            withAnimation(.easeInOut(duration: 0.8)) {
                syncPhase = .approaching
            }
            syncAnimationTask?.cancel()
            syncAnimationTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 4_500_000_000) // 4.5с — точки сближаются
                guard let self, !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.5)) {
                    self.syncPhase = .merging
                }
                try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5с — слияние
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 1.0)) {
                    self.syncPhase = .completed(newCount: self.newNoteCount)
                }
            }
        case .completed:
            // Результат уже обработан через onSyncCompleted.
            // Визуальное .completed выставляется из цепочки .exchangingNotes выше.
            break
        case .failed(let error):
            // Отменяем цепочку анимаций чтобы она не перезаписала ошибку
            syncAnimationTask?.cancel()
            syncAnimationTask = nil
            withAnimation(.easeInOut(duration: 0.6)) {
                syncPhase = .failed(error.localizedDescription)
            }
        }
    }
    
    func testSyncFriends() {
//        newNoteCount = 0
//        syncPhase = .searching
//        let eventList: [SyncProgressState] = [.searching, .connecting, .exchangingUsers, .exchangingNotes, .completed]
//        
//        (1...5).forEach { ddd in
//            DispatchQueue.main.asyncAfter(deadline: .now() + Double(ddd)) {
//                if eventList[ddd - 1] == .completed {
//                    self.newNoteCount = self.sendNotes.count
//                }
//                self.syncPgogressStates.append((eventList[ddd - 1]))
//                self.mapSyncEventToAnimationPhase(eventList[ddd - 1])
//            }
//        }
    }
    
    private func loadData() {
        Task {
            totalNotes = await noteRepositpry.getTotalNotes(friendID: friend.id)
            unsentNotes = await noteRepositpry.getUnsentNotes(friendID: friend.id)
        }
    }
}
