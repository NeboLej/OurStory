//
//  FriendScreenState.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import Foundation

// Статус поиска друга поблизости
enum FriendSearchStatus: Equatable {
    case idle
    case searching
    case found
    case friendReady  // Friend found AND already pressed "tell stories"
    case notFound
}

struct FriendScreenState {
    
    let friend: Friend
    let allStoriesCount: Int
    let notSeenStoriesCount: Int
    let lastSyncDate: Date?
    
    let searchStatus: FriendSearchStatus
    let showUserSuggestion: Bool
    let hasUserProfileDifference: Bool
    
    var isSyncButtonEnabled: Bool {
        // Первая синхронизация (user ещё не привязан) — кнопка всегда доступна
        if friend.user == nil { return true }
        // Повторная синхронизация — только когда друг найден поблизости
        return searchStatus == .found || searchStatus == .friendReady
    }
}
