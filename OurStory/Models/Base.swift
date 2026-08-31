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
    
    let notes: [Note]
    
    static var example: Story {
        Story(date: Date(), title: "Example story", isUserTitle: false, notes: [Note.example])
    }
}


struct Note: Identifiable {
    let id: UUID = UUID()
    let title: String?
    let date: Date
    let text: String
    let friends: [Friend]
    let owner: User?
    
    static var example: Note {
        Note(title: nil, date: Date(), text: "Ходил в лес, набрал шишек для плова потом вернулся домой и готовился к касстингу на роль девушки джеймса бонда", friends: [], owner: nil)
    }
}

protocol User {
    var name: String { get }
}

struct Friend: User  {
    let name: String
}
