//
//  HelpScreen.swift
//  OurStory
//
//  Created by Nebo on 22.10.2026.
//

import SwiftUI

struct HelpScreen: View {
    
    @Environment(\.dismiss) var dismiss
    let help: Help
    @State var playbackIndex = 0
    private var isHaveNextBlock: Bool {
        playbackIndex < (help.internactiveBlock.playbackBlocks.count - 1)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !help.subtitle.isEmpty {
                        Text(help.subtitle)
                            .font(.mySemiBold(size: 16))
                    }
                    
                    InteractiveBlockView(block: help.internactiveBlock, playbackIndex: $playbackIndex)
                    
                    ForEach(help.blocks.indices, id: \.self) { index in
                        BlockView(block: help.blocks[index])
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            
            Button {
                if !help.internactiveBlock.playbackBlocks.isEmpty {
                    if playbackIndex == help.internactiveBlock.playbackBlocks.count - 1 {
                        dismiss()
                    } else {
                        playbackIndex += 1
                    }
                } else {
                    dismiss()
                }
            } label: {
                VStack(spacing: 2) {
                    Text(isHaveNextBlock ? "ДАЛЕЕ" : "ПОНЯТНО")
                        .font(.mySemiBold(size: 14))
                        .tracking(2)
                        .foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.myPrimary)
                .overlay {
                    Rectangle()
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                        .padding(3)
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle(help.title)
        .navigationBarTitleDisplayMode(.large)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .background(Color.backgroundFill)
    }
}

import Lottie

struct InteractiveBlockView: View {
    let block: InteractiveHelpBlock
    @Binding var playbackIndex: Int
    @State private var currentPlayback: PlaybackHelpBlocks
    
    init(block: InteractiveHelpBlock, playbackIndex: Binding<Int>) {
        self.block = block
        self.currentPlayback = block.playbackBlocks[0]
        self._playbackIndex = playbackIndex
    }
  
    private var lottiePlayback: LottiePlaybackMode {
        .playing(.marker(currentPlayback.playbackName, loopMode: .loop))
    }
    
    var body: some View {
        VStack {
            LottieView(animation: .named(block.animationName))
                .resizable()
                .playbackMode(lottiePlayback)
                .animationSpeed(currentPlayback.animationSpeed)
                .frame(maxWidth: 400)
                .aspectRatio(4 / 3, contentMode: .fit)
                .frame(maxWidth: .infinity)
            
            pageIndicators()
                .padding(.bottom, 16)
            
            VStack {
                ForEach(currentPlayback.blocks.indices, id: \.self) { index in
                    BlockView(block: currentPlayback.blocks[index])
                }
            }
            .id(playbackIndex)

        }
        .clipped()
        .onChange(of: playbackIndex) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.35)) {
                currentPlayback = block.playbackBlocks[playbackIndex]
            }
        }
    }
    
    @ViewBuilder
    private func pageIndicators() -> some View {
        HStack(spacing: 6) {
            ForEach(0..<block.playbackBlocks.count, id: \.self) { index in
                Capsule()
                    .foregroundColor(index == playbackIndex ? .myPrimary : .gray.opacity(0.3))
                    .frame(width: index == playbackIndex ? 16 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: playbackIndex)
            }
        }
    }
}

struct BlockView: View {
    let block: HelpBlock

    var body: some View {
        switch block {
        case .text(let text):
            MarkdownText(text)
        case .heading(let text):
            Text(text)
                .font(.title2.bold())
                .padding(.top, 8)
        case .note(let text):
            Callout(text: text, systemImage: "lightbulb", color: .blue)
        case .warning(let text):
            Callout(text: text, systemImage: "exclamationmark.triangle", color: .orange)
        case .image(let image):
            Image(image)
        case .button:
            EmptyView()
        }
    }
}



struct MarkdownText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(attributed)
            .font(.myMedium(size: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributed: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

private struct Callout: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            MarkdownText(text)
                .font(.myRegular(size: 16))
        }
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        HelpScreen(help: HelpType.exhangeStory)
    }
}
