//
//  HomeScreenState.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

struct HomeScreenState {
    
    var currentStory: Story?
    
    init(appStore: AppStore) {
        currentStory = appStore.currentStory
    }
    
}
