//
//  Base.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import Foundation


struct Story {
    var date: Date
    var title: String = "Title 1"
    var isUserTitle: Bool = false
    
    lazy var baseDate: BaseDate = { BaseDate(date: date) }()
    
    var notes: [Note]
    
    static var example1: Story {
        Story(date: Date(), title: "Салки и шишки были славные но я облажался ", isUserTitle: true, notes: [Note.example1, Note.example2, Note.example3])
    }
    
    func addNewNote(_ note: Note) -> Self {
        var copy = self
        copy.notes.insert(note, at: 0)
        return copy
    }
    
    func replaceNote(_ note: Note) -> Self {
        var copy = self
        copy.notes = copy.notes.replaceFirst(note)
        return copy
    }
}


struct Note: Identifiable, Equatable {
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    let title: String?
    let date: Date
    let text: String
    let friends: [Friend]
    let owner: User?
    
    init(id: UUID = UUID(), title: String? = nil, date: Date, text: String, friends: [Friend], owner: User? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.text = text
        self.friends = friends
        self.owner = owner
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
    
    func copy(title: String? = nil, date: Date? = nil, text: String? = nil, friends: [Friend]? = nil) -> Self {
        Note(id: self.id, title: title ?? self.title, date: date ?? self.date, text: text ?? self.text, friends: friends ?? self.friends, owner: self.owner)
    }
}

protocol User {
    var name: String { get }
    var color: String { get }
}

struct Friend: User, Hashable, Identifiable  {
    
    let id: UUID = UUID()
    let name: String
    let color: String
    
    
    static var mock: [Friend] = [
        Friend(name: "Олег", color: "308446"),
        Friend(name: "Стас", color: "FFBCD9"),
        Friend(name: "Настя", color: "F3A505"),
        Friend(name: "Вероника", color: "F4C430"),
        Friend(name: "Виктор Сергеевич", color: "1FCECB")
    ]
    
    
    static func getRandomFriends() -> [Friend] {
        let count = (0...3).randomElement()!
        var friends: Set<Friend> = []
        (0..<count).forEach { _ in
            let random = mock.randomElement()!
            friends.insert(random)
        }
        print(count)
        return friends.map { $0 }
    }
}
