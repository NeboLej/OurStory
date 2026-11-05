//
//  NoteFilter.swift
//  OurStory
//

import Foundation

enum NoteFilter: Hashable {
    case byDate(BaseDate)
    case byFriend(UUID)
    case bySearch(String)
    case every(noteID: [UUID])
}
