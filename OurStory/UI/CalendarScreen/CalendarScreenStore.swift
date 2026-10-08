//
//  CalendarScreenStore.swift
//  OurStory
//
//  Created by Nebo on 08.10.2026.
//

import SwiftUI

@Observable
final class CalendarScreenStore: BaseStore {
    
    var state: CalendarScreenState {
        CalendarScreenState(monthPages: monthPages, selectedDate: selectedDate, selectedStory: selectedStory)
    }
    
    private(set) var monthPages: [CalendarViewMonthData] = []
    
    private var storyMap: [BaseDate: Story] {
        appStore.stories
    }
    private var stories: [Story] { Array(storyMap.values) }
    
    private var selectedStory: Story?
    private var selectedDate: Date?
    
    let calendar: Calendar = {
        var c = Calendar.current
        c.locale = Locale(identifier: "ru_RU")
        return c
    }()
    
    override init(appStore: AppStore) {
        super.init(appStore: appStore)
        monthPages = buildPages()
    }
    
    func send(_ action: CalendarScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .selectDate(let newDate):
                selectedStory = storyMap[BaseDate(date: newDate)]
                selectedDate = newDate
            case .closeNotePanel:
                selectedStory = nil
                selectedDate = nil
            }
        }
    }
    
    private func buildPages() -> [CalendarViewMonthData] {
        let today = Date.now
        var pages: [CalendarViewMonthData] = []
        
        let monthStarts = monthRange(from: stories, today: today)
        
        for monthStart in monthStarts {
            guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { continue }
            
            var cells: [CalendarViewCellData] = []
            var totalNotes = 0
            var activeDays = 0
            var cellIndex = 0
            
            let year = calendar.component(.year, from: monthStart)
            let month = calendar.component(.month, from: monthStart)
            
            // Leading placeholders
            if let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: range.lowerBound)) {
                let wd = calendar.component(.weekday, from: firstDay)
                let offset = wd == 1 ? 6 : wd - 2
                for _ in 0..<offset {
                    cells.append(CalendarViewCellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], noteCount: 0))
                    cellIndex += 1
                }
            }
            
            for day in range {
                guard let dayDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { continue }
                
                let story = storyMap[BaseDate(date: dayDate)]
                let colors = extractColors(from: story)
                let noteCount = story?.notes.count ?? 0
                
                if noteCount > 0 {
                    totalNotes += noteCount
                    activeDays += 1
                }
                
                cells.append(CalendarViewCellData(id: cellIndex,
                                        day: day,
                                        date: dayDate,
                                        dayNumber: day,
                                        isToday: calendar.isDateInToday(dayDate),
                                        colors: colors,
                                        noteCount: noteCount))
                cellIndex += 1
            }
            
            // Split into weeks of 7
            var weeks: [[CalendarViewCellData]] = []
            var week: [CalendarViewCellData] = []
            for cell in cells {
                week.append(cell)
                if week.count == 7 {
                    weeks.append(week)
                    week = []
                }
            }
            if !week.isEmpty {
                while week.count < 7 {
                    week.append(CalendarViewCellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], noteCount: 0))
                    cellIndex += 1
                }
                weeks.append(week)
            }
            
            pages.append(CalendarViewMonthData(id: pages.count,
                                     month: monthStart,
                                     weeks: weeks,
                                     totalNotes: totalNotes,
                                     activeDays: activeDays))
        }
        
        return pages
    }
    
    private func monthRange(from stories: [Story], today: Date) -> [Date] {
        let dates = stories.map(\.date)
        guard let earliest = dates.min() else {
            // No stories — show current month only
            let comps = calendar.dateComponents([.year, .month], from: today)
            return [calendar.date(from: comps)].compactMap { $0 }
        }
        
        let startComps = calendar.dateComponents([.year, .month], from: earliest)
        let endComps = calendar.dateComponents([.year, .month], from: today)
        
        guard var cursor = calendar.date(from: startComps),
              let end = calendar.date(from: endComps) else { return [] }
        
        var result: [Date] = []
        while cursor <= end {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }
    
    private func extractColors(from story: Story?) -> [Color] {
        guard let story, !story.notes.isEmpty else { return [] }
        let unique = Array(Set(story.notes.flatMap(\.friends).map(\.color)))
        guard !unique.isEmpty else { return [.red.opacity(0.8)] }
        return unique.sorted(by: <).map { Color(hex: $0) }
    }
}

