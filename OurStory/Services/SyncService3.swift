//
//  SyncService3.swift
//  OurStory
//
//  Network.framework-based peer-to-peer sync.
//  Drop-in replacement for SyncService2 (MultipeerConnectivity).
//

import Foundation
import Network

// MARK: - Wire Protocol

private enum Sync3MessageKind: String, Codable {
    case user, userApproval, notes, ack
}

private struct Sync3Message: Codable {
    let kind: Sync3MessageKind
    let user: User?
    let approval: Bool?
    let notes: [SyncNote]?
    
    static func user(_ user: User) -> Sync3Message {
        Sync3Message(kind: .user, user: user, approval: nil, notes: nil)
    }
    
    static func userApproval(_ approved: Bool) -> Sync3Message {
        Sync3Message(kind: .userApproval, user: nil, approval: approved, notes: nil)
    }
    
    static func notes(_ notes: [SyncNote]) -> Sync3Message {
        Sync3Message(kind: .notes, user: nil, approval: nil, notes: notes)
    }
    
    static var ack: Sync3Message {
        Sync3Message(kind: .ack, user: nil, approval: nil, notes: nil)
    }
}

// MARK: - NWProtocolFramer (SyncFramer)

/// Length-prefixed framer: [4 bytes big-endian payload size][JSON payload]
/// Replaces manual incomingBuffer parsing from SyncService2.
private class SyncFramer: NWProtocolFramerImplementation {
    
    static let definition = NWProtocolFramer.Definition(implementation: SyncFramer.self)
    static let label = "SyncFramer"
    
    required init(framer: NWProtocolFramer.Instance) {}
    
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { .ready }
    func stop(framer: NWProtocolFramer.Instance) -> Bool { true }
    func wakeup(framer: NWProtocolFramer.Instance) {}
    func cleanup(framer: NWProtocolFramer.Instance) {}
    
    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            var headerData = Data()
            let headerParsed = framer.parseInput(minimumIncompleteLength: 4, maximumLength: 4) { buffer, _ in
                if let buffer, buffer.count >= 4 {
                    headerData = Data(buffer.prefix(4))
                    return 4
                }
                return 0
            }
            guard headerParsed, headerData.count == 4 else { return 4 }
            
            let payloadLength = Int(headerData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
            let message = NWProtocolFramer.Message(definition: SyncFramer.definition)
            if !framer.deliverInputNoCopy(length: payloadLength, message: message, isComplete: true) {
                return 0
            }
        }
    }
    
    func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        var length = UInt32(messageLength).bigEndian
        framer.writeOutput(data: Data(bytes: &length, count: 4))
        do {
            try framer.writeOutputNoCopy(length: messageLength)
        } catch {
            Logger.log("SyncFramer: writeOutput failed", event: .error(error))
        }
    }
}

// MARK: - SyncService3

final class SyncService3 {
    
    private let profile: User
    private var session: Sync3Session?
    
    var onStateChanged: ((SyncProgressState) -> Void)?
    var onSyncCompleted: ((SyncResult) -> Void)?
    var onFriendReady: (() -> Void)?
    
    init(profile: User) {
        self.profile = profile
    }
    
    private var startWork: DispatchWorkItem?
    
    // MARK: - Scenario 1: First sync (no linked user)
    
    func startFirstSync(friend: Friend, notes: [Note]) {
        startWork?.cancel()
        let hadActiveSession = session != nil
        cancelSync()
        
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let session = Sync3Session(
                myProfile: self.profile,
                friend: friend,
                notes: notes,
                mode: .firstSync
            )
            self.session = session
            self.bindSession(session)
            session.start()
        }
        startWork = work
        let delay = hadActiveSession ? 0.5 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    // MARK: - Scenario 2: Discovery (linked friend)
    
    func startDiscovery(friend: Friend, notes: [Note]) {
        startWork?.cancel()
        guard friend.user != nil else { return }
        let hadActiveSession = session != nil
        cancelSync()
        
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let session = Sync3Session(
                myProfile: self.profile,
                friend: friend,
                notes: notes,
                mode: .discovery
            )
            self.session = session
            self.bindSession(session)
            session.start()
        }
        startWork = work
        let delay = hadActiveSession ? 0.5 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    func beginExchange(notes: [Note]) {
        session?.beginExchange(notes: notes)
    }
    
