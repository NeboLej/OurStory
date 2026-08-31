//
//  Models.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

struct HCDay: Identifiable {
    let id: String = UUID().uuidString
    let value: Int
    let weekdaySymbol: String
    let date: Date
    let notFromThisMonth: Bool
}


struct HCWeek: Identifiable {
    let id: String = UUID().uuidString
    let days: [HCDay]
    
    static func load(from date: Date, value: Int) -> Self {
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
                    let isCurrentMonth = calendar.isDate(date, equalTo: modifiedDate, toGranularity: .month)
                    
                    days.append(HCDay(value: value, weekdaySymbol: weekdaySymbols[symbolIndex], date: date, notFromThisMonth: !isCurrentMonth))
                }
            }
        }
        
        return Self(days: days)
    }
}


