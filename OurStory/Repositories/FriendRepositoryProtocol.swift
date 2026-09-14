//
//  FriendRepositoryProtocol.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

protocol FriendRepositoryProtocol {
    func getAllFriends() async -> [Friend]
    func addNewFriend(_ friend: Friend) async
}
