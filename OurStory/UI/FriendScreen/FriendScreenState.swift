//
//  FriendScreenState.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import Foundation

struct FriendScreenState {
    
    let friend: Friend
    let allStoriesCount: Int
    let notSeenStoriesCount: Int
    let lastSyncDate: Date?
    
    let syncPgogressStates: [SyncProgressState]
    let newNotesCount: Int
    
}
