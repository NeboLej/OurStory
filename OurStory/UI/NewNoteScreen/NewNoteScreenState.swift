//
//  NewNoteScreenState.swift
//  OurStory
//
//  Created by Nebo on 04.09.2026.
//

import Foundation

struct NewNoteScreenState {
    
    let title: String?
    let text: String
    let date: Date
    
    let allFriends: [Friend]
    let selectedFriends: [Friend]
}
