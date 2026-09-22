//
//  SyncService.swift
//  OurStory
//
//  Created by Nebo on 22.09.2026.
//

import Foundation
import MultipeerConnectivity


enum SyncEvent {
    case searching
    case connecting
    case exchangingUsers
    case waitingForUserConfirmation(User)
    case exchangingNotes
    case completed
    case failed(Error)
}

struct SyncNote: Codable {
    let id: UUID
    let text: String
    let title: String?
    let date: Date
    
    var baseDate: BaseDate { BaseDate(date: date) }
    
    init(from: Note) {
        self.id = from.id
        self.text = from.text
        self.title = from.title
        self.date = from.date
    }
}

struct SyncMessage: Codable {
    
    enum Kind: String, Codable {
        case user
        case userApproval
        case notes
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

enum SyncError: Error {
    case notConnected
    case userRejected
}

struct SyncResult {
    let user: User
    let notes: [SyncNote]
}

class SyncService {
    
    private var profile: User
    
    init(profile: User) {
        self.profile = profile
    }
    
    var manager: PeerExchangeManager?
    
    func syncFriend(friend: Friend, notes: [Note]) async throws -> SyncResult {
        
        let manager = PeerExchangeManager(localFriend: friend, myProfile: profile)
        
        manager.onEvent = { event in
            switch event {
            case .searching: print("Ищем устройство...")
            case .connecting: print("Подключение...")
            case .exchangingUsers: print("Обмениваемся профилями...")
            case .waitingForUserConfirmation(let user):
                print("показать Alert")
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    manager.confirmUser(true)
                }
            case .exchangingNotes: print("Синхронизируем заметки...")
            case .completed: print("Готово")
            case .failed: print("показать ошибку")
            }
        }
        
        return try await manager.sync(notes: notes)
    }
}

final class PeerExchangeManager: NSObject {
    
    private let peerID: MCPeerID
    private let session: MCSession
    
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    
    //    private var continuation: CheckedContinuation<User, Error>?
    
    private let serviceType = "user-exchange"
    
    var onEvent: ((SyncEvent) -> Void)?
    
    private var myProfile: User
    private var myNotes: [SyncNote] = []
    private var localFriend: Friend
    
    private var continuation: CheckedContinuation<SyncResult, Error>?
    
    private var receivedUser: User?
    private var receivedNotes: [SyncNote] = []
    
    init(localFriend: Friend, myProfile: User) {
        self.localFriend = localFriend
        self.myProfile = myProfile
        self.peerID = MCPeerID(displayName: localFriend.id.uuidString)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }
    
    private var userApprovalContinuation: CheckedContinuation<Bool, Never>?
    
    
    func sync(notes: [Note]) async throws -> SyncResult {
        myNotes = notes.map { SyncNote(from: $0) }
        
        onEvent?(.searching)
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            advertiser.startAdvertisingPeer()
            browser.startBrowsingForPeers()
        }
    }
    
    //публичный подтверждаем юзера с ui
    func confirmUser(_ approved: Bool) {
        guard let peer = session.connectedPeers.first else {
            return
        }
        
        let message = SyncMessage.userApproval(approved)
        
        do {
            let data = try JSONEncoder().encode(message)
            
            try session.send(data,toPeers: [peer], with: .reliable)
        } catch {
            print("Failed to send confirmation:", error)
        }
    }
    
    private func sendNotes() {
        guard let peer = session.connectedPeers.first else {
            return
        }
        
        let message = SyncMessage.notes(myNotes)
        
        do {
            let data = try JSONEncoder().encode(message)
            
            try session.send(data, toPeers: [peer], with: .reliable)
            
            onEvent?(.exchangingNotes)
            
        } catch {
            print("Failed to send notes:", error)
        }
    }
    
    private func finishSync() {
        guard let user = receivedUser else {
            return
        }
        
        guard let continuation else {
            return
        }
        
        self.continuation = nil
        
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        
        onEvent?(.completed)
        
        continuation.resume(
            returning: SyncResult(
                user: user,
                notes: receivedNotes
            )
        )
    }
    
    private func finishSyncWithError(_ error: Error) {
        guard let continuation else {
            return
        }
        
        self.continuation = nil
        
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        
        continuation.resume(throwing: error)
    }
    
    //    func sync() async throws -> User {
    //
    //        try await withCheckedThrowingContinuation { continuation in
    //            self.continuation = continuation
    //            advertiser.startAdvertisingPeer()
    //            browser.startBrowsingForPeers()
    //        }
    //    }
}

extension PeerExchangeManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        // В прототипе автоматически принимаем соединение.
        invitationHandler(true, session)
    }
}

extension PeerExchangeManager: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer:", peerID.displayName)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer:", peerID.displayName)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        //        finish(error: error)
    }
}

extension PeerExchangeManager: MCSessionDelegate {
    
    //отправка данных
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        guard state == .connected else {
            return
        }
        
        onEvent?(.exchangingUsers)
        
        do {
            let message = SyncMessage.user(myProfile)
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: [peerID], with: .reliable)
        } catch {
            print("Failed to send User:", error)
        }
    }
    
    //получение данных
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(SyncMessage.self, from: data)
            
            switch message.kind {
            case .user:
                guard let user = message.user else { return }
                
                receivedUser = user
                
                if user.id == localFriend.user?.id {
                    sendNotes()
                } else {
                    onEvent?(.waitingForUserConfirmation(user))
                }
            case .userApproval:
                guard let approved = message.approval else { return }
                
                print("Получено подтверждение:", approved)
                
                if approved {
                    sendNotes()
                } else {
                    finishSyncWithError(NSError(domain: "PeerExchange", code: 1, userInfo: [NSLocalizedDescriptionKey: "Пользователь отклонил обмен."]))
                }
                
            case .notes:
                guard let notes = message.notes else { return }
                
                receivedNotes = notes
                onEvent?(.exchangingNotes)
                finishSync()
            }
            
        } catch {
            print("Failed to decode SyncMessage:", error)
        }
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
}


//private extension PeerExchangeManager2 {
//
//    func finish(user: User) {
//
//        cleanup()
//
//        continuation?.resume(returning: user)
//        continuation = nil
//    }
//
//    func finish(error: Error) {
//
//        cleanup()
//
//        continuation?.resume(throwing: error)
//        continuation = nil
//    }
//
//    func cleanup() {
//
//        advertiser.stopAdvertisingPeer()
//        browser.stopBrowsingForPeers()
//
//        session.disconnect()
//    }
//}
