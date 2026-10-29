//
//  FriendScreenAction.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import Foundation

enum FriendScreenAction {
    case editFriend(name: String, color: String)
    case deleteFriendWithStories
    case hideFriend
    case syncFriend
    case applyUserProfile
    case toAllNotes
    case toUnsentNotes
    case unlinkFriend
    case dismissUserSuggestion
    
    // Auto-search lifecycle
    case startSearching
    case stopSearching
    case retrySearching
}
