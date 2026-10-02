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
        case .searching: "Ищу других пользователей рядом..."
        case .connecting: "Соединяю пользователей..."
        case .exchangingUsers: "Обмениваю информацию..."
        case .friendNearby: "Друг рядом и готов слушать"
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
    
    /// Запускает поиск друга: подключается и обменивается user-ами.
    /// Когда user совпадает с friend.user — onEvent получит .friendNearby.
    /// Notes не отправляются до вызова confirmUser(true).
    func startDiscovery(friend: Friend, notes: [Note]) {
        manager?.cancel()
        manager = nil
        
        let manager = PeerExchangeManager(localFriend: friend, myProfile: profile)
        self.manager = manager
        
        manager.onEvent = { [weak self] event in
            self?.onEvent?(event)
        }
        
        // Запускаем sync без await — результат получим через onEvent / onSyncCompleted
        // .failed и .completed уже отправляются из PeerExchangeManager через onEvent
        Task { [weak self] in
            do {
                let result = try await manager.sync(notes: notes)
                await MainActor.run {
                    self?.onSyncCompleted?(result)
                }
            } catch {
                // Ошибка уже сообщена через onEvent(.failed) из PeerExchangeManager
            }
        }
    }
    
    /// Колбэк при успешном завершении sync (после exchange notes)
    var onSyncCompleted: ((SyncResult) -> Void)?
    
    func cancelSync() {
        manager?.cancel()
        manager = nil
    }

    /// Возвращает true если manager активен и approval отправлен
    @discardableResult
    func confirmUser(_ approved: Bool) -> Bool {
        guard let manager, manager.isActive else { return false }
        manager.confirmUser(approved)
        return true
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
    private(set) var isActive = false
    
    // MARK: Event
    
    var onEvent: ((SyncProgressState) -> Void)?
    
    // MARK: Init
    
    init(localFriend: Friend, myProfile: User) {
        self.localFriend = localFriend
        self.myProfile = myProfile
        
        // Используем myProfile.id — уникальный для каждого устройства.
        // localFriend.id одинаков на обоих сторонах и вызывает конфликт MCPeerID.
        self.peerID = MCPeerID(displayName: myProfile.id.uuidString)
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
        
        Logger.log("PeerExchange: sync started, notes count: \(myNotes.count), friendID: \(localFriend.id)", event: .unowned)
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
        Logger.log("PeerExchange: confirmUser(\(approved)), isActive: \(isActive), localApprovalSent: \(localApprovalSent), connectedPeers: \(session.connectedPeers.count)", event: .unowned)
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
        Logger.log("PeerExchange: trySendNotesIfReady - isActive: \(isActive), notesSent: \(notesSent), localApprovalSent: \(localApprovalSent), remoteApprovalReceived: \(remoteApprovalReceived)", event: .unowned)
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
            Logger.log("PeerExchange: sent user profile \(myProfile.name) to \(peer.displayName)", event: .success)
        } catch {
            Logger.log("PeerExchange: failed to send user", event: .error(error))
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
            Logger.log("PeerExchange: sent \(myNotes.count) notes to \(peer.displayName)", event: .success)
            onEvent?(.exchangingNotes)
        } catch {
            Logger.log("PeerExchange: failed to send notes", event: .error(error))
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
        Logger.log("PeerExchange: sync completed successfully, received \(receivedNotes.count) notes from \(user.name)", event: .success)
        onEvent?(.completed)
        continuation.resume(returning: SyncResult(user: user, notes: receivedNotes))
    }
    
    private func finishSyncWithError(_ error: Error) {
        guard isActive else { return }
        
        isActive = false
        stopNetworking()
        Logger.log("PeerExchange: sync failed", event: .error(error))
        onEvent?(.failed(error))
        
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(throwing: error)
    }
    
    private func handle(message: SyncMessage, fromPeer peerID: MCPeerID) {
        guard isActive else {
            Logger.log("PeerExchange: handle ignored, isActive=false, kind=\(message.kind)", event: .unowned)
            return
        }
        
        switch message.kind {
        case .user:
            guard let user = message.user else { return }
            
            receivedUser = user
            Logger.log("PeerExchange: received user \(user.name) (id: \(user.id)), localFriend.user?.id: \(localFriend.user?.id.uuidString ?? "nil")", event: .success)
            
            // Пользователь получен — прекращаем поиск, чтобы не создавать лишних соединений
            advertiser.stopAdvertisingPeer()
            browser.stopBrowsingForPeers()
            
            if user.id == localFriend.user?.id {
                // Друг совпадает — сообщаем что рядом, ждём явного подтверждения из UI
                Logger.log("PeerExchange: friend matched -> friendNearby", event: .success)
                onEvent?(.friendNearby(user))
            } else {
                Logger.log("PeerExchange: friend not matched -> waitingForUserConfirmation", event: .unowned)
                onEvent?(.waitingForUserConfirmation(user))
            }
        case .userApproval:
            guard let approved = message.approval else { return }
            Logger.log("PeerExchange: received userApproval: \(approved), localApprovalSent: \(localApprovalSent)", event: .unowned)
            
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
            Logger.log("PeerExchange: received notes message, localApprovalSent: \(localApprovalSent), remoteApprovalReceived: \(remoteApprovalReceived), count: \(message.notes?.count ?? -1)", event: .unowned)
            guard localApprovalSent else { return }
            guard remoteApprovalReceived else { return }
            guard let notes = message.notes else { return }
            
            receivedNotes = notes
            Logger.log("PeerExchange: received \(notes.count) notes, calling finishSync", event: .success)
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            Logger.log("PeerExchange: session state changed to \(state.rawValue) for peer \(peerID.displayName), isActive: \(self.isActive)", event: .unowned)
            guard self.isActive else { return }
            
            switch state {
            case .connecting:
                self.onEvent?(.connecting)
            case .connected:
                self.onEvent?(.exchangingUsers)
                self.sendUser(to: peerID)
            case .notConnected:
                self.finishSyncWithError(SyncError.disconnected)
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Decode on background to avoid blocking main queue
        let message: SyncMessage
        do {
            message = try JSONDecoder().decode(SyncMessage.self, from: data)
        } catch {
            Logger.log("PeerExchange: failed to decode message", event: .error(error))
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            Logger.log("PeerExchange: received \(message.kind) from \(peerID.displayName), isActive: \(self.isActive)", event: .success)
            guard self.isActive else { return }
            self.handle(message: message, fromPeer: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    func session( _ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
}
