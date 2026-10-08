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
    private var suggestedFriend: Friend? = nil
    private var suggestionTask: Task<Void, Never>? = nil
    private let rootNote: Note?
    
    var state: NoteScreenState {
        NoteScreenState(title: title, text: text, date: date, isEditing: rootNote != nil, allFriends: appStore.allFriends, selectedFriends: selectedFriends, suggestedFriend: suggestedFriend)
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
            case .addNewFriend:
                appStore.send(.toNewFriend)
            case .updateStoryText(let text):
                checkForFriendMention(in: text)
            case .acceptSuggestion:
                if let friend = suggestedFriend, !selectedFriends.contains(friend) {
                    selectedFriends.append(friend)
                }
                suggestedFriend = nil
            }
        }
    }
    
    private func checkForFriendMention(in text: String) {
        suggestionTask?.cancel()
        suggestionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self else { return }
            self.suggestedFriend = self.findMatchingFriend(in: text)
        }
    }
    
    private func findMatchingFriend(in text: String) -> Friend? {
        let lastWord = extractLastWord(from: text)
        guard lastWord.count >= 3 else { return nil }
        
        let unselected = appStore.allFriends.filter { !selectedFriends.contains($0) }
        
        for friend in unselected {
            let nameParts = friend.name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            for part in nameParts {
                if lastWord.fuzzyMatchesName(part) { return friend }
            }
            
            if let userName = friend.user?.name {
                let userParts = userName.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                for part in userParts {
                    if lastWord.fuzzyMatchesName(part) { return friend }
                }
            }
        }
        return nil
    }
    
    private func extractLastWord(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lastSpace = trimmed.lastIndex(where: { $0.isWhitespace || $0.isNewline }) else {
            return trimmed
        }
        return String(trimmed[trimmed.index(after: lastSpace)...])
    }
    
    private func loadLocalNote() -> Note? {
        nil
    }
}
