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
        if let index = allFriends.firstIndex(where: { $0.id == friend.id }) {
            allFriends[index] = friend
        } else {
            allFriends.append(friend)
        }
        allNotes = allNotes.map { $0.replacingFriend(friend) }

        Task {
            if let user = friend.user {
                await userRepository.addNewUser(user)
            }
            await friendsRepository.editFriend(friend)
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
        guard !isSyncing else { return }
        isSyncing = true
        Task {
            await cloudKitService.uploadAll()
            isSyncing = false
        }
    }
    
    func syncDownload() {
        guard !isSyncing else { return }
        isSyncing = true
        Task {
            await cloudKitService.downloadAll()
            loadData()
            isSyncing = false
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
            if case .error = cloudSyncState {
                isSyncing = false
                checkOnboardingNeeded()
                return
            }
            await MainActor.run {
                // Re-read user from UserDefaults (may have been restored from iCloud)
                user = userDefaultsManager.getCurrentUser()
                if !user.name.isEmpty, !user.color.isEmpty, appCoordinator.fullScreenCover == .onboarding {
                    appCoordinator.fullScreenCover = nil
                }
                loadData()
            }
            await cloudKitService.uploadAll()
            await MainActor.run {
                isSyncing = false
            }
            checkOnboardingNeeded()
        }
    }
    
    func restoreBackup(_ backup: DatabaseBackup, policy: BackupConflictPolicy?) async throws {
        guard !isSyncing else { throw BackupRestoreError.syncInProgress }
        isSyncing = true
        defer { isSyncing = false }
        try await BackupService.shared.restore(backup, policy: policy)
        loadData()
        await cloudKitService.uploadAll()
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
}
