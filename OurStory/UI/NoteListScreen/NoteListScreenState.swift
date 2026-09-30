//
//  NoteListScreenState .swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import Foundation

struct NoteListScreenState {
    let notes: [Note]
    let allFriends: [Friend]
    
    var groupedNotes: [(date: Date, notes: [Note])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: notes) { note in
            calendar.startOfDay(for: note.date)
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, notes: $0.value.sorted { $0.date < $1.date }) }
    }
}
