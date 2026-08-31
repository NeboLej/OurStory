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
}


