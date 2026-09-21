//
//  AppActions.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import Foundation

enum AppAction {
    case selectedDate(Date)
    case addNewNote(Note)
    case editNote(Note)
    case addNewFriend(Friend)
    case editFriend(Friend)
    case deleteFriend(Friend)
}

enum NavigateAction {
    case toNote(Note?)
    case toFriendsList
    case toFriend(Friend)
    case toNewFriend
}
