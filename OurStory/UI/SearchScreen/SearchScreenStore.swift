//
//  SearchScreenStore.swift
//  OurStory
//

import SwiftUI

@Observable
final class SearchScreenStore: BaseStore {
    
    private(set) var searchResults: [Note] = []
    
    var state: SearchScreenState {
        SearchScreenState(notes: searchResults, allFriends: appStore.allFriends)
    }
    
    func send(_ action: SearchScreenAction) {
        switch action {
        case .search(let query):
            guard query.count >= 3 else {
                searchResults = []
                return
            }
            searchResults = appStore.searchNotes(query: query)
        case .close:
            if !appStore.appCoordinator.path.isEmpty {
                appStore.appCoordinator.path.removeLast()
            }
        }
    }
}
