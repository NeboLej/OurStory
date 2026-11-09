//
//  SyncService2.swift
//  OurStory
//
//  Created by Nebo on 27.09.2026.
//

import Foundation
import MultipeerConnectivity

enum SyncProgressState: Hashable {
    case searching
    case connecting
    case exchangingUsers
    case friendNearby(User)
    case waitingForUserConfirmation(User)
    case exchangingNotes
    case completed
    case failed(Error)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .searching: hasher.combine(0)
        case .connecting: hasher.combine(1)
        case .exchangingUsers: hasher.combine(2)
        case .friendNearby: hasher.combine(7)
        case .waitingForUserConfirmation: hasher.combine(3)
        case .exchangingNotes: hasher.combine(4)
        case .completed: hasher.combine(5)
        case .failed: hasher.combine(6)
        }
    }
    
    var descriptionText: String {
        switch self {
        case .searching: L10n.syncSearching
        case .connecting: L10n.syncConnecting
        case .exchangingUsers: L10n.syncExchangingInfo
        case .friendNearby: L10n.syncFriendNearby
        case .waitingForUserConfirmation: L10n.syncWaitingApproval
        case .exchangingNotes: L10n.syncTellingStories
        case .completed: L10n.syncCompleted
        case .failed(let error): L10n.syncError(error.localizedDescription)
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.searching, .searching),
            (.connecting, .connecting),
            (.exchangingUsers, .exchangingUsers),
            (.friendNearby, .friendNearby),
            (.waitingForUserConfirmation, .waitingForUserConfirmation),
            (.exchangingNotes, .exchangingNotes),
            (.completed, .completed),
            (.failed, .failed):
            return true
            
        default:
            return false
        }
    }
}

// MARK: - Models

struct SyncNote: Codable {
    let id: UUID
    let text: String
    let title: String?
    let date: Date
    
    var baseDate: BaseDate {
        BaseDate(date: date)
    }
    
    init(id: UUID, text: String, title: String?, date: Date) {
        self.id = id
        self.text = text
        self.title = title
        self.date = date
    }
    
    init(from note: Note) {
        self.id = note.id
        self.text = note.text
        self.title = note.title
        self.date = note.date
    }
}

// MARK: - Protocol Messages

struct SyncMessage: Codable {
    
    enum Kind: String, Codable {
        case user, userApproval, notes
    }
    
    let kind: Kind
    let user: User?
    let approval: Bool?
    let notes: [SyncNote]?
    
    static func user(_ user: User) -> SyncMessage {
        SyncMessage(kind: .user, user: user, approval: nil, notes: nil)
    }
    
    static func userApproval(_ approved: Bool) -> SyncMessage {
        SyncMessage(kind: .userApproval, user: nil, approval: approved, notes: nil)
    }
    
    static func notes(_ notes: [SyncNote]) -> SyncMessage {
        SyncMessage(kind: .notes, user: nil, approval: nil, notes: notes)
    }
}

// MARK: - Errors

enum SyncError: LocalizedError {
    case notConnected
    case userRejected
    case cancelled
    case disconnected
    
    var errorDescription: String? {
        switch self {
        case .notConnected: L10n.syncErrorNotConnected
        case .userRejected: L10n.syncErrorUserRejected
        case .cancelled: L10n.syncErrorCancelled
        case .disconnected: L10n.syncErrorDisconnected
        }
    }
}

// MARK: - Result

struct SyncResult {
    let user: User
    let notes: [SyncNote]
}
