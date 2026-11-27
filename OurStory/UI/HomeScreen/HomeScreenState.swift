//
//  HomeScreenState.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

struct HomeScreenState {
    
    var selectedNotes: [Note]
    var selectedDate: Date
    var cloudSyncState: CloudSyncState
    var emptyStateText: String
    
    init(selectedNotes: [Note], selectedDate: Date, cloudSyncState: CloudSyncState, emptyStateText: String) {
        self.selectedNotes = selectedNotes
        self.selectedDate = selectedDate
        self.cloudSyncState = cloudSyncState
        self.emptyStateText = emptyStateText
    }
}
