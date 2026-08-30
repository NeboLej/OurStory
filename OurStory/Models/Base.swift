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
}


struct Note {
    let title: String?
    let date: Date
    let text: String
    let friends: [Friend]
    let owner: User
}

protocol User {
    var name: String { get }
}

struct Friend: User  {
    let name: String
}
