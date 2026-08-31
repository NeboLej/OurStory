//
//  BaseDate.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

struct BaseDate: Hashable {
    let day: Int
    let month: Int
    let year: Int
    
    init(date: Date) {
        let calendar = Calendar.current
        day = calendar.component(.day, from: date)
        month = calendar.component(.month, from: date)
        year = calendar.component(.year, from: date)
    }
}
