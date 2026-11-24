//
//  SearchScreenState.swift
//  OurStory
//

import Foundation

struct SearchScreenState {
    let notes: [Note]
    let allFriends: [Friend]
    
    var noteIDs: [UUID] { notes.map(\.id) }
}
