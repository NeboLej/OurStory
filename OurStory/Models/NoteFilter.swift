//
//  NoteFilter.swift
//  OurStory
//

import Foundation

enum NoteFilter: Hashable {
    case byDate(BaseDate)
    case byFriend(UUID)
    case every(noteID: [UUID])
    /// Keeps the given order of IDs (e.g. search relevance).
    case ranked(noteIDs: [UUID])

    var preservesOrder: Bool {
        if case .ranked = self { true } else { false }
    }
}
