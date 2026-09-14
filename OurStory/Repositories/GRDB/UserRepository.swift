//
//  UserRepository.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

final class UserRepository: BaseRepository, UserRepositoryProtocol {
    
    func getAllUsers() async -> [User] {
        do {
            return try await dbPool.read { db in
                let users = try UserModelGRDB.fetchAll(db).map { User(from: $0) }
                Logger.log("get \(users.count) user", location: .GRDB, event: .success)
                return users
            }
        } catch {
            Logger.log("Failed to get all user", location: .GRDB, event: .error(error))
            return []
        }
    }
    
    func addNewUser(_ user: User) async {
        do {
            try await dbPool.write { db in
                var model = UserModelGRDB(from: user)
                try model.insert(db)
                Logger.log("save new user", location: .GRDB, event: .success)
            }
        } catch {
            Logger.log("save new user", location: .GRDB, event: .error(error))
            fatalError()
        }
    }
}
