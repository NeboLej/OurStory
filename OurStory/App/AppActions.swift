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
    case syncNotes([SyncNote], Friend)
    case markNotesSynced(noteIDs: [UUID], friendID: UUID)
    case editNote(Note)
    case deleteNote(Note)
    case addNewFriend(Friend)
    case editFriend(Friend)
    case deleteFriend(Friend)
    case deleteFriendWithNotes(Friend)
    case hideFriend(Friend)
    case editProfile(name: String, color: String)
}

enum NavigateAction {
    case toNote(Note?)
    case toFriendsList
    case toFriend(Friend)
    case toNewFriend
    case toSettings
    case toEditProfile
    case toNotesList(title: String, filter: NoteFilter)
    case toLogs
    case toCalendar
    case toSearch
    case toHelpListScreen
    case toNotificationSettings
}
