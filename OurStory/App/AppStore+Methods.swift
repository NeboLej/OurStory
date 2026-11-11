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
        allNotes.append(note)
        Task {
            await noteRepository.addNote(note)
        }
    }
    
    func syncNotes(_ notes: [SyncNote], friend: Friend) {
        let notes = notes.sorted { $0.date < $1.date }
        var allNewNotes: [Note] = []
        
        Task {
            for note in notes {
                let newNote = Note(id: note.id, title: note.title, date: note.date, text: note.text, friends: [], owner: friend)
                allNewNotes.append(newNote)
                allNotes.append(newNote)
                await noteRepository.saveOrUpdateNote(newNote)
            }
            sortedNotes = allNewNotes
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await CloudKitService.shared.uploadAll()
        }
    }
    
    func markNotesSynced(noteIDs: [UUID], friendID: UUID) {
        let ids = Set(noteIDs)
        allNotes = allNotes.map { ids.contains($0.id) ? $0.markedSynced(with: friendID) : $0 }
    }
    
    func updateNote(_ note: Note) {
        Task {
            await noteRepository.updateNote(note)
        }
    }
    
    func deleteNote(_ note: Note) {
        allNotes.removeAll { $0.id == note.id }
        Task {
            await noteRepository.deleteNote(note.id)
        }
    }
    
    //MARK: FRIENDS -
    func addNewFriend(_ friend: Friend) {
        Task {
            if let user = friend.user {
                await userRepository.addNewUser(user)
            }
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
    
    func deleteFriendWithNotes(_ friend: Friend) {
        Task {
            await noteRepository.deleteNotesOwnedByFriend(friendID: friend.id)
            await friendsRepository.deleteFriend(friend)
            allFriends.removeAll { $0.id == friend.id }
            loadData()
        }
    }
    
    func hideFriend(_ friend: Friend) {
        Task {
            await noteRepository.removeNoteFriendLinks(friendID: friend.id)
            await friendsRepository.hideFriend(friend)
            allFriends.removeAll { $0.id == friend.id }
            loadData()
        }
    }
    
    // MARK: - Cloud Sync
    
    func syncUpload() {
        Task {
            await cloudKitService.uploadAll()
        }
    }
    
    func syncDownload() {
        Task {
            await cloudKitService.downloadAll()
            await MainActor.run {
                loadData()
            }
        }
    }
    
    func syncDownloadAndUpload(force: Bool = false) {
        guard !isSyncing else { return }
        if !force, let last = lastSyncDate, Date().timeIntervalSince(last) < syncCooldown {
            return
        }
        isSyncing = true
        lastSyncDate = Date()
        Task {
            await cloudKitService.downloadAll()
            await MainActor.run {
                // Re-read user from UserDefaults (may have been restored from iCloud)
                user = userDefaultsManager.getCurrentUser()
                loadData()
            }
            await cloudKitService.uploadAll()
            await MainActor.run {
                isSyncing = false
            }
            checkOnboardingNeeded()
        }
    }
    
    func checkOnboardingNeeded() {
        if user.name.isEmpty || user.color.isEmpty {
            appCoordinator.fullScreenCover = .onboarding
        }
    }
    
    // MARK: - Welcome Message
    
    func createWelcomeMessageIfNeeded() {
        guard !userDefaultsManager.isShowSupportEvent(.welcomeMessage) else { return }
        
        userDefaultsManager.setShowSupportEvent(.welcomeMessage)
        
        Task {
            let ourStoryFriend = Friend.ourStory
            
            let exists = await friendsRepository.friendExists(id: ourStoryFriend.id)
            if !exists {
                await friendsRepository.addNewFriend(ourStoryFriend)
            }
            
            let welcomeNote = Note(
                title: L10n.welcomeTitle,
                date: .now,
                text: L10n.welcomeText(user.name),
                friends: [],
                owner: ourStoryFriend
            )
            await noteRepository.addNote(welcomeNote)
            allNotes.append(welcomeNote)
        }
    }
    
    // MARK: - Search
    
    func searchNotes(query: String) -> [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        let tokens = trimmed
            .lowercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        return allNotes
            .compactMap { note -> (Note, Double)? in
                let score = searchScore(note: note, tokens: tokens)
                return score > 0 ? (note, score) : nil
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }
    
    private func searchScore(note: Note, tokens: [String]) -> Double {
        var totalScore: Double = 0
        
        let titleLower = note.title?.lowercased() ?? ""
        let textLower = note.text.lowercased()
        let friendNames = note.friends.map { $0.name.lowercased() }
        let ownerName = note.owner?.name.lowercased()
        
        for token in tokens {
            var tokenScore: Double = 0
            
            // Title — highest priority
            if titleLower.contains(token) {
                tokenScore = max(tokenScore, 3.0)
            } else if !titleLower.isEmpty, titleLower.commonPrefix(with: token).count >= min(3, token.count) {
                tokenScore = max(tokenScore, 2.0)
            }
            
            // Text body
            if textLower.contains(token) {
                tokenScore = max(tokenScore, 1.5)
            }
            
            // Friend names — fuzzy prefix match
            for name in friendNames {
                if name.contains(token) {
                    tokenScore = max(tokenScore, 2.0)
                } else if token.fuzzyMatchesName(name) {
                    tokenScore = max(tokenScore, 1.5)
                }
            }
            
            // Owner name
            if let ownerName {
                if ownerName.contains(token) {
                    tokenScore = max(tokenScore, 2.0)
                } else if token.fuzzyMatchesName(ownerName) {
                    tokenScore = max(tokenScore, 1.5)
                }
            }
            
            guard tokenScore > 0 else { return 0 }
            totalScore += tokenScore
        }
        
        return totalScore
    }
}
