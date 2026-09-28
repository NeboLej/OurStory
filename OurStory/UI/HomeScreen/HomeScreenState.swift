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
    
    init(appStore: AppStore) {
        selectedStory = appStore.selectedStory
        selectedDate = appStore.selectedDate
    }
    
}