    func confirmUser(_ approved: Bool) {
        session?.confirmUser(approved)
    }
    
    func cancelSync() {
        startWork?.cancel()
        startWork = nil
        session?.cancel()
        session = nil
    }
    
    var isActive: Bool { session?.isActive ?? false }
    var isFriendNearby: Bool { session?.isFriendNearby ?? false }
    
    private func bindSession(_ session: Sync3Session) {
        session.onStateChanged = { [weak self] state in
            DispatchQueue.main.async { self?.onStateChanged?(state) }
        }
        session.onCompleted = { [weak self] result in
            DispatchQueue.main.async { self?.onSyncCompleted?(result) }
        }
        session.onFriendReady = { [weak self] in
            DispatchQueue.main.async { self?.onFriendReady?() }
        }
    }
}

// MARK: - Sync3Session

private final class Sync3Session {
    
    enum Mode { case firstSync, discovery }
    
    enum Phase: Equatable {
        case idle
        case searching
        case connecting
        case connected
        case userExchanged
        case waitingForApproval
        case friendNearby
        case exchanging
        case completed
        case failed
        case cancelled
    }
    
    // MARK: Properties
    
    private let myProfile: User
    private let friend: Friend
    private var myNotes: [SyncNote]
    private let mode: Mode
    private let myPeerID: String
    
    private let queue = DispatchQueue(label: "com.ourstory.sync3.session", qos: .userInitiated)
    
    private var phase: Phase = .idle
    private var phaseBeforeDisconnect: Phase?
    
    // Network.framework components
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    
    private let serviceType = "_ourstory._tcp"
    
    // Logical state (survives reconnects)
    private var receivedUser: User?
    private var sentUser = false
    private var receivedNotes: [SyncNote] = []
    private var receivedNotesMessage = false
    private var sentNotes = false
    private var localApproved = false
    private var remoteApproved = false
    private var sentAck = false
    private var receivedAck = false
    
    // Reconnect
    private var searchReconnectAttempts = 0
    private let maxSearchReconnects = 5
    
    // Timers
    private var searchTimeoutWork: DispatchWorkItem?
    private var exchangeDeadlineWork: DispatchWorkItem?
    private var reconnectDelayWork: DispatchWorkItem?
    
    // Callbacks
    var onStateChanged: ((SyncProgressState) -> Void)?
    var onCompleted: ((SyncResult) -> Void)?
    var onFriendReady: (() -> Void)?
    
    private(set) var isActive = false
    private(set) var isFriendNearby = false
    
    // MARK: Init
    
    init(myProfile: User, friend: Friend, notes: [Note], mode: Mode) {
        self.myProfile = myProfile
        self.friend = friend
        self.myNotes = notes.map { SyncNote(from: $0) }
        self.mode = mode
        self.myPeerID = myProfile.id.uuidString
    }
    
    deinit { tearDownTransport() }
    
    // MARK: - Public API
    
    func start() {
        queue.async { [self] in
            guard phase == .idle else { return }
            isActive = true
            transition(to: .searching)
            buildTransportAndStart()
        }
    }
    
    func beginExchange(notes: [Note]) {
        queue.async { [self] in
            guard phase == .friendNearby else { return }
            isFriendNearby = false
            myNotes = notes.map { SyncNote(from: $0) }
            localApproved = true
            sendMessage(.userApproval(true))
            trySendNotes()
        }
    }
    
    func confirmUser(_ approved: Bool) {
        queue.async { [self] in
            guard phase == .waitingForApproval else { return }
            localApproved = approved
            sendMessage(.userApproval(approved))
            
            if !approved {
                transition(to: .failed)
                emitState(.failed(SyncError.userRejected))
                cleanup()
                return
            }
            trySendNotes()
        }
    }
    
    func cancel() {
        queue.async { [self] in
            guard isActive else { return }
            transition(to: .cancelled)
            cleanup()
        }
    }
    
    // MARK: - NWParameters
    
