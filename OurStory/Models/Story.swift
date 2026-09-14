//
//  Story.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

struct Story {
    var date: Date
    var title: String = "Title 1"
    var isUserTitle: Bool = false
    
    lazy var baseDate: BaseDate = { BaseDate(date: date) }()
    
    var notes: [Note]
    
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
