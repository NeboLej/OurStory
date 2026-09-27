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
    case waitingForUserConfirmation(User)
    case exchangingNotes
    case completed
    case failed(Error)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .searching: hasher.combine(0)
        case .connecting: hasher.combine(1)
        case .exchangingUsers: hasher.combine(2)
        case .waitingForUserConfirmation: hasher.combine(3)
        case .exchangingNotes: hasher.combine(4)
        case .completed: hasher.combine(5)
        case .failed: hasher.combine(6)
        }
    }
    
    var descriptionText: String {
        switch self {
        case .searching: "Ищу других пользователей рядом..."
        case .connecting: "Соединяю пользователей..."
        case .exchangingUsers: "Обмениваю информацию..."
        case .waitingForUserConfirmation: "Получение разрешения на обмен историями..."
        case .exchangingNotes: "Рассказываю истории..."
        case .completed: "Обмен историями завершен!"
        case .failed(let error): "Ошибка обмена: \(error.localizedDescription)"
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.searching, .searching),
            (.connecting, .connecting),
            (.exchangingUsers, .exchangingUsers),
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
        case .notConnected: "Нет подключения к пользователю."
        case .userRejected: "Пользователь отклонил обмен."
        case .cancelled: "Обмен отменен."
        case .disconnected: "Соединение с пользователем потеряно."
        }
    }
}

// MARK: - Result

struct SyncResult {
    let user: User
    let notes: [SyncNote]
}

// MARK: - SyncService

final class SyncService {
    
    private var profile: User
    
    /// Важно: manager должен храниться здесь.
    /// Иначе после выхода из syncFriend менеджер может быть
    /// освобожден, а confirmUser() не сможет до него достучаться.
    private var manager: PeerExchangeManager?
    
    var onEvent: ((SyncProgressState) -> Void)?
    
    init(profile: User) {
        self.profile = profile
    }
    
    func syncFriend(friend: Friend, notes: [Note]) async throws -> SyncResult {
        manager?.cancel()
        manager = nil
        
        let manager = PeerExchangeManager(localFriend: friend, myProfile: profile)
        
        self.manager = manager
        
        manager.onEvent = { [weak self] event in
            self?.onEvent?(event)
        }
        
        do {
            let result = try await manager.sync(notes: notes)
            if self.manager === manager {
                self.manager = nil
            }
            
            return result
            
        } catch {
            manager.cancel()
            
            if self.manager === manager {
                self.manager = nil
            }
            
            throw error
        }
    }
    
    func cancelSync() {
        manager?.cancel()
        manager = nil
    }

    func confirmUser(_ approved: Bool) {
        manager?.confirmUser(approved)
    }
}

// MARK: - PeerExchangeManager

final class PeerExchangeManager: NSObject {
    
    // MARK: Multipeer
    
    private let peerID: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    
    private let serviceType = "user-exchange"
    
    // MARK: Data
    
    private let myProfile: User
    private let localFriend: Friend
    
    private var myNotes: [SyncNote] = []
    
    private var receivedUser: User?
    private var receivedNotes: [SyncNote] = []
    
    // MARK: Continuations
    
    private var continuation: CheckedContinuation<SyncResult, Error>?
    
    // MARK: Handshake state
    
    /// Мы отправили свое подтверждение.
    private var localApprovalSent = false
    
    /// Мы получили подтверждение второй стороны.
    private var remoteApprovalReceived = false
    
    /// Notes уже были отправлены.
    private var notesSent = false
    
    /// Активна ли текущая сессия.
    private var isActive = false
    
    // MARK: Event
    
    var onEvent: ((SyncProgressState) -> Void)?
    
    // MARK: Init
    
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
    
    deinit {
        stopNetworking()
    }
    
    // MARK: Sync
    
    func sync(notes: [Note]) async throws -> SyncResult {
        myNotes = notes.map { SyncNote(from: $0)  }
        
        receivedUser = nil
        receivedNotes = []
        
        localApprovalSent = false
        remoteApprovalReceived = false
        notesSent = false
        
        isActive = true
        
        onEvent?(.searching)
        
        return try await withTaskCancellationHandler {
            
            try await withCheckedThrowingContinuation { continuation in
                
                guard self.isActive else {
                    continuation.resume(throwing: SyncError.cancelled)
                    return
                }
                
                self.continuation = continuation
                self.advertiser.startAdvertisingPeer()
                self.browser.startBrowsingForPeers()
            }
        } onCancel: {
            self.cancel()
        }
    }
    
    func cancel() {
        guard isActive || continuation != nil else {
            stopNetworking()
            return
        }
        
        isActive = false
        stopNetworking()
        
        if let continuation {
            self.continuation = nil
            continuation.resume(throwing: SyncError.cancelled)
        }
    }
    
