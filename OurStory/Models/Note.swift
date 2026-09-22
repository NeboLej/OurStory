//
//  Note.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

struct Note: Identifiable, Equatable, Hashable {
      
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
        if let owner = from.note.owner {
            self.owner = Friend(from: owner)
        } else {
            self.owner = nil
        }
    }
    
    func copy(title: String? = nil, date: Date? = nil, text: String? = nil, friends: [Friend]? = nil) -> Self {
        Note(id: self.id, rootStoryID: self.rootStoryID, title: title ?? self.title, date: date ?? self.date, text: text ?? self.text, friends: friends ?? self.friends, owner: self.owner)
    }
}
