//
//  Note.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

struct Note: Identifiable, Equatable {
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    let title: String?
    let date: Date
    let text: String
    let friends: [Friend]
    let owner: Friend?
    
    let rootStoryID: UUID
    
    init(id: UUID = UUID(), rootStoryID: UUID = UUID(), title: String? = nil, date: Date, text: String, friends: [Friend], owner: Friend? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.text = text
        self.friends = friends
        self.owner = owner
        self.rootStoryID = rootStoryID
    }
    
    init(from: NoteWithFriends) {
        self.id = from.note.id
        self.title = from.note.title
        self.date = from.note.date
        self.text = from.note.text
        self.friends = from.friends.map { Friend(from: $0) }
        self.rootStoryID = from.note.rootStoryID
        self.owner = nil
    }
    
    static var example1: Note {
        Note(title: nil, date: Date(), text: "Ходил в лес, набрал шишек для плова потом вернулся домой и готовился к касстингу на роль девушки джеймса бонда", friends: [
        ], owner: nil)
    }
    
    static var example2: Note {
        Note(title: "Салочки-сасалочки", date: Date(), text: "Вечером случайно встретил Олега, решили раз уж встретились то нужно выяснить кто из нас лучше в салки играет, 16 часов выясняли. Олег оказался реально мастером, респект ему и его бабушкам", friends: [
            Friend(name: "Стас", color: "f4d3a1"), Friend(name: "Марина", color: "66ee33")
        ], owner: nil)
    }
    
    static var example3: Note {
        Note(title: "Сладкая месть", date: Date(), text: "Пол дня ждал тоху у подъезда, весь год тренился играть в салочки и сегодня то я ему точно покажу кто тут батя. 💪", friends: [], owner: Friend(name: "Стас", color: "f4d3a1"))
    }
    
    func copy(title: String? = nil, date: Date? = nil, text: String? = nil, friends: [Friend]? = nil, rootStoryID: UUID? = nil) -> Self {
        Note(id: self.id, rootStoryID: rootStoryID ?? self.rootStoryID, title: title ?? self.title, date: date ?? self.date, text: text ?? self.text, friends: friends ?? self.friends, owner: self.owner)
    }
}
