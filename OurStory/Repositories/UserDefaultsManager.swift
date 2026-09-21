//
//  UserDefaultsManager.swift
//  OurStory
//
//  Created by Nebo on 22.09.2026.
//

import Foundation

class UserDefaultsManager {
    
    let db = UserDefaults.standard
    
    enum UserDefaultsKeys: String, Codable {
        case userID
        case userName
        case userColor
    }
    
    func getCurrentUser() -> User {
        let id = db.string(forKey: UserDefaultsKeys.userID.rawValue)
        let userName = db.string(forKey: UserDefaultsKeys.userName.rawValue)
        let userColor = db.string(forKey: UserDefaultsKeys.userColor.rawValue)
        
        if let id, let uuid = UUID(uuidString: id) {
            let user = User(id: uuid, name: userName ?? "", color: userColor ?? "")
            return user
        } else {
            return createNewUser()
        }
    }
    
    func editUser(name: String, color: String) -> User {
        var currentUser = getCurrentUser()
        currentUser.name = name
        currentUser.color = color
        
        db.set(currentUser.name, forKey: UserDefaultsKeys.userName.rawValue)
        db.set(currentUser.color, forKey: UserDefaultsKeys.userColor.rawValue)
        
        return currentUser
    }
    
    private func createNewUser() -> User {
        let user = User(name: "", color: "")
        db.set(user.id.uuidString, forKey: UserDefaultsKeys.userID.rawValue)
        db.set(user.name, forKey: UserDefaultsKeys.userName.rawValue)
        db.set(user.color, forKey: UserDefaultsKeys.userColor.rawValue)
        return user
    }
}
