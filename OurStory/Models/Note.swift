//
//  Note.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

struct Note: Identifiable, Equatable, Hashable {
      
    let id: UUID
    let title: String?
    let date: Date
    let text: String
    let friends: [Friend]
    let owner: Friend?
    let syncedFriendIDs: Set<UUID>
    
    var baseDate: BaseDate { BaseDate(date: date) }
    
    init(id: UUID = UUID(), title: String? = nil, date: Date, text: String, friends: [Friend], owner: Friend? = nil, syncedFriendIDs: Set<UUID> = []) {
        self.id = id
        self.title = title
        self.date = date
        self.text = text
        self.friends = friends
        self.owner = owner
        self.syncedFriendIDs = syncedFriendIDs
    }
    
    init(from: NoteWithFriends, syncedFriendIDs: Set<UUID> = []) {
        self.id = from.note.id
        self.title = from.note.title
        self.date = from.note.date
        self.text = from.note.text
        self.friends = from.friends.map { Friend(from: $0) }
        if let owner = from.note.owner {
            self.owner = Friend(from: owner)
        } else {
            self.owner = nil
        }
        self.syncedFriendIDs = syncedFriendIDs
    }
    
    var isSyncedWithAllFriends: Bool {
        !friends.isEmpty && friends.allSatisfy(isSynced(with:))
    }
    
    func isSynced(with friend: Friend) -> Bool {
        syncedFriendIDs.contains(friend.id)
    }
    
    func markedSynced(with friendID: UUID) -> Self {
        Note(id: id, title: title, date: date, text: text, friends: friends, owner: owner, syncedFriendIDs: syncedFriendIDs.union([friendID]))
    }
    
    /// Any edit recreates noteFriend links with `isSent = false`, so sync status is reset.
    func copy(title: String? = nil, date: Date? = nil, text: String? = nil, friends: [Friend]? = nil) -> Self {
        Note(id: self.id, title: title ?? self.title, date: date ?? self.date, text: text ?? self.text, friends: friends ?? self.friends, owner: self.owner)
    }
    
    static let tmpNotes = [
        Note(id: UUID(), title: "ndfsfd", date: Date(), text: "выоатл ыывот аоыва ываи оываорыв ивыл оатыв иаоывр авдыла ытва ", friends: [], owner: Friend(name: "Вася", color: "44fd21")),
        
        Note(id: UUID(), title: "Заголовок присутствует", date: Date().getOffsetDate(-3), text: "выоатл ыывот аоыва ываи оываорыв ивыл оатыв иаоывр авдыла ытва ", friends: [Friend(name: "Вася", color: "44fd21")], owner: nil),
        
        Note(id: UUID(), title: nil, date: Date().getOffsetDate(-5), text: "выоатл ыывот аоыва ываи оываорыв ивыл оатыв иаоывр авдыла ытва ", friends: [], owner: nil)
    ]
}
