//
//  FriendScreenState.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import Foundation

// Фазы анимации синхронизации
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

// Статус поиска друга поблизости
enum FriendSearchStatus: Equatable {
    case idle
    case searching
    case found
    case notFound
}

struct FriendScreenState {
    
    let friend: Friend
    let allStoriesCount: Int
    let notSeenStoriesCount: Int
    let lastSyncDate: Date?
    
    let syncPgogressStates: [SyncProgressState]
    let newNotesCount: Int
    
    let searchStatus: FriendSearchStatus
    let syncPhase: SyncPhase
    
    var isSyncButtonEnabled: Bool {
        guard syncPhase == .idle else { return false }
        // Первая синхронизация (user ещё не привязан) — кнопка всегда доступна
        if friend.user == nil { return true }
        // Повторная синхронизация — только когда друг найден поблизости
        return searchStatus == .found
    }
    
    var isInSync: Bool {
        switch syncPhase {
        case .idle: return false
        default: return true
        }
    }
}
