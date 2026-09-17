//
//  HomeScreenAction.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import Foundation

enum HomeScreenAction {
    case createNewNote
    case updateFriendInNote(note: Note, friend: Friend)
    case editNote(Note)
    case addFriend
}
