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
}

enum NavigateAction {
    case toCreateNote
}
