//
//  AppStore+Methods.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import Foundation

extension AppStore {
    
    
    //MARK: NOTE -
    func addNewNote(_ note: Note) {
        guard let selectedStory else { fatalError() }
        let needSaveStory = selectedStory.notes.isEmpty
        let updatedStory = selectedStory.addNewNote(note)
        
        self.selectedStory = updatedStory
        stories[BaseDate(date: updatedStory.date)] = updatedStory
        
        Task {
            if needSaveStory {
                await storyRepository.newStory(updatedStory)
            }
            
            await noteRepository.addNote(note)
        }
    }
    
    func syncNotes(_ notes: [SyncNote], friend: Friend) {
        let notes = notes.sorted { $0.date < $1.date }
        var allNewNotes: [Note] = []
        guard let firstNoteDate = notes.first?.date, let lastNoteDate = notes.last?.date else { return }
        
        Task {
            let syncStories = await storyRepository.getStories(startDate: firstNoteDate.getOffsetDate(-1, component: .day),
                                                               endDate: lastNoteDate.getOffsetDate(1, component: .day))
            
            for note in notes {
                var updatedStory: Story
                
                if let story = syncStories.first(where: { $0.baseDate == note.baseDate }) {
                    updatedStory = story
                } else {
                    updatedStory = Story(date: note.date)
                    await storyRepository.newStory(updatedStory)
                }
                    
                let newNote = Note(id: note.id, rootStoryID: updatedStory.id, title: note.title, date: note.date, text: note.text, friends: [], owner: friend)
                allNewNotes.append(newNote)
                let currentUpdateStory = updatedStory.addNewNote(newNote)
                
                await noteRepository.saveOrUpdateNote(newNote)
                stories[updatedStory.baseDate] = currentUpdateStory
                
                if selectedStory?.id == currentUpdateStory.id {
                    selectedStory = currentUpdateStory
                }
            }
            sortedNotes = allNewNotes
        }
    }
    
    func moveNoteToStory(_ note: Note, newBaseDate: BaseDate) {
        if let existingStory = stories[newBaseDate] {
            // Story for new date already exists
            let movedNote = note.copy(rootStoryID: existingStory.id)
            let updatedStory = existingStory.addNewNote(movedNote)
            stories[newBaseDate] = updatedStory
            if selectedStory?.id == existingStory.id {
                selectedStory = updatedStory
            }
            Task {
                await noteRepository.updateNote(movedNote)
            }
        } else {
            // Need to create new story for this date
            let newStory = Story(date: note.date)
            let movedNote = note.copy(rootStoryID: newStory.id)
            let updatedStory = newStory.addNewNote(movedNote)
            stories[newBaseDate] = updatedStory
            Task {
                await storyRepository.newStory(newStory)
                await noteRepository.updateNote(movedNote)
            }
        }
    }
    
    func updateNote(_ note: Note) {
        Task {
            await noteRepository.updateNote(note)
        }
    }
    
    //MARK: FRIENDS -
    func addNewFriend(_ friend: Friend) {
        Task {
            await friendsRepository.addNewFriend(friend)
            allFriends.append(friend)
        }
    }
    
    func editFriend(_ friend: Friend) {
        Task {
            if let user = friend.user {
                await userRepository.addNewUser(user)
            }
            await friendsRepository.editFriend(friend)
            allFriends.removeAll { $0.id == friend.id }
            allFriends.append(friend)
        }
    }
    
    func deleteFriend(_ friend: Friend) {
        Task {
            await friendsRepository.deleteFriend(friend)
            allFriends.removeAll { $0.id == friend.id }
        }
    }
}
