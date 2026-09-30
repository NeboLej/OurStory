//
//  NoteListScreenAction.swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import Foundation

enum NoteListScreenAction {
    case editNote(Note)
    case updateFriendInNote(note: Note, friend: Friend)
    case selectMenuNote(UUID?)
    case selectFriendsNote(Note?)
    case updateNotes([Note])
}
