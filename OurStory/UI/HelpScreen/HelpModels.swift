//
//  HelpModels.swift
//  OurStory
//
//  Created by Nebo on 22.10.2026.
//

import Foundation

enum HelpType {
    static let helps: [Help] = [
        HelpType.addedFriend,
        HelpType.exhangeStory,
    ]
    
    static let exhangeStory = Help(id: 2, title: "Обмен историями", subtitle: "", blocks: [], internactiveBlock:
        InteractiveHelpBlock(animationName: "phones_exchange", playbackBlocks: [
            PlaybackHelpBlocks(playbackName: "approach", animationSpeed: 0.55, blocks: [
                .text("""
                    **Встретьтесь с другом**
                    Чтобы рассказать истории нужно *физически* быть рядом с вашим другом.
                    
                    Не переживайте, что не смогли передать историю сразу как только написали ее. Истории любят когда их вспоминают немного позже
                    """),
                .note("Не обязательно приближать телефоны друг к другу вплутную, достаточно быть в радиусе 10-15 метров"),
                .warning("Если приблизить телефоны в упор - сработает *Apple AirDrop* и вы обменяетесь своими контактами, это не то, что там нужно")
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
    
    static let addedFriend = Help(id: 1, title: "Добавление друга", subtitle: "", blocks: [], internactiveBlock:
        InteractiveHelpBlock(animationName: "friends_guide", playbackBlocks: [
            PlaybackHelpBlocks(playbackName: "storytellers", animationSpeed: 1.4, blocks: [
                .text("Чтобы упомянать друга в историх нужно добавить его в список вашех друзей"),
                .note("Не переживайте, чтобы начать записывать общие истории друг не обязательно должен быть рядом. И даже не обязательно должен скачивать приложение")
            ]),
            
            PlaybackHelpBlocks(playbackName: "add_remote", animationSpeed: 1, blocks: [
                .text("""
                    **Если друга сейчас нет рядом** 
                    
                     1.  Нажмите кнопку "ДОБАВИТЬ ДРУГА" и пункт "СОЗДАТЬ ПРОФИЛЬ ДРУГА"
                     2.  Укажите имя и выберите цвет
                     3.  **Отлично!** С этого момента друга можно упомнянать в ваших историях
                    
                     4.  Когда вы встретитесь просто одновременно нажмите на кнопку "РАССКАЗАТЬ ИСТОРИИ" в созданном профиле
                     5.  Дождитесь окончания обмена данными
                    """),
                .note("После этого профиль друга, который создали вы, будет связан с профилем, созданным вашим другом")
            ]),
            
            PlaybackHelpBlocks(playbackName: "add_nearby", animationSpeed: 1, blocks: [
                .text("""
                    **Если друг сейчас рядом** 
                    
                     1.  Нажмите кнопку "ДОБАВИТЬ ДРУГА" и пункт "ПОЛУЧИТЬ ПРОФИЛЬ ДРУГА"
                     2.  Ваш друг должен нажать тоже "ПОЛУЧИТЬ ПРОФИЛЬ ДРУГА" или "РАССКАЗАТЬ ИСТОРИИ" если он уже создавал ваш профиль ранее 
                     3.  Дождитесь синхронизации
                     4.  **Отлично!** С этого момента друга можно упомнянать в ваших историях
                    
                    """),
                .warning("Если во время поиска друга не удалось найти, вы можете вернуться и нажать на кнопку \"ПОЛУЧИТЬ ПРОФИЛЬ ДРУГА\" еще раз")
            ]),
        ])
    )
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

import SwiftUI

#Preview {
    NavigationStack {
        HelpScreen(help: HelpType.addedFriend)
    }
}

