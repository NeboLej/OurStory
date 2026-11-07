//
//  TextFactory.swift
//  OurStory
//
//  Created by Nebo on 27.10.2026.
//

import Foundation

class TextFactory {
    
    static let shared = TextFactory()
    
    private init() {}
    
    func getEmptyDayText(date: Date) -> String {
        let calendar = Calendar.current
        let texts: [String]
        if calendar.isDateInToday(date) {
            texts = L10n.currentDayTexts
        } else if date < calendar.startOfDay(for: .now) {
            texts = L10n.oldDayTexts
        } else {
            texts = L10n.futureDayTexts
        }
        return texts.randomElement() ?? ""
    }
}
