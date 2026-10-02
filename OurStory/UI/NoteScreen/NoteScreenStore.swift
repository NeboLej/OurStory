//
//  NoteScreenStore.swift
//  OurStory
//
//  Created by Nebo on 04.09.2026.
//

import SwiftUI

@Observable
final class NoteScreenStore: BaseStore {
    
    private var title: String? = nil
    private var text: String = ""
    private var date: Date
    private var allFriends: [Friend] = []
    private var selectedFriends: [Friend] = []
    private let rootNote: Note?
    
    var state: NoteScreenState {
        NoteScreenState(title: title, text: text, date: date, isEditing: rootNote != nil, allFriends: appStore.allFriends, selectedFriends: selectedFriends)
    }
    
    init(appStore: AppStore, note: Note? = nil) {
        rootNote = note
        // Combine the selected calendar day with the current time
        let selectedDay = appStore.selectedDate
        let now = Date.now
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDay)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        date = calendar.date(from: components) ?? now
        
        super.init(appStore: appStore)
        
        if let note = note {
            title = note.title
            text = note.text
            date = note.date
            selectedFriends = note.friends
        } else if let localNote = loadLocalNote() {
            title = localNote.title
            text = localNote.text
            date = localNote.date
            selectedFriends = localNote.friends
        }
    }
    
    func send(_ action: NoteScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .selectFriend(let friend):
                if selectedFriends.contains(friend) {
                    selectedFriends.removeAll { $0 == friend }
                } else {
                    selectedFriends.append(friend)
                }
            case .saveNote(title: let title, text: let text):
                if let rootNote {
                    let updatedNote = rootNote.copy(title: title, date: date, text: text, friends: selectedFriends)
                    appStore.send(.editNote(updatedNote))
                } else {
                    let story = appStore.getSelectedStory()
                    let newNote = Note(rootStoryID: story.id, title: title.isEmpty ? nil : title, date: date, text: text, friends: selectedFriends, owner: nil)
                    appStore.send(.addNewNote(newNote))
                }
                
            case .selectDate(let newDate):
                date = newDate
            }
        }
    }
    
    private func loadLocalNote() -> Note? {
        nil
    }
}
