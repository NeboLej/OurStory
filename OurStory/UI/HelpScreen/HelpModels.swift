//
//  HelpModels.swift
//  OurStory
//
//  Created by Nebo on 22.10.2026.
//

import Foundation

enum HelpType {
    static let helps: [Help] = [
        HelpType.exhangeStory
    ]
    
    static let exhangeStory = Help(id: 1, title: "Обмен историями", subtitle: "", blocks: [], internactiveBlock:
        InteractiveHelpBlock(animationName: "phones_exchange_1", playbackBlocks: [
            PlaybackHelpBlocks(playbackName: "approach", animationSpeed: 0.45, blocks: [
                .text("""
                    **Встретьтесь с другом**
                    Чтобы рассказать истории нужно *физически* быть рядом с вашим другом.
                    
                    Не переживайте, что не смогли передать историю сразу как только написали ее. Истории любят когда их вспоминают немного позже
                    """),
                .note("Не обязательно приближать телефоны друг к другу вплутную, достаточно быть в радиусе 10-15 метров"),
                .warning("Если приблизить телефоны в упор - сработает *Apple AirDrop* и вы обменяетесь своими контактами, это не то что там нужно")
            ]),
            PlaybackHelpBlocks(playbackName: "press", animationSpeed: 0.6, blocks: [
                .text("""
                    Нажмите кнопки передачи данных **одновременно**
                    """),
                .note("Не обязательно нажимать прямо в одну секунду, достаточно это сделать с разницей до 8-10 секунд"),
                
            ]),
            PlaybackHelpBlocks(playbackName: "exchange", animationSpeed: 0.7, blocks: [
                .text("""
                    **Дождитесь обмена историями**
                    """),
                .note("Если связь оборвалась попробуйте вернуться на экран друга и обменяться историями заново"),
            ]),
        ]))
}

struct Help: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    
    let blocks: [HelpBlock]
    let internactiveBlock: InteractiveHelpBlock
}

struct InteractiveHelpBlock {
    let animationName: String
    let playbackBlocks: [PlaybackHelpBlocks]
}

struct PlaybackHelpBlocks {
    let playbackName: String
    let animationSpeed: Double
    let blocks: [HelpBlock]
}

enum HelpBlock {
    case text(String)
    case heading(String)
    case image(String)
    case note(String)
    case warning(String)
    case button(String)
}

