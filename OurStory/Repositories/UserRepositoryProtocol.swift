//
//  UserRepositoryProtocol.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

protocol UserRepositoryProtocol {
    func getAllUsers() async -> [User]
    func addNewUser(_ user: User) async
}
