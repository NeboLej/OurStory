//
//  AppStore.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

@Observable
final class AppStore {
    
    var currentStory: Story?
    
    init() {
        currentStory = Story.example
    }
    
    func send(_ action: AppAction) {
        
    }
}
