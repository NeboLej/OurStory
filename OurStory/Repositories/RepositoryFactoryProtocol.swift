//
//  RepositoryFactoryProtocol.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

protocol RepositoryFactoryProtocol {
    var userRepository: UserRepositoryProtocol { get }
    var friendRepository: FriendRepositoryProtocol { get }
    var noteRepository: NoteRepositoryProtocol { get }
    
}

class RepositoryFactory: RepositoryFactoryProtocol {
    let userRepository: UserRepositoryProtocol
    let friendRepository: FriendRepositoryProtocol
    let noteRepository: NoteRepositoryProtocol
    
    init() {
        let dbPool: DatabasePool = DatabaseManager.shared.dbPool
        
        self.userRepository = UserRepository(dbPool: dbPool)
        self.friendRepository = FriendRepository(dbPool: dbPool)
        self.noteRepository = NoteRepository(dbPool: dbPool)
    }
}


//try await dbPool.read { db in
//    let seeds = try SeedModelGRDB.fetchAll(db).map { Seed(from: $0) }
//    Logger.log("get \(seeds.count) Seeds", location: .GRDB, event: .success)
//    return seeds
//}
