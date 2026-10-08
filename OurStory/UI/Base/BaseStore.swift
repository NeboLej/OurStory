//
//  BaseStore.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

@MainActor
class BaseStore {
    let appStore: AppStore
    
    init(appStore: AppStore) {
        self.appStore = appStore
    }
}
