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
    
    private let currentDayTexts: [String] = ["Как прошёл твой день?", "Ну что, как оно было?", "У этого дня есть своя история",
                                             "Что хочется запомнить сегодня?", "Давай сохраним этот день", "Даже пара слов — уже история",
                                             "Уже вижу как ты вспомнишь об этой истории через пару лет", "Запиши, пока свежо в памяти"]
    private let oldDayTexts: [String] = ["Помнишь этот день?", "Кажется, здесь есть что вспомнить", "Что осталось в памяти?",
                                         "У этого дня ещё есть шанс попасть в историю", "О, а что было в этот день?", "Время вспомнить кое-что хорошее",
                                         "Никогда не поздно записать что-то важное", "Что-то интересное наверняка было", "Попробуй вернуться в тот день"]
    private let featureDayTexts: [String] = ["Есть планы на этот день?", "Каким будет этот день?", "Запланируешь что-нибудь хорошее?", "История ещё впереди ✨",
                                             "Пусть у будущего будет маленькая подсказка."]
    
    func getEmptyDayText(date: Date) -> String {
        let calendar = Calendar.current
        let texts: [String]
        if calendar.isDateInToday(date) {
            texts = currentDayTexts
        } else if date < calendar.startOfDay(for: .now) {
            texts = oldDayTexts
        } else {
            texts = featureDayTexts
        }
        return texts.randomElement() ?? ""
    }
}
