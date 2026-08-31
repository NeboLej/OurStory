//
//  HomeScreen.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

struct HomeScreen: View {
    
    @State private var store: HomeScreenStore
    
    init(store: HomeScreenStore) {
        self.store = store
    }
    
    var body: some View {
        ScrollView(.vertical) {
            
            if let currentSroty = store.state.currentStory {
                storyView(currentSroty)
            }
            
        }
//        .ignoresSafeArea(.all)
        .frame(maxWidth: .infinity)
        .background(.backgroundFill)
        
    }
    
    
    @ViewBuilder
    private func storyView(_ story: Story) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(story.title)
                .font(.myMedium(size: 16))
                .foregroundStyle(.titleDark)
                .padding(.bottom, 4)
            Text(story.date.description)
                .font(.myItalic(size: 12))
                .foregroundStyle(.titleDark.opacity(0.6))
                .padding(.bottom, 30)
            
            ForEach(story.notes) { note in
                noteView(note)
            }
        }
        .padding(.horizontal, 6)
    }
    
    
    @ViewBuilder
    private func noteView(_ note: Note) -> some View {
        if note.owner == nil {
            HStack(alignment: .top, spacing: 16) {
                Rectangle()
                    .frame(width: 16)
                    
                VStack(alignment: .leading, spacing: 0) {
                    if let noteTitle = note.title {
                        Text(noteTitle)
                            .font(.mySemiBold(size: 15))
                    }

                    Text(note.text)
                        .multilineTextAlignment(.leading)
                        .font(.myRegular(size: 15))
                }

            }
        }

    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .home)
}
