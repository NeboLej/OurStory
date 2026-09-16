//
//  Story.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

struct Story {
    let id: UUID
    let date: Date
    let title: String
    let isUserTitle: Bool
    
    lazy var baseDate: BaseDate = { BaseDate(date: date) }()
    
    private(set) var notes: [Note]
    
    init(id: UUID = UUID(), date: Date, title: String = "Title 1", isUserTitle: Bool = false, notes: [Note] = []) {
        self.id = id
        self.date = date
        self.title = title
        self.isUserTitle = isUserTitle
        self.notes = notes
    }
    
    init(from: StoryWithNotes) {
        id = from.story.id
        date = from.story.date
        title = from.story.title
        isUserTitle = from.story.isUserTitle
        notes = from.notes.map { Note(from: $0) }
    }
    
    static var example1: Story {
        Story(date: Date(), title: "Салки и шишки были славные но я облажался ", isUserTitle: true, notes: [Note.example1, Note.example2, Note.example3])
    }
    
    func addNewNote(_ note: Note) -> Self {
        var copy = self
        copy.notes.insert(note, at: 0)
        return copy
    }
    
    func replaceNote(_ note: Note) -> Self {
        var copy = self
        copy.notes = copy.notes.replaceFirst(note)
        return copy
    }
}
