//
//  User.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

struct User: Hashable, Identifiable, Equatable {
    
    let id: UUID
    let name: String
    let color: String
    
    init(id: UUID = UUID(), name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
    
    init(from: UserModelGRDB) {
        self.id = from.id
        self.color = from.color
        self.name = from.name
    }
}

struct Friend: Hashable, Identifiable {
    
    let id: UUID
    let name: String
    let color: String
    
    let user: User?
    
    init(id: UUID = UUID(), name: String, color: String, user: User? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.user = user
    }
    
    init(from: FriendModelGRDB) {
        self.id = from.id
        self.color = from.color
        self.name = from.name
        
        if let user = from.user {
            self.user = User(from: user)
        } else {
            self.user = nil
        }
    }
    
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
