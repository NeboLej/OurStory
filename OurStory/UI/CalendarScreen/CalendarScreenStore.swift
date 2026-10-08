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
    
    let cal: Calendar = {
        var c = Calendar.current
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
            guard let range = cal.range(of: .day, in: .month, for: monthStart) else { continue }
            
            var cells: [CalendarViewCellData] = []
            var totalNotes = 0
            var activeDays = 0
            var cellIndex = 0
            
            let year = cal.component(.year, from: monthStart)
            let month = cal.component(.month, from: monthStart)
            
            // Leading placeholders
            if let firstDay = cal.date(from: DateComponents(year: year, month: month, day: range.lowerBound)) {
                let wd = cal.component(.weekday, from: firstDay)
                let offset = wd == 1 ? 6 : wd - 2
                for _ in 0..<offset {
                    cells.append(CalendarViewCellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], noteCount: 0))
                    cellIndex += 1
                }
            }
            
            for day in range {
                guard let dayDate = cal.date(from: DateComponents(year: year, month: month, day: day)) else { continue }
                
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
                                        isToday: cal.isDateInToday(dayDate),
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
            let comps = cal.dateComponents([.year, .month], from: today)
            return [cal.date(from: comps)].compactMap { $0 }
        }
        
        let startComps = cal.dateComponents([.year, .month], from: earliest)
        let endComps = cal.dateComponents([.year, .month], from: today)
        
        guard var cursor = cal.date(from: startComps),
              let end = cal.date(from: endComps) else { return [] }
        
        var result: [Date] = []
        while cursor <= end {
            result.append(cursor)
            guard let next = cal.date(byAdding: .month, value: 1, to: cursor) else { break }
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

