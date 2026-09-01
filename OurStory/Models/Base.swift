//
//  Base.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import Foundation


struct Story {
    let date: Date
    let title: String
    let isUserTitle: Bool
    
    lazy var baseDate: BaseDate = { BaseDate(date: date) }()
    
    let notes: [Note]
    
    static var example1: Story {
        Story(date: Date(), title: "Салки и шишки были славные но я облажался ", isUserTitle: true, notes: [Note.example1, Note.example2, Note.example3])
    }
}


struct Note: Identifiable {
    let id: UUID = UUID()
    let title: String?
    let date: Date
    let text: String
    let friends: [Friend]
    let owner: User?
    
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
}

protocol User {
    var name: String { get }
    var color: String { get }
}

struct Friend: User, Hashable  {
    let name: String
    let color: String
    
    
    static var mock: [Friend] = [
        Friend(name: "Олег", color: "470736"),
        Friend(name: "Стас", color: "1560BD"),
        Friend(name: "Настя", color: "B57281"),
        Friend(name: "Вероника", color: "D1E231"),
        Friend(name: "Виктор Сергеевич", color: "808080")
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
