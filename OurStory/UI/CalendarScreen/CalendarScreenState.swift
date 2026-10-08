//
//  CalendarScreenState.swift
//  OurStory
//
//  Created by Nebo on 08.10.2026.
//

import SwiftUI

struct CalendarScreenState {
    var monthPages: [CalendarViewMonthData]
    var selectedDate: Date?
    var selectedStory: Story?
}

struct CalendarViewCellData: Identifiable {
    let id: Int
    let day: Int // -1 = placeholder
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let colors: [Color]
    let noteCount: Int
}

struct CalendarViewMonthData: Identifiable {
    let id: Int
    let month: Date
    let weeks: [[CalendarViewCellData]]
    let totalNotes: Int
    let activeDays: Int
}
