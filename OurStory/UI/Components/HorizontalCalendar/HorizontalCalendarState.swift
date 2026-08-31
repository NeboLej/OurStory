//
//  HorizontalCalendarState.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

struct HorizontalCalendarState {
    
    let weeks: [HCWeek]
    let selectionDate: Date
    
    init(appStore: AppStore, weeks: [HCWeek]) {
        selectionDate = appStore.selectionDate
        self.weeks = weeks
    }
}
