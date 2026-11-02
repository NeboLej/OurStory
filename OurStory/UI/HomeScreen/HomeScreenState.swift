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
    var isSyncing: Bool
    var emptyStateText: String
    
    init(selectedNotes: [Note], selectedDate: Date, isSyncing: Bool, emptyStateText: String) {
        self.selectedNotes = selectedNotes
        self.selectedDate = selectedDate
        self.isSyncing = isSyncing
        self.emptyStateText = emptyStateText
    }
}