    private func stopNetworking() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }
    
    func confirmUser(_ approved: Bool) {
        guard isActive else { return }
        guard !localApprovalSent else { return }
        guard let peer = session.connectedPeers.first else { return }
        
        sendUserApproval(approved, to: peer)
    }
    
    private func sendUserApproval( _ approved: Bool, to peer: MCPeerID) {
        
        guard isActive else { return }
        let message = SyncMessage.userApproval(approved)
        
        do {
            let data = try JSONEncoder().encode(message)
            
            try session.send(data, toPeers: [peer], with: .reliable)
            
            localApprovalSent = true
            
            if !approved {
                finishSyncWithError(SyncError.userRejected)
                return
            }
            trySendNotesIfReady()
            
        } catch {
            finishSyncWithError(error)
        }
    }
    
    private func trySendNotesIfReady() {
        guard isActive else { return }
        guard !notesSent else { return }
        guard localApprovalSent else { return }
        guard remoteApprovalReceived else { return }
        
        guard let peer = session.connectedPeers.first else {
            finishSyncWithError(SyncError.notConnected)
            return
        }
        
        sendNotes(to: peer)
    }
    
    private func sendUser(to peer: MCPeerID) {
        guard isActive else { return }
        
        let message = SyncMessage.user(myProfile)
        
        do {
            let data = try JSONEncoder().encode(message)
            
            try session.send(data, toPeers: [peer], with: .reliable)
            
        } catch {
            finishSyncWithError(error)
        }
    }
    
    private func sendNotes(to peer: MCPeerID) {
        guard isActive else { return }
        guard !notesSent else { return }
        
        let message = SyncMessage.notes(myNotes)
        
        do {
            let data = try JSONEncoder().encode(message)
            
            try session.send(data, toPeers: [peer], with: .reliable)
            notesSent = true
            onEvent?(.exchangingNotes)
        } catch {
            finishSyncWithError(error)
        }
    }
    
    // MARK: Finish
    
    private func finishSync() {
        guard isActive else { return }
        guard let user = receivedUser else { return }
        guard let continuation else { return }
        
        isActive = false
        self.continuation = nil
        
        stopNetworking()
        onEvent?(.completed)
        continuation.resume(returning: SyncResult(user: user, notes: receivedNotes))
    }
    
    private func finishSyncWithError(_ error: Error) {
        guard isActive else { return }
        
        isActive = false
        stopNetworking()
        
        guard let continuation else { return }
        
        self.continuation = nil
        
        onEvent?(.failed(error))
        continuation.resume(throwing: error)
    }
    
    private func handle(message: SyncMessage, fromPeer peerID: MCPeerID) {
        guard isActive else { return }
        
        switch message.kind {
        case .user:
            guard let user = message.user else { return }
            
            receivedUser = user
            onEvent?(.exchangingUsers)
            
            if user.id == localFriend.user?.id {
                sendUserApproval(true, to: peerID)
            } else {
                onEvent?(.waitingForUserConfirmation(user))
            }
        case .userApproval:
            guard let approved = message.approval else { return }
            
            if !approved {
                finishSyncWithError(SyncError.userRejected)
                return
            }
            
            // Вторая сторона согласилась.
            remoteApprovalReceived = true
            
            // Но notes будут отправлены только если
            // наше собственное approval тоже уже отправлено.
            trySendNotesIfReady()
            
        case .notes:
            guard localApprovalSent else { return }
            guard remoteApprovalReceived else { return }
            guard let notes = message.notes else { return }
            
            receivedNotes = notes
            onEvent?(.exchangingNotes)
            finishSync()
        }
    }
}

// MARK: - Advertiser Delegate

extension PeerExchangeManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard isActive else {
            invitationHandler(false, nil)
            return
        }
        
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        finishSyncWithError(error)
    }
}

// MARK: - Browser Delegate

extension PeerExchangeManager: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard isActive else { return }
        guard peerID != self.peerID else { return }
        guard session.connectedPeers.isEmpty else { return }
        
        onEvent?(.connecting)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) { }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        finishSyncWithError(error)
    }
}

// MARK: - MCSession Delegate

extension PeerExchangeManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        guard isActive else { return }
        
        switch state {
        case .connecting: onEvent?(.connecting)
        case .connected:
            onEvent?(.exchangingUsers)
            sendUser(to: peerID)
        case .notConnected:
            finishSyncWithError(SyncError.disconnected)
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard isActive else { return }
        
        do {
            let message = try JSONDecoder().decode(SyncMessage.self, from: data)
            handle(message: message, fromPeer: peerID)
        } catch {
            print("Failed to decode SyncMessage:", error)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    func session( _ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
}
