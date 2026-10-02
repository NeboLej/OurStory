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
    @State private var isShowFriendsList: Bool = false
    
    init(store: HomeScreenStore, screenBuilder: ScreenBuilder) {
        self.store = store
        self.screenBuilder = screenBuilder
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .frame(height: 70)
                .foregroundStyle(Color.myPrimary)
            screenBuilder.getComponent(type: .horizontalCalendar)
                .overlay(alignment: .topTrailing) {
                    if store.state.isSyncing {
                        CloudSyncIndicator()
                            .padding(.trailing, 12)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: store.state.isSyncing)
                .padding(.top, 16)
            
            if let currentStory = store.state.selectedStory {
                storyView(currentStory)
                    .id(store.state.selectedStory?.id ?? UUID())
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
            if !isShowFriendsList {
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
    
    @ViewBuilder
    private func storyView(_ story: Story) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                Text(story.title)
                    .font(.myMedium(size: 18))
                    .foregroundStyle(.textMulticolor)
                    .padding(.top, 20)
                Text(story.date.toReadable())
                    .font(.myItalic(size: 14))
                    .foregroundStyle(.textMulticolor.opacity(0.6))
                    .padding(.bottom, 36)
            }
            .padding(.leading, 16)
            
            screenBuilder.getComponent(type: .notesList(notes: story.notes, storyID: story.id, isShowFriendsList: $isShowFriendsList))
        }
        .padding(.bottom, 80)
    }
}

let tmpNotes = [
    Note(id: UUID(), rootStoryID: UUID(), title: "ndfsfd", date: Date(), text: "выоатл ыывот аоыва ываи оываорыв ивыл оатыв иаоывр авдыла ытва ", friends: [], owner: Friend(name: "Вася", color: "44fd21")),
    
    Note(id: UUID(), rootStoryID: UUID(), title: "", date: Date().getOffsetDate(-3), text: "выоатл ыывот аоыва ываи оываорыв ивыл оатыв иаоывр авдыла ытва ", friends: [Friend(name: "Вася", color: "44fd21")], owner: nil),
    
    Note(id: UUID(), rootStoryID: UUID(), title: nil, date: Date().getOffsetDate(-5), text: "выоатл ыывот аоыва ываи оываорыв ивыл оатыв иаоывр авдыла ытва ", friends: [], owner: nil)
]

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .home)
}
