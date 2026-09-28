//
//  HomeScreen.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

struct HomeScreen: View {
    
    @State private var store: HomeScreenStore
    @State private var screenBuilder: ScreenBuilder
    @State private var noteListStore: NoteListScreenStore
    
    init(store: HomeScreenStore, screenBuilder: ScreenBuilder) {
        self.store = store
        self.screenBuilder = screenBuilder
        self.noteListStore = NoteListScreenStore(appStore: store.appStore, notes: [])
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .frame(height: 70)
                .foregroundStyle(Color.myPrimary)
            screenBuilder.getComponent(type: .horizontalCalendar)
                .padding(.top, 16)
            
            if let currentStory = store.state.selectedStory {
                ScrollView(.vertical) {
                    storyView(currentStory)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Историй пока нет")
                        .font(.myMedium(size: 18))
                        .foregroundStyle(.textMulticolor)
                        .padding(.bottom, 4)
                        .padding(.top, 20)
                    Text(store.state.selectedDate.toReadable())
                        .font(.myItalic(size: 14))
                        .foregroundStyle(.textMulticolor.opacity(0.6))
                        .padding(.bottom, 36)
                    Spacer()
                }
                .padding(.horizontal, 42)
            }
        }
        .background(.backgroundFill)
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                if noteListStore.isShowFriendsList {
                    NoteListScreen(title: nil, store: noteListStore).friendsListOverlay
                } else {
                    HomeScreenToolbar {
                        store.send(.toFriendsList)
                    } onSettings: {
                        store.send(.toSettings)
                    } onNewNote: {
                        store.send(.createNewNote)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func storyView(_ story: Story) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                Text(story.title)
                    .font(.myMedium(size: 18))
                    .foregroundStyle(.textMulticolor)
                    .padding(.bottom, 4)
                    .padding(.top, 20)
                Text(story.date.toReadable())
                    .font(.myItalic(size: 14))
                    .foregroundStyle(.textMulticolor.opacity(0.6))
                    .padding(.bottom, 36)
            }
            .padding(.leading, 30)
            
            NoteListScreen(title: nil, store: noteListStore).noteListContent
        }
        .padding(.bottom, 180)
        .onChange(of: story.notes) { _, newNotes in
            noteListStore.updateNotes(newNotes)
        }
        .onAppear {
            noteListStore.updateNotes(story.notes)
        }
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .home)
}
