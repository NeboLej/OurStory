//
//  HelpModels.swift
//  OurStory
//
//  Created by Nebo on 22.10.2026.
//

import Foundation

enum HelpType {
    static let helps: [Help] = [
        HelpType.addedFriend,
        HelpType.exhangeStory,
    ]
    
    static let exhangeStory = Help(id: 2, title: L10n.helpExchangeTitle, subtitle: "", blocks: [], internactiveBlock:
        InteractiveHelpBlock(animationName: "phones_exchange", playbackBlocks: [
            PlaybackHelpBlocks(playbackName: "approach", animationSpeed: 0.55, blocks: [
                .text(L10n.helpExchangeBlock1),
                .note(L10n.helpExchangeNote1),
                .warning(L10n.helpExchangeWarning1)
            ]),
            PlaybackHelpBlocks(playbackName: "press", animationSpeed: 0.6, blocks: [
                .text(L10n.helpExchangeBlock2),
                .note(L10n.helpExchangeNote2),
                
            ]),
            PlaybackHelpBlocks(playbackName: "exchange", animationSpeed: 0.7, blocks: [
                .text(L10n.helpExchangeBlock3),
                .note(L10n.helpExchangeNote3),
            ]),
        ]))
    
    static let addedFriend = Help(id: 1, title: L10n.helpAddFriendTitle, subtitle: "", blocks: [], internactiveBlock:
        InteractiveHelpBlock(animationName: "friends_guide", playbackBlocks: [
            PlaybackHelpBlocks(playbackName: "storytellers", animationSpeed: 1.4, blocks: [
                .text(L10n.helpAddBlock1),
                .note(L10n.helpAddNote1)
            ]),
            
            PlaybackHelpBlocks(playbackName: "add_remote", animationSpeed: 1, blocks: [
                .text(L10n.helpAddBlock2),
                .note(L10n.helpAddNote2)
            ]),
            
            PlaybackHelpBlocks(playbackName: "add_nearby", animationSpeed: 1, blocks: [
                .text(L10n.helpAddBlock3),
                .warning(L10n.helpAddWarning)
            ]),
        ])
    )
}

struct Help: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    
    let blocks: [HelpBlock]
    let internactiveBlock: InteractiveHelpBlock
}

struct InteractiveHelpBlock {
    let animationName: String
    let playbackBlocks: [PlaybackHelpBlocks]
}

struct PlaybackHelpBlocks {
    let playbackName: String
    let animationSpeed: Double
    let blocks: [HelpBlock]
}

enum HelpBlock {
    case text(String)
    case heading(String)
    case image(String)
    case note(String)
    case warning(String)
    case button(String)
}

import SwiftUI

#Preview {
    NavigationStack {
        HelpScreen(help: HelpType.addedFriend)
    }
}

