//
//  SyncService.swift
//  OurStory
//
//  Created by Nebo on 22.09.2026.
//

import Foundation
import MultipeerConnectivity

class SyncService {
    
    var profile: User
    
    init(profile: User) {
        self.profile = profile
    }
    
    var manager: PeerExchangeManager2?
    
//    func syncFriend(friend: Friend) async throws -> User {
//        manager = PeerExchangeManager2(localUser: profile)
//        let friend = try await manager?.sync()
//    }
    
    func syncFriend(friend: Friend) async throws -> User {

        let manager = PeerExchangeManager2(localUser: profile)

        return try await manager.sync()
    }
}

import Foundation
import MultipeerConnectivity

final class PeerExchangeManager2: NSObject {

    private let localUser: User

    private let peerID: MCPeerID
    private let session: MCSession

    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser

    private var continuation: CheckedContinuation<User, Error>?

    private let serviceType = "user-exchange"

    init(localUser: User) {
        self.localUser = localUser

        self.peerID = MCPeerID(
            displayName: localUser.id.uuidString
        )

        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )

        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: serviceType
        )

        self.browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: serviceType
        )

        super.init()

        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func sync() async throws -> User {

        try await withCheckedThrowingContinuation { continuation in

            self.continuation = continuation

            advertiser.startAdvertisingPeer()
            browser.startBrowsingForPeers()
        }
    }
}

extension PeerExchangeManager2: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {

        // В прототипе автоматически принимаем соединение.

        invitationHandler(true, session)
    }
}

extension PeerExchangeManager2: MCNearbyServiceBrowserDelegate {

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {

        print("Found peer:", peerID.displayName)

        browser.invitePeer(
            peerID,
            to: session,
            withContext: nil,
            timeout: 10
        )
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        print("Lost peer:", peerID.displayName)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        finish(error: error)
    }
}

//extension PeerExchangeManager2: MCNearbyServiceAdvertiserDelegate {
//
//    func advertiser(
//        _ advertiser: MCNearbyServiceAdvertiser,
//        didReceiveInvitationFromPeer peerID: MCPeerID,
//        withContext context: Data?,
//        invitationHandler: @escaping (Bool, MCSession?) -> Void
//    ) {
//
//        print("Received invitation from:", peerID.displayName)
//
//        invitationHandler(true, session)
//    }
//
//    func advertiser(
//        _ advertiser: MCNearbyServiceAdvertiser,
//        didNotStartAdvertisingPeer error: Error
//    ) {
//        finish(error: error)
//    }
//}

extension PeerExchangeManager2: MCSessionDelegate {
    
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        
        print("Peer state:", state)
        
        guard state == .connected else {
            return
        }
        
        do {
            let data = try JSONEncoder().encode(localUser)
            
            try session.send(
                data,
                toPeers: [peerID],
                with: .reliable
            )
            
        } catch {
            finish(error: error)
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {

        do {
            let user = try JSONDecoder().decode(
                User.self,
                from: data
            )

            finish(user: user)

        } catch {
            finish(error: error)
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
    }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
    }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
    }
}



private extension PeerExchangeManager2 {

    func finish(user: User) {

        cleanup()

        continuation?.resume(returning: user)
        continuation = nil
    }

    func finish(error: Error) {

        cleanup()

        continuation?.resume(throwing: error)
        continuation = nil
    }

    func cleanup() {

        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()

        session.disconnect()
    }
}






import Foundation
import MultipeerConnectivity

final class PeerExchangeManager: NSObject {

    // MARK: - Constants

    private let serviceType = "user-exchange"

    // MARK: - Local User

    let localUser: User

    // MARK: - Multipeer Connectivity

    private let peerID: MCPeerID

    private let session: MCSession

    private let advertiser: MCNearbyServiceAdvertiser

    private let browser: MCNearbyServiceBrowser

    // MARK: - Callbacks

    var onReceiveUser: ((User) -> Void)?

    var onConnectionChanged: ((MCSessionState) -> Void)?

    // MARK: - Init

    init(localUser: User) {

        self.localUser = localUser

        self.peerID = MCPeerID(
            displayName: localUser.id.uuidString
        )

        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )

        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: serviceType
        )

        self.browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: serviceType
        )

        super.init()

        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    // MARK: - Start

    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    // MARK: - Stop

    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }

    // MARK: - Send User

    func sendUser() {

        guard !session.connectedPeers.isEmpty else {
            return
        }

        do {
            let data = try JSONEncoder().encode(localUser)

            try session.send(
                data,
                toPeers: session.connectedPeers,
                with: .reliable
            )

        } catch {
            print("Failed to send User:", error)
        }
    }
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

    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {

        print("Lost peer:", peerID.displayName)
    }
}

extension PeerExchangeManager: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState ) {

        print("Peer:", peerID.displayName, "state:", state.rawValue)

        DispatchQueue.main.async {
            self.onConnectionChanged?(state)
        }

        if state == .connected {
            // Как только соединение установлено,
            // отправляем нашего User.
            sendUser()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {

        do {
            let user = try JSONDecoder().decode(User.self, from: data)

            print("Received user:", user)

            DispatchQueue.main.async {
                self.onReceiveUser?(user)
            }

        } catch {
            print("Failed to decode User:", error)
        }
    }

    // MARK: - Required MCSessionDelegate methods

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
}
