//
//  AppStore.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

@Observable
final class AppStore {
    
    var selectedDate: Date = .now
    var selectedStory: Story?
    var stories: [BaseDate: Story] = [:]
    var allFriends: [Friend] = []
    var user: User
    var sortedNotes: [Note] = []
    var isShowNoteFriendsList: Bool = false
    
    var appCoordinator: AppCoordinator = AppCoordinator()
    var cloudSyncState: CloudSyncState = .idle
    
    @ObservationIgnored
    let cloudKitService = CloudKitService.shared
    @ObservationIgnored
    let userRepository: UserRepositoryProtocol
    @ObservationIgnored
    let friendsRepository: FriendRepositoryProtocol
    @ObservationIgnored
    let noteRepository: NoteRepositoryProtocol
    @ObservationIgnored
    let storyRepository: StoryRepositoryProtocol
    @ObservationIgnored
    let userDefaultsManager: UserDefaultsManager = UserDefaultsManager()
    
    @ObservationIgnored
    var isSyncing = false
    
    init(repositoryFactory: RepositoryFactoryProtocol) {
        self.userRepository = repositoryFactory.userRepository
        self.friendsRepository = repositoryFactory.friendRepository
        self.noteRepository = repositoryFactory.noteRepository
        self.storyRepository = repositoryFactory.storyRepository
        
        user = userDefaultsManager.getCurrentUser()
        
        cloudKitService.onStateChange = { [weak self] state in
            self?.cloudSyncState = state
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadData()
        }
    }
    
    func send(_ action: AppAction) {
        switch action {
        case .selectedDate(let date):
            selectedDate = date
            selectedStory = self.stories[BaseDate(date: selectedDate)]
        case .addNewNote(let newNote):
            addNewNote(newNote)
        case .editNote(let note):
            let oldStoryEntry = stories.first(where: { $0.value.id == note.rootStoryID })
            let newBaseDate = BaseDate(date: note.date)
            let dateChanged = oldStoryEntry != nil && oldStoryEntry!.key != newBaseDate
            
            if dateChanged, let oldBaseDate = oldStoryEntry?.key, let oldStory = oldStoryEntry?.value {
                // Remove note from old story
                let updatedOldStory = oldStory.removeNote(note.id)
                stories[oldBaseDate] = updatedOldStory
                if selectedStory?.id == oldStory.id {
                    selectedStory = updatedOldStory
                }
                
                // Add note to new story (find existing or create)
                moveNoteToStory(note, newBaseDate: newBaseDate)
            } else if let oldBaseDate = oldStoryEntry?.key, let oldStory = oldStoryEntry?.value {
                // Same date — just replace in place
                let updatedStory = oldStory.replaceNote(note)
                stories[oldBaseDate] = updatedStory
                if selectedStory?.id == updatedStory.id {
                    selectedStory = updatedStory
                }
                updateNote(note)
            }
        case .syncNotes(let notes, let friend):
            syncNotes(notes, friend: friend)
        case .addNewFriend(let friend):
            addNewFriend(friend)
        case .editFriend(let friend):
            editFriend(friend)
        case .deleteFriend(let friend):
            deleteFriend(friend)
        case .editProfile(name: let name, color: let color):
            user = userDefaultsManager.editUser(name: name, color: color)
        }
    }
    
    func getSelectedStory() -> Story {
        let story = selectedStory ?? stories[BaseDate(date: selectedDate)] ?? Story(date: selectedDate)
        selectedStory = story
        return story
    }

    func send(_ action: NavigateAction) {
        switch action {
        case .toNote(let note):
            appCoordinator.navigate(to: .note(note))
        case .toFriendsList:
            appCoordinator.navigate(to: .friendList)
        case .toFriend(let friend):
            appCoordinator.navigate(to: .friend(friend))
        case .toNewFriend: 
            appCoordinator.navigate(to: .newFriend)
        case .toSettings:
            appCoordinator.navigate(to: .setting)
        case .toEditProfile:
            appCoordinator.navigate(to: .editProfile)
        case .toNotesList(title: let title, notes: let notes):
            appCoordinator.navigate(to: .notes(title: title, notes: notes, isShowFriendsList: Binding(get: { self.isShowNoteFriendsList }, set: { self.isShowNoteFriendsList = $0 })))
        case .toLogs:
            appCoordinator.navigate(to: .log)
        case .toCalendar:
            appCoordinator.navigate(to: .calendar)
        }
    }
    
    func loadData() {
        Task {
            allFriends = await friendsRepository.getAllFriends()
            
            let stories = await storyRepository.getStories(startDate: Date().getOffsetDate(-1, component: .month),
                                                           endDate: Date().getOffsetDate(1, component: .month))
            
            stories.forEach { story in
                self.stories[BaseDate(date: story.date)] = story
            }
            
            selectedStory = getSelectedStory()
        }
    }
}
