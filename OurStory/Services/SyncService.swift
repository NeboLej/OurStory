//
//  SyncService.swift
//  OurStory
//
//  Created by Nebo on 22.09.2026.
//

import Foundation
import MultipeerConnectivity

class SyncService {
    
    var manager: PeerExchangeManager?
    
    
    func syncFriend(friend: Friend) {
        let currentUser = User(name: "ВИТЯ", color: "5544dd")
        print(currentUser.id)
        
        manager = PeerExchangeManager(localUser: currentUser)
        manager?.start()
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
