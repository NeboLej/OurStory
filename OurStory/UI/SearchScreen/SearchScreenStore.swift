//
//  SearchScreenStore.swift
//  OurStory
//

import SwiftUI

@Observable
final class SearchScreenStore: BaseStore {

    private(set) var searchResults: [Note] = []

    @ObservationIgnored
    private var searchTask: Task<Void, Never>?

    var state: SearchScreenState {
        SearchScreenState(notes: searchResults, allFriends: appStore.allFriends)
    }

    func send(_ action: SearchScreenAction) {
        switch action {
        case .search(let query):
            search(query)
        case .close:
            searchTask?.cancel()
            if !appStore.appCoordinator.path.isEmpty {
                appStore.appCoordinator.path.removeLast()
            }
        }
    }

    private func search(_ query: String) {
        searchTask?.cancel()

        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= NoteSearchEngine.minQueryLength else {
            searchResults = []
            return
        }

        let notes = appStore.allNotes
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            let results = await NoteSearchEngine.search(notes, query: query)
            guard !Task.isCancelled else { return }

            self?.searchResults = results
        }
    }
}
