//
//  FriendScreenAction.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import Foundation

enum FriendScreenAction {
    case editFriend(name: String, color: String)
    case deleteFriend
    case syncFriend
    case confirmSyncFriend(Bool)
    case toNewNotes
    case exitSync
    case applyUserProfile
    case toAllNotes
    case toUnsentNotes
    case unlinkFriend
    
    // Auto-search lifecycle
    case startSearching
    case stopSearching
    case retrySearching
}
