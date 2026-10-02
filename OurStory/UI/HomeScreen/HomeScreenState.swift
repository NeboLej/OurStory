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
    
    init(appStore: AppStore) {
        selectedStory = appStore.selectedStory
        selectedDate = appStore.selectedDate
        
        switch appStore.cloudSyncState {
        case .uploading, .downloading:
            isSyncing = true
        default:
            isSyncing = false
        }
    }
    
}
