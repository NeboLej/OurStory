//
//  HorizontalCalendarStore.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import SwiftUI

@Observable
final class HorizontalCalendarStore: BaseStore {
    
    private(set) var weeks: [HCWeek] = []
    /// ID of the "current" week that should be centered on launch
    private(set) var currentWeekID: String = ""
    
    var state: HorizontalCalendarState {
        HorizontalCalendarState(appStore: appStore, weeks: weeks)
    }
    
    override init(appStore: AppStore) {
        super.init(appStore: appStore)
        let loaded = (-1...1).map { loadWeek(from: Date.now, value: $0) }
        weeks = loaded
        currentWeekID = loaded[1].id // middle week = current
    }
    
    func send(_ action: HorizontalCalendarActions, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .selectedDate(let newDate):
                appStore.send(.selectedDate(newDate))
            case .addNextTwoWeeks:
                guard let lastWeekDate = weeks.last?.days.first?.date else { return }
                weeks.append(contentsOf: [
                    loadWeek(from: lastWeekDate, value: 1),
                    loadWeek(from: lastWeekDate, value: 2),
                ])
                weeks.removeFirst(2)
            case .addPreviousTwoWeeks:
                guard let firstWeekDate = weeks.first?.days.first?.date else { return }
                weeks.insert(contentsOf: [
                    loadWeek(from: firstWeekDate, value: -2),
                    loadWeek(from: firstWeekDate, value: -1),
                ], at: 0)
                weeks.removeLast(2)
            }
        }
    }
    
    /// Returns a formatted month/year string for the given week index
    func monthTitle(for week: HCWeek) -> String {
        guard let midDate = week.days.first?.date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: midDate).capitalized
    }
    
    private func loadWeek(from date: Date, value: Int) -> HCWeek {
        var days: [HCDay] = []
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ru_RU")
        let weekdaySymbols = calendar.shortWeekdaySymbols
        
        let modifiedDate = calendar.date(byAdding: .weekOfMonth, value: value, to: date) ?? .now
        
        if let interval = calendar.dateInterval(of: .weekOfMonth, for: modifiedDate) {
            let startOfWeek = interval.start
            
            for index in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: index, to: startOfWeek) {
                    let value = calendar.component(.day, from: date)
                    let symbolIndex = calendar.component(.weekday, from: date) - 1
                    
                    days.append(HCDay(value: value, weekdaySymbol: weekdaySymbols[symbolIndex], date: date))
                }
            }
        }
        
        return HCWeek(days: days)
    }
}
