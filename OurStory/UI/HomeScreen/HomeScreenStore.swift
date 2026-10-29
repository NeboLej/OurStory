//
//  HomeScreenStore.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import SwiftUI

@Observable
final class HomeScreenStore: BaseStore {
    
    var state: HomeScreenState {
        let isSyncing = appStore.cloudSyncState == .uploading || appStore.cloudSyncState == .downloading
        let currentDate = appStore.selectedDate
        return HomeScreenState(selectedStory: appStore.selectedStory, selectedDate: currentDate, isSyncing: isSyncing, emptyStateText: emptyTextByDate(for: currentDate))
    }
    
    private var emptyTextByDateDict: [BaseDate: String] = [:]
    private let calendar = Calendar.current
    
    private func emptyTextByDate(for date: Date) -> String {
        let baseDate = BaseDate(date: date)
        if let text = emptyTextByDateDict[baseDate] {
            return text
        } else {
            let text = TextFactory.shared.getEmptyDayText(date: date)
            emptyTextByDateDict[baseDate] = text
            return text
        }
    }
    
    func send(_ action: HomeScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .createNewNote: appStore.send(.toNote(nil))
            case .toFriendsList: appStore.send(.toFriendsList)
            case .toSettings: appStore.send(.toSettings)
            case .toCalendar: appStore.send(.toCalendar)
            case .toSearch: appStore.send(.toSearch)
            }
        }
    }
}