    private func makeParameters() -> NWParameters {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveInterval = 5
        tcpOptions.keepaliveCount = 3
        
        let params = NWParameters(tls: nil, tcp: tcpOptions)
        params.includePeerToPeer = true
        
        let framerOptions = NWProtocolFramer.Options(definition: SyncFramer.definition)
        params.defaultProtocolStack.applicationProtocols.insert(framerOptions, at: 0)
        
        return params
    }
    
    // MARK: - Transport Lifecycle
    
    private func buildTransportAndStart() {
        tearDownTransport()
        
        let params = makeParameters()
        
        // NWListener
        guard let newListener = try? NWListener(using: params) else {
            Logger.log("Sync3: failed to create NWListener", event: .unowned)
            transition(to: .failed)
            emitState(.failed(SyncError.notConnected))
            cleanup()
            return
        }
        
        let txtRecord = NWTXTRecord(["uid": myPeerID])
        newListener.service = NWListener.Service(name: myPeerID, type: serviceType, txtRecord: txtRecord)
        
        newListener.stateUpdateHandler = { [weak self] state in
            self?.queue.async { self?.handleListenerState(state) }
        }
        newListener.newConnectionHandler = { [weak self] conn in
            self?.queue.async { self?.handleIncomingConnection(conn) }
        }
        self.listener = newListener
        newListener.start(queue: queue)
        
        // NWBrowser — needs separate params (no TCP/framer, just P2P)
        let browseParams = NWParameters()
        browseParams.includePeerToPeer = true
        let newBrowser = NWBrowser(for: .bonjourWithTXTRecord(type: serviceType, domain: nil), using: browseParams)
        newBrowser.stateUpdateHandler = { [weak self] state in
            self?.queue.async { self?.handleBrowserState(state) }
        }
        newBrowser.browseResultsChangedHandler = { [weak self] results, changes in
            self?.queue.async { self?.handleBrowseResults(results) }
        }
        self.browser = newBrowser
        newBrowser.start(queue: queue)
        
        Logger.log("Sync3: transport built, searching…", event: .unowned)
        
        if phase == .searching, phaseBeforeDisconnect == nil {
            startSearchTimeout()
        }
    }
    
    private func tearDownTransport() {
        listener?.cancel()
        browser?.cancel()
        connection?.cancel()
        listener = nil
        browser = nil
        connection = nil
    }
    
    // MARK: - Listener State
    
    private func handleListenerState(_ state: NWListener.State) {
        guard isActive else { return }
        switch state {
        case .ready:
            Logger.log("Sync3: listener ready", event: .success)
        case .failed(let error):
            Logger.log("Sync3: listener failed", event: .error(error))
            handleDisconnect()
        case .cancelled:
            break
        default:
            break
        }
    }
    
    // MARK: - Browser State & Results
    
    private func handleBrowserState(_ state: NWBrowser.State) {
        guard isActive else { return }
        switch state {
        case .ready:
            Logger.log("Sync3: browser ready", event: .success)
        case .failed(let error):
            Logger.log("Sync3: browser failed", event: .error(error))
            handleDisconnect()
        default:
            break
        }
    }
    
    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        guard isActive, connection == nil else { return }
        
        Logger.log("Sync3: browse results: \(results.count) peer(s)", event: .unowned)
        
