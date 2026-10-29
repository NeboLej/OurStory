//
//  SyncProgressState.swift
//  OurStory
//

import Foundation

// MARK: - SyncPhase

enum SyncPhase: Equatable {
    case idle
    case searching
    case approaching
    case merging
    case completed(newCount: Int)
    case failed(String)
    case waitingForConfirmation(User)
    
    static func == (lhs: SyncPhase, rhs: SyncPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
            (.searching, .searching),
            (.approaching, .approaching),
            (.merging, .merging):
            return true
        case (.completed(let a), .completed(let b)):
            return a == b
        case (.failed(let a), .failed(let b)):
            return a == b
        case (.waitingForConfirmation(let a), .waitingForConfirmation(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Screen State

struct SyncProgressScreenState {
    let syncPhase: SyncPhase
    let friendName: String
    let friendColor: String
    let userColor: String
    let newNotesCount: Int
}

// MARK: - Result

struct SyncCompletedResult {
    let updatedFriend: Friend
    let newNoteCount: Int
}

// MARK: - Config (передаётся через ScreenType)

final class SyncProgressConfig: @unchecked Sendable {
    let friend: Friend
    let unsentNotes: [Note]
    let syncService: SyncService3
    let isDiscoveryActive: Bool
    let isNewFriend: Bool
    let noteRepository: NoteRepositoryProtocol
    let onSyncFinished: ((SyncCompletedResult) -> Void)?
    
    init(friend: Friend,
         unsentNotes: [Note],
         syncService: SyncService3,
         isDiscoveryActive: Bool,
         isNewFriend: Bool = false,
         noteRepository: NoteRepositoryProtocol,
         onSyncFinished: ((SyncCompletedResult) -> Void)?) {
        self.friend = friend
        self.unsentNotes = unsentNotes
        self.syncService = syncService
        self.isDiscoveryActive = isDiscoveryActive
        self.isNewFriend = isNewFriend
        self.noteRepository = noteRepository
        self.onSyncFinished = onSyncFinished
    }
}
