//
//  NewNoteScreenAction.swift
//  OurStory
//
//  Created by Nebo on 04.09.2026.
//

import Foundation

enum NewNoteScreenAction {
    case selectFriends([Friend])
    case saveNote(title: String?, text: String)
}