        for result in results {
            guard case .service(let name, _, _, _) = result.endpoint else {
                Logger.log("Sync3: skipping non-service endpoint: \(result.endpoint)", event: .unowned)
                continue
            }
            guard name != myPeerID else { continue }
            
            // In discovery mode, pre-filter by TXT record
            if mode == .discovery, let expectedUID = friend.user?.id.uuidString {
                if case .bonjour(let txtRecord) = result.metadata {
                    guard txtRecord["uid"] == expectedUID else { continue }
                } else {
                    // TXT record not yet resolved — skip, will get update later
                    continue
                }
            }
            
            // Role arbitration: lower UUID initiates connection
            Logger.log("Sync3: found peer \(name), myPeerID: \(myPeerID), metadata: \(result.metadata)", event: .unowned)
            if myPeerID < name {
                Logger.log("Sync3: I initiate → connecting to \(name)", event: .unowned)
                connectToPeer(result.endpoint)
            } else {
                Logger.log("Sync3: peer initiates → waiting for connection from \(name)", event: .unowned)
            }
            break
        }
    }
    
    // MARK: - Connection
    
    private func connectToPeer(_ endpoint: NWEndpoint) {
        guard connection == nil else { return }
        let conn = NWConnection(to: endpoint, using: makeParameters())
        setupConnection(conn)
        conn.start(queue: queue)
    }
    
    private func handleIncomingConnection(_ conn: NWConnection) {
        guard isActive else {
            conn.cancel()
            return
        }
        
        if connection != nil {
            conn.cancel()
            return
        }
        
        Logger.log("Sync3: accepted incoming connection", event: .unowned)
        setupConnection(conn)
        conn.start(queue: queue)
    }
    
    private func setupConnection(_ conn: NWConnection) {
        connection = conn
        
        conn.stateUpdateHandler = { [weak self] state in
            self?.queue.async { self?.handleConnectionState(state) }
        }
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        guard isActive else { return }
        
        switch state {
        case .preparing:
            cancelSearchTimeout()
            if phase == .searching {
                transition(to: .connecting)
            }
            
        case .ready:
            searchReconnectAttempts = 0
            
            // Stop discovery — we have a connection
            listener?.cancel()
            browser?.cancel()
            listener = nil
            browser = nil
            
            if phaseBeforeDisconnect == nil {
                transition(to: .connected)
            }
            
            receiveNextMessage()
            sendUserOnConnect()
            
        case .failed(let error):
            Logger.log("Sync3: connection failed", event: .error(error))
            connection = nil
            handleDisconnect()
            
        case .cancelled:
            break
            
        case .waiting(let error):
            Logger.log("Sync3: connection waiting: \(error)", event: .unowned)
            
        default:
            break
        }
    }
    
    // MARK: - Sending
    
    private func sendMessage(_ message: Sync3Message) {
        guard let connection, connection.state == .ready else {
            Logger.log("Sync3: sendMessage but no ready connection (\(message.kind))", event: .unowned)
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(message)
            let framerMessage = NWProtocolFramer.Message(definition: SyncFramer.definition)
            let context = NWConnection.ContentContext(
                identifier: "sync3-\(message.kind.rawValue)",
                metadata: [framerMessage]
            )
            
            connection.send(content: jsonData, contentContext: context, isComplete: true, completion: .contentProcessed { [weak self] error in
                if let error {
                    Logger.log("Sync3: send failed", event: .error(error))
                    self?.queue.async { self?.handleDisconnect() }
                }
            })
            
            Logger.log("Sync3: sent \(message.kind) (\(jsonData.count) bytes)", event: .success)
        } catch {
            Logger.log("Sync3: encode failed", event: .error(error))
            handleDisconnect()
        }
    }
    
    // MARK: - Receiving
    
    private func receiveNextMessage() {
        guard let connection else { return }
        
        connection.receiveMessage { [weak self] content, context, isComplete, error in
            guard let self else { return }
            self.queue.async {
                if let error {
                    Logger.log("Sync3: receive error", event: .error(error))
                    self.handleDisconnect()
                    return
                }
                
                guard let content, !content.isEmpty else {
                    self.handleDisconnect()
                    return
                }
                
                do {
                    let message = try JSONDecoder().decode(Sync3Message.self, from: content)
                    self.handleMessage(message)
                } catch {
                    Logger.log("Sync3: decode failed", event: .error(error))
                }
                
                self.receiveNextMessage()
            }
        }
    }
    
    // MARK: - Message Handling
    
    private func handleMessage(_ message: Sync3Message) {
        guard isActive else { return }
        
        Logger.log("Sync3: received \(message.kind), phase: \(desc(phase))", event: .success)
        
        switch message.kind {
        case .user:
            guard let user = message.user else { return }
            receivedUser = user
            
            cancelSearchTimeout()
            
            switch mode {
            case .firstSync:
                if sentUser {
                    if phaseBeforeDisconnect != nil {
                        replayStateAfterReconnect()
                    } else {
                        transition(to: .waitingForApproval)
                    }
                } else {
                    transition(to: .userExchanged)
                }
                
            case .discovery:
                if user.id == friend.user?.id {
                    if sentUser {
                        if phaseBeforeDisconnect != nil {
                            replayStateAfterReconnect()
                        } else {
                            transition(to: .friendNearby)
                        }
                    } else {
                        transition(to: .userExchanged)
                    }
                } else {
                    // Wrong peer — disconnect and keep searching
                    Logger.log("Sync3: wrong peer \(user.name)", event: .unowned)
                    connection?.cancel()
                    connection = nil
                    receivedUser = nil
                    sentUser = false
                    phase = .searching
                    buildTransportAndStart()
                }
            }
            
        case .userApproval:
            guard let approved = message.approval else { return }
            if !approved {
                transition(to: .failed)
                emitState(.failed(SyncError.userRejected))
                cleanup()
                return
            }
            remoteApproved = true
            
            if mode == .discovery, !localApproved, phase == .friendNearby {
                onFriendReady?()
            }
            
            trySendNotes()
            
        case .notes:
            guard let notes = message.notes else { return }
            guard !receivedNotesMessage else {
                // Duplicate — re-send ack
                sendMessage(.ack)
                return
            }
            receivedNotes = notes
            receivedNotesMessage = true
            Logger.log("Sync3: received \(notes.count) notes", event: .success)
            
            sentAck = true
            sendMessage(.ack)
            tryFinish()
            
        case .ack:
            Logger.log("Sync3: received ACK", event: .success)
            receivedAck = true
            tryFinish()
        }
    }
    
    // MARK: - Note Exchange Logic
    
    private func trySendNotes() {
        guard isActive else { return }
        guard localApproved, remoteApproved else { return }
        guard !sentNotes else { return }
        
        guard connection?.state == .ready else {
            Logger.log("Sync3: trySendNotes but no connection, waiting for reconnect", event: .unowned)
            return
        }
        
        sentNotes = true
        transition(to: .exchanging)
        startExchangeDeadline()
        
        sendMessage(.notes(myNotes))
        tryFinish()
    }
    
    private func tryFinish() {
        guard isActive else { return }
        guard sentNotes, receivedNotesMessage, sentAck, receivedAck else { return }
        guard let user = receivedUser else { return }
        
        Logger.log("Sync3: both sides confirmed, completing", event: .success)
        transition(to: .completed)
        
        let result = SyncResult(user: user, notes: receivedNotes)
        onCompleted?(result)
        cleanup()
    }
    
    // MARK: - Send User on Connect
    
    private func sendUserOnConnect() {
        guard !sentUser else { return }
        sentUser = true
        
        sendMessage(.user(myProfile))
        
        // If we already received remote user, advance state
        guard isActive, receivedUser != nil else { return }
        
        if phaseBeforeDisconnect != nil {
            replayStateAfterReconnect()
        } else {
            switch mode {
            case .firstSync:
                transition(to: .waitingForApproval)
            case .discovery:
                if receivedUser?.id == friend.user?.id {
                    transition(to: .friendNearby)
                }
            }
        }
    }
    
    // MARK: - Reconnect
    
    private func replayStateAfterReconnect() {
        guard let prev = phaseBeforeDisconnect else { return }
        phaseBeforeDisconnect = nil
        searchReconnectAttempts = 0
        
        Logger.log("Sync3: replaying state from \(desc(prev))", event: .unowned)
        
        switch prev {
        case .waitingForApproval:
            transition(to: .waitingForApproval)
            if localApproved {
                sendMessage(.userApproval(true))
                trySendNotes()
            }
            
        case .friendNearby:
            transition(to: .friendNearby)
            if localApproved {
                sendMessage(.userApproval(true))
                trySendNotes()
            } else if remoteApproved {
                onFriendReady?()
            }
            
        case .exchanging:
            transition(to: .exchanging)
            sendMessage(.userApproval(true))
            if sentNotes {
                sendMessage(.notes(myNotes))
            }
            if sentAck {
                sendMessage(.ack)
                tryFinish()
            }
            
        default:
            break
        }
    }
    
    private func handleDisconnect() {
        guard isActive else { return }
        let disconnectedPhase = phase
        
        Logger.log("Sync3: disconnect in phase \(desc(disconnectedPhase))", event: .unowned)
        
        switch disconnectedPhase {
        case .completed, .failed, .cancelled, .idle:
            return
        default:
            break
        }
        
        reconnect(from: disconnectedPhase)
    }
    
    private func reconnect(from disconnectedPhase: Phase) {
        guard isActive else { return }
        
        if disconnectedPhase == .searching || disconnectedPhase == .connecting {
            searchReconnectAttempts += 1
            if searchReconnectAttempts > maxSearchReconnects {
                transition(to: .failed)
                emitState(.failed(SyncError.disconnected))
                cleanup()
                return
            }
        }
        
        phaseBeforeDisconnect = disconnectedPhase
        connection = nil
        sentUser = false
        
        let shouldNotifyUI: Bool
        switch disconnectedPhase {
        case .searching, .connecting: shouldNotifyUI = false
        default: shouldNotifyUI = true
        }
        
        if shouldNotifyUI {
            transition(to: .searching)
        } else {
            phase = .searching
        }
        
        Logger.log("Sync3: reconnecting from \(desc(disconnectedPhase)), attempt \(searchReconnectAttempts)", event: .unowned)
        
        reconnectDelayWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.queue.async {
                guard self.isActive else { return }
                self.buildTransportAndStart()
            }
        }
        reconnectDelayWork = work
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: work)
    }
    
    // MARK: - State Transitions
    
    private func transition(to newPhase: Phase) {
        let old = phase
        phase = newPhase
        Logger.log("Sync3: \(desc(old)) → \(desc(newPhase))", event: .unowned)
        
        switch newPhase {
        case .searching:    emitState(.searching)
        case .connecting:   emitState(.connecting)
        case .connected:    emitState(.exchangingUsers)
        case .waitingForApproval:
            if let u = receivedUser { emitState(.waitingForUserConfirmation(u)) }
        case .friendNearby:
            isFriendNearby = true
            if let u = receivedUser { emitState(.friendNearby(u)) }
        case .exchanging:   emitState(.exchangingNotes)
        case .completed:    emitState(.completed)
        case .failed:       break // caller emits specific error
        default:            break
        }
    }
    
    private func emitState(_ state: SyncProgressState) {
        onStateChanged?(state)
    }
    
    private func desc(_ p: Phase) -> String {
        switch p {
        case .idle: "idle"
        case .searching: "searching"
        case .connecting: "connecting"
        case .connected: "connected"
        case .userExchanged: "userExchanged"
        case .waitingForApproval: "waitingForApproval"
        case .friendNearby: "friendNearby"
        case .exchanging: "exchanging"
        case .completed: "completed"
        case .failed: "failed"
        case .cancelled: "cancelled"
        }
    }
    
    // MARK: - Timeouts
    
    private func startSearchTimeout() {
        searchTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.queue.async {
                guard self.isActive else { return }
                guard self.phase == .searching, self.phaseBeforeDisconnect == nil else { return }
                Logger.log("Sync3: search timeout", event: .unowned)
                self.transition(to: .failed)
                self.emitState(.failed(SyncError.notConnected))
                self.cleanup()
            }
        }
        searchTimeoutWork = work
        DispatchQueue.global().asyncAfter(deadline: .now() + 30, execute: work)
    }
    
    private func cancelSearchTimeout() {
        searchTimeoutWork?.cancel()
        searchTimeoutWork = nil
    }
    
    private func startExchangeDeadline() {
        guard exchangeDeadlineWork == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.queue.async {
                guard self.isActive, self.phase == .exchanging else { return }
                Logger.log("Sync3: exchange deadline reached", event: .unowned)
                self.transition(to: .failed)
                self.emitState(.failed(SyncError.disconnected))
                self.cleanup()
            }
        }
        exchangeDeadlineWork = work
        DispatchQueue.global().asyncAfter(deadline: .now() + 60, execute: work)
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        isActive = false
        isFriendNearby = false
        searchTimeoutWork?.cancel()
        searchTimeoutWork = nil
        exchangeDeadlineWork?.cancel()
        exchangeDeadlineWork = nil
        reconnectDelayWork?.cancel()
        reconnectDelayWork = nil
        tearDownTransport()
    }
}
