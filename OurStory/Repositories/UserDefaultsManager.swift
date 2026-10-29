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
}

class UserDefaultsManager {
    
    let db = UserDefaults.standard
    
    enum UserDefaultsKeys: String, Codable {
        case userID
        case userName
        case userColor
        case noteDraft
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
        db.bool(forKey: event.rawValue)
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
    
    private func createNewUser() -> User {
        let user = User(name: "", color: "")
        db.set(user.id.uuidString, forKey: UserDefaultsKeys.userID.rawValue)
        db.set(user.name, forKey: UserDefaultsKeys.userName.rawValue)
        db.set(user.color, forKey: UserDefaultsKeys.userColor.rawValue)
        Logger.log("Create new user", location: .userDefault, event: .success)
        return user
    }
}
