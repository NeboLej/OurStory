//
//  Date+.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

extension Date {
    func toReadableDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        return formatter.string(from: self)
    }
    
    func toMonthYearDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        
        return formatter.string(from: self)
    }
    
    func toHourMinuteDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return formatter.string(from: self)
    }
    
    
    func isCurrentMonth() -> Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    func getOffsetDate(_ offset: Int, component: Calendar.Component = Calendar.Component.day) -> Date {
        Calendar.current.date(byAdding: component, value: offset, to: self) ?? Date()
    }
}
