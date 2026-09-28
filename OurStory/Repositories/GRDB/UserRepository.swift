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
                if try UserModelGRDB.filter(key: user.id).fetchCount(db) == 0 {
                    var model = UserModelGRDB(from: user)
                    try model.insert(db)
                    Logger.log("save new user", location: .GRDB, event: .success)
                } else {
                    Logger.log("error save new user, not unique", location: .GRDB, event: .error(nil))
                }
            }
        } catch {
            Logger.log("save new user", location: .GRDB, event: .error(error))
            fatalError()
        }
    }
    
//    func getUser(id: UUID) async -> User? {
//        do {
//            return try await dbPool.read { db in
//                if let model = try? UserModelGRDB.fetchOne(db, key: id) {
//                    let user = User(from: model)
//                    Logger.log("get user", location: .GRDB, event: .success)
//                    return user
//                } else {
//                    Logger.log("Failed to get user", location: .GRDB, event: .error(DatabaseError()))
//                    return nil
//                }
//            }
//        } catch {
//            fatalError()
//        }
//    }
}
