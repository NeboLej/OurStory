//
//  SyncProgressStore.swift
//  OurStory
//

import SwiftUI

@Observable
final class SyncProgressStore: BaseStore {
    
    // MARK: - Inputs
    
    private let friend: Friend
    private let unsentNotes: [Note]
    private let noteRepository: NoteRepositoryProtocol
    private let syncService: SyncService3
    private let isDiscoveryActive: Bool
    private let isNewFriend: Bool
    
    var onSyncFinished: ((SyncCompletedResult) -> Void)?
    
    // MARK: - Observable State
    
    private var syncPhase: SyncPhase = .idle
    private var newNoteCount: Int = 0
    
    // MARK: - Internal
    
    @ObservationIgnored
    private var syncAnimationTask: Task<Void, Never>?
    
    @ObservationIgnored
    private var approachingDelayTask: Task<Void, Never>?
    
    var state: SyncProgressScreenState {
        SyncProgressScreenState(
            syncPhase: syncPhase,
            friendName: friend.name,
            friendColor: friend.color,
            userColor: appStore.user.color,
            newNotesCount: newNoteCount
        )
    }
    
    // MARK: - Init
    
    init(appStore: AppStore, config: SyncProgressConfig) {
        self.friend = config.friend
        self.unsentNotes = config.unsentNotes
        self.noteRepository = config.noteRepository
        self.syncService = config.syncService
        self.isDiscoveryActive = config.isDiscoveryActive
        self.isNewFriend = config.isNewFriend
        self.onSyncFinished = config.onSyncFinished
        super.init(appStore: appStore)
    }
    
    // MARK: - Actions
    
    func send(_ action: SyncProgressAction) {
        switch action {
        case .confirmSync(let isConfirm):
            syncService.confirmUser(isConfirm)
            
        case .exitSync:
            syncAnimationTask?.cancel()
            syncAnimationTask = nil
            approachingDelayTask?.cancel()
            approachingDelayTask = nil
            syncService.cancelSync()
            syncPhase = .idle
            appStore.appCoordinator.fullScreenCover = nil
            
        case .toNewNotes:
            appStore.appCoordinator.fullScreenCover = nil
            let friendName = friend.name
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard let self else { return }
                self.appStore.send(.toNotesList(
                    title: "Истории от \(friendName)",
                    notes: self.appStore.sortedNotes
                ))
            }
        }
    }
    
    // MARK: - Start Sync
    
    func startSync() {
        guard syncPhase == .idle else { return }
        newNoteCount = 0
        syncPhase = .searching
        
        syncService.onStateChanged = { [weak self] event in
            guard let self else { return }
            Logger.log("SyncProgress: received event: \(event.descriptionText)")
            self.mapSyncEventToAnimationPhase(event)
        }
        
        syncService.onSyncCompleted = { [weak self] result in
            guard let self else { return }
            Logger.log("SyncProgress: sync completed, received \(result.notes.count) notes from \(result.user.name)")
            self.handleSyncCompleted(result)
        }
        
        if isDiscoveryActive {
            syncService.beginExchange(notes: unsentNotes)
        } else {
            syncService.startFirstSync(friend: friend, notes: unsentNotes)
        }
    }
    
    // MARK: - Private
    
    private func handleSyncCompleted(_ result: SyncResult) {
        let sentNoteIDs = unsentNotes.map { $0.id }
        
        Task {
            await noteRepository.updateSentStatus(noteIDs: sentNoteIDs, friendID: friend.id, isSent: true)
        }
        
        let updatedFriend: Friend
        if isNewFriend {
            updatedFriend = Friend(
                name: result.user.name,
                color: result.user.color,
                user: result.user,
                lastSyncDate: Date()
            )
            appStore.send(.addNewFriend(updatedFriend))
        } else {
            updatedFriend = friend.copy(user: result.user, lastSyncDate: Date())
            appStore.send(.editFriend(updatedFriend))
        }
        appStore.send(.syncNotes(result.notes, updatedFriend))
        newNoteCount = result.notes.count
        
        onSyncFinished?(SyncCompletedResult(
            updatedFriend: updatedFriend,
            newNoteCount: result.notes.count
        ))
    }
    
    private func mapSyncEventToAnimationPhase(_ event: SyncProgressState) {
        switch event {
        case .searching:
            withAnimation(.easeInOut(duration: 0.8)) {
                syncPhase = .searching
            }
        case .connecting, .exchangingUsers:
            approachingDelayTask?.cancel()
            approachingDelayTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 600_000_000)
                guard let self, !Task.isCancelled else { return }
                guard self.syncPhase == .searching else { return }
                withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                    self.syncPhase = .approaching
                }
            }
        case .friendNearby:
            break
        case .waitingForUserConfirmation(let user):
            approachingDelayTask?.cancel()
            approachingDelayTask = nil
            withAnimation(.easeInOut(duration: 0.6)) {
                syncPhase = .waitingForConfirmation(user)
            }
        case .exchangingNotes:
            withAnimation(.easeInOut(duration: 0.8)) {
                syncPhase = .approaching
            }
            syncAnimationTask?.cancel()
            syncAnimationTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 4_500_000_000)
                guard let self, !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.5)) {
                    self.syncPhase = .merging
                }
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 1.0)) {
                    self.syncPhase = .completed(newCount: self.newNoteCount)
                }
            }
        case .completed:
            break
        case .failed(let error):
            syncAnimationTask?.cancel()
            syncAnimationTask = nil
            withAnimation(.easeInOut(duration: 0.6)) {
                syncPhase = .failed(error.localizedDescription)
            }
        }
    }
}
