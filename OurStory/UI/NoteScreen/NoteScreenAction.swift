//
//  NoteScreenAction.swift
//  OurStory
//
//  Created by Nebo on 04.09.2026.
//

import Foundation

enum NoteScreenAction {
    case selectFriend(Friend)
    case saveNote(title: String, text: String)
    case selectDate(Date)
}
