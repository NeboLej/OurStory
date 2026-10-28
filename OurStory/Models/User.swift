//
//  User.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

struct User: Hashable, Identifiable, Equatable, Codable {
    
    let id: UUID
    var name: String
    var color: String
    
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
    let lastSyncDate: Date?
    let isHidden: Bool
    
    init(id: UUID = UUID(), name: String, color: String, user: User? = nil, lastSyncDate: Date? = nil, isHidden: Bool = false) {
        self.id = id
        self.name = name
        self.color = color
        self.user = user
        self.lastSyncDate = lastSyncDate
        self.isHidden = isHidden
    }
    
    init(from: FriendModelGRDB) {
        self.id = from.id
        self.color = from.color
        self.name = from.name
        self.lastSyncDate = from.lastSyncDate
        self.isHidden = from.isHidden
        
        if let user = from.user {
            self.user = User(from: user)
        } else {
            self.user = nil
        }
    }
    
    func copy(user: User? = nil, lastSyncDate: Date? = nil) -> Friend {
        Friend(id: self.id, name: self.name, color: self.color, user: user ?? self.user, lastSyncDate: lastSyncDate ?? self.lastSyncDate, isHidden: self.isHidden)
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
        return friends.map { $0 }
    }
    
    static let ourStory = Friend(
        id: UUID(uuidString: "00000000-0000-0000-0000-4F5552535459")!,
        name: "Our Story 🦖",
        color: "B6D6BF",
        isHidden: true
    )
}
