//
//  UserDefaultsManager.swift
//  OurStory
//
//  Created by Nebo on 22.09.2026.
//

import Foundation

enum SupportEvent: String {
    case exchangeStory
    case welcomeMessage
    case addFriend
}

class UserDefaultsManager {
    
    let db = UserDefaults.standard
    
    enum UserDefaultsKeys: String, Codable {
        case userID
        case userName
        case userColor
        case noteDraft
        case notificationsEnabled
        case dailyReminderEnabled
        case dailyReminderHour
        case dailyReminderMinute
        case notificationPromptShown
        case cloudProfileChecked
    }
    
    func getCurrentUser() -> User {
        let id = db.string(forKey: UserDefaultsKeys.userID.rawValue)
        let userName = db.string(forKey: UserDefaultsKeys.userName.rawValue)
        let userColor = db.string(forKey: UserDefaultsKeys.userColor.rawValue)
        
        if let id, let uuid = UUID(uuidString: id) {
            let user = User(id: uuid, name: userName ?? "", color: userColor ?? "")
            Logger.log("Get user", location: .userDefault, event: .success)
            return user
        } else {
            return createNewUser()
        }
    }
    
    func isShowSupportEvent(_ event: SupportEvent) -> Bool {
        let ff = db.bool(forKey: event.rawValue)
        return ff
    }
    
    func setShowSupportEvent(_ event: SupportEvent) {
        db.set(true, forKey: event.rawValue)
    }
    
    func editUser(name: String, color: String) -> User {
        var currentUser = getCurrentUser()
        currentUser.name = name
        currentUser.color = color
        
        db.set(currentUser.name, forKey: UserDefaultsKeys.userName.rawValue)
        db.set(currentUser.color, forKey: UserDefaultsKeys.userColor.rawValue)
        
        Logger.log("Edit user", location: .userDefault, event: .success)
        
        Task {
            try await CloudKitService.shared.uploadProfile()
        }
        
        return currentUser
    }
    
    func restoreUser(id: UUID, name: String, color: String) -> User {
        db.set(id.uuidString, forKey: UserDefaultsKeys.userID.rawValue)
        db.set(name, forKey: UserDefaultsKeys.userName.rawValue)
        db.set(color, forKey: UserDefaultsKeys.userColor.rawValue)
        Logger.log("Edit user (restore)", location: .userDefault, event: .success)
        
        return User(id: id, name: name, color: color)
    }
    
    /// Cleared on reinstall. Until a successful cloud download has checked for an existing profile,
    /// the local profile must not be uploaded, or it would shadow the one being restored.
    var isCloudProfileChecked: Bool {
        get { db.bool(forKey: UserDefaultsKeys.cloudProfileChecked.rawValue) }
        set { db.set(newValue, forKey: UserDefaultsKeys.cloudProfileChecked.rawValue) }
    }
    
    // MARK: - Note Draft
    
    struct NoteDraft: Codable {
        let title: String?
        let text: String
        let date: Date
        let friendIDs: [UUID]
        
        var isEmpty: Bool {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedText.isEmpty && (trimmedTitle ?? "").isEmpty && friendIDs.isEmpty
        }
    }
    
    func saveNoteDraft(_ draft: NoteDraft) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        db.set(data, forKey: UserDefaultsKeys.noteDraft.rawValue)
        Logger.log("Draft saved: \(draft.text.prefix(30))...", location: .userDefault, event: .success)
    }
    
    func loadNoteDraft() -> NoteDraft? {
        guard let data = db.data(forKey: UserDefaultsKeys.noteDraft.rawValue) else { return nil }
        let draft = try? JSONDecoder().decode(NoteDraft.self, from: data)
        Logger.log("Draft load: \(draft != nil ? "found" : "empty")", location: .userDefault, event: draft != nil ? .success : .error())
        return draft
    }
    
    func clearNoteDraft() {
        db.removeObject(forKey: UserDefaultsKeys.noteDraft.rawValue)
        Logger.log("Draft cleared", location: .userDefault, event: .success)
    }
    
    // MARK: - Notifications
    
    var isNotificationsEnabled: Bool {
        get { db.bool(forKey: UserDefaultsKeys.notificationsEnabled.rawValue) }
        set { db.set(newValue, forKey: UserDefaultsKeys.notificationsEnabled.rawValue) }
    }
    
    var isDailyReminderEnabled: Bool {
        get { db.bool(forKey: UserDefaultsKeys.dailyReminderEnabled.rawValue) }
        set { db.set(newValue, forKey: UserDefaultsKeys.dailyReminderEnabled.rawValue) }
    }
    
    var dailyReminderHour: Int {
        get {
            let val = db.integer(forKey: UserDefaultsKeys.dailyReminderHour.rawValue)
            return val == 0 && !db.bool(forKey: "dailyReminderHourSet") ? 21 : val
        }
        set {
            db.set(newValue, forKey: UserDefaultsKeys.dailyReminderHour.rawValue)
            db.set(true, forKey: "dailyReminderHourSet")
        }
    }
    
    var dailyReminderMinute: Int {
        get { db.integer(forKey: UserDefaultsKeys.dailyReminderMinute.rawValue) }
        set { db.set(newValue, forKey: UserDefaultsKeys.dailyReminderMinute.rawValue) }
    }
    
    var isNotificationPromptShown: Bool {
        get { db.bool(forKey: UserDefaultsKeys.notificationPromptShown.rawValue) }
        set { db.set(newValue, forKey: UserDefaultsKeys.notificationPromptShown.rawValue) }
    }
    
    private func createNewUser() -> User {
        let user = User(name: "", color: "")
        db.set(user.id.uuidString, forKey: UserDefaultsKeys.userID.rawValue)
        db.set(user.name, forKey: UserDefaultsKeys.userName.rawValue)
        db.set(user.color, forKey: UserDefaultsKeys.userColor.rawValue)
        Logger.log("Create new user", location: .userDefault, event: .success)
        return user
    }
}
