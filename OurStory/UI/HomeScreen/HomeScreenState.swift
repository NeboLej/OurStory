//
//  HomeScreenState.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

struct HomeScreenState {
    
    var selectedStory: Story?
    var selectedDate: Date
    var isSyncing: Bool
    var emptyStateText: String
    
    init(selectedStory: Story? = nil, selectedDate: Date, isSyncing: Bool, emptyStateText: String) {
        self.selectedStory = selectedStory
        self.selectedDate = selectedDate
        self.isSyncing = isSyncing
        self.emptyStateText = emptyStateText
    }
}
