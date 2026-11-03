//
//  BaseStore.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

@MainActor
class BaseStore {
    let appStore: AppStoreProtocol
    
    init(appStore: AppStoreProtocol) {
        self.appStore = appStore
    }
}
