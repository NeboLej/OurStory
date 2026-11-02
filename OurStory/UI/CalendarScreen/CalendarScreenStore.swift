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
        CalendarScreenState(monthPages: monthPages, selectedDate: selectedDate, selectedNotes: selectedNotes)
    }
    
    private(set) var monthPages: [CalendarViewMonthData] = []
    
    private var noteMap: [BaseDate: [Note]] {
        appStore.notesByDate
    }
    
    private var selectedNotes: [Note]?
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
                selectedNotes = noteMap[BaseDate(date: newDate)]
                selectedDate = newDate
            case .closeNotePanel:
                selectedNotes = nil
                selectedDate = nil
            }
        }
    }
    
    private func buildPages() -> [CalendarViewMonthData] {
        let today = Date.now
        var pages: [CalendarViewMonthData] = []
        
        let allDates = noteMap.keys.compactMap { Calendar.current.date(from: DateComponents(year: $0.year, month: $0.month, day: $0.day)) }
        let monthStarts = monthRange(from: allDates, today: today)
        
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
                    cells.append(CalendarViewCellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], dots: [], noteCount: 0))
                    cellIndex += 1
                }
            }
            
            for day in range {
                guard let dayDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { continue }
                
                let notes = noteMap[BaseDate(date: dayDate)]
                let colors = extractBorderColors(from: notes)
                let dots = extractDots(from: notes)
                let noteCount = notes?.count ?? 0
                
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
                                        dots: dots,
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
                    week.append(CalendarViewCellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], dots: [], noteCount: 0))
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
    
    private func monthRange(from dates: [Date], today: Date) -> [Date] {
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
    
    private var profileColor: Color {
        Color(hex: appStore.user.color)
    }
    
    private func extractBorderColors(from notes: [Note]?) -> [Color] {
        guard let notes, !notes.isEmpty else { return [] }
        
        var colorHexes = Set<String>()
        
        for note in notes {
            if let owner = note.owner {
                colorHexes.insert(owner.color)
            } else {
                note.friends.forEach { colorHexes.insert($0.color) }
                colorHexes.insert(appStore.user.color)
            }
        }
        
        return colorHexes.sorted().map { Color(hex: $0) }
    }
    
    private func extractDots(from notes: [Note]?) -> [Dot] {
        guard let notes, !notes.isEmpty else { return [] }
        
        var dots: [Dot] = []
        var hasProfileDot = false
        var friendHexes = Set<String>()
        var ownerHexes = Set<String>()
        
        for note in notes {
            if let owner = note.owner {
                ownerHexes.insert(owner.color)
            } else {
                note.friends.forEach { friendHexes.insert($0.color) }
                hasProfileDot = true
            }
        }
        
        for hex in ownerHexes.sorted() {
            dots.append(Dot(color: Color(hex: hex), style: .stroke))
        }
        
        for hex in friendHexes.sorted() {
            dots.append(Dot(color: Color(hex: hex), style: .fill))
        }

        if hasProfileDot {
            dots.append(Dot(color: profileColor, style: .fill))
        }
        
        return dots
    }
}

