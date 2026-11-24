//
//  NoteListScreenState .swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import Foundation

struct NoteGroup: Identifiable {
    let id: String
    let date: Date
    let notes: [Note]
}

struct NoteListScreenState {
    let notes: [Note]
    let allFriends: [Friend]
    var preservesOrder: Bool = false

    var groupedNotes: [NoteGroup] {
        preservesOrder ? consecutiveDayGroups : sortedDayGroups
    }

    private var sortedDayGroups: [NoteGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: notes) { note in
            calendar.startOfDay(for: note.date)
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { NoteGroup(id: "\($0.key.timeIntervalSince1970)", date: $0.key, notes: $0.value.sorted { $0.date < $1.date }) }
    }

    /// Same day may appear in several groups, since the incoming order (relevance) must be kept.
    private var consecutiveDayGroups: [NoteGroup] {
        let calendar = Calendar.current
        var runs: [(date: Date, notes: [Note])] = []
        for note in notes {
            let day = calendar.startOfDay(for: note.date)
            if let last = runs.last, last.date == day {
                runs[runs.count - 1].notes.append(note)
            } else {
                runs.append((day, [note]))
            }
        }
        return runs.enumerated().map { index, run in
            NoteGroup(id: "\(index)-\(run.date.timeIntervalSince1970)", date: run.date, notes: run.notes)
        }
    }
}
