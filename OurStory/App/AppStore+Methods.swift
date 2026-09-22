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
