//
//  HomeScreen.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI
import Lottie

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
                    HStack {
                        if store.state.isSyncing {
                            CloudSyncIndicator()
                        }
                        
                        Button {
                            store.send(.toSettings)
                        } label: {
                           Image(systemName: "gearshape.fill")
                                .foregroundStyle(.myPrimary)
                        }
                    }
                    .padding(.trailing, 12)
                    .transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.3), value: store.state.isSyncing)
                .padding(.top, 16)
            
            if let currentStory = store.state.selectedStory {
                storyView(currentStory)
                    .id(store.state.selectedStory?.id ?? UUID())
            } else {
                VStack(alignment: .center, spacing: 0) {
                    Spacer()
                    ZStack {
                        LottieView(animation: .named("day_empty"))
                            .resizable()
                            .playing(loopMode: .loop)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: 150)
                            .opacity(0.6)
                        VStack {
                            Text(store.state.selectedDate.toDay())
                                .font(.mySemiBold(size: 20))
                                .foregroundStyle(.myPrimary)
                            
                            Text(store.state.selectedDate.toMonth())
                                .font(.myRegular(size: 14))
                                .foregroundStyle(.myPrimary)
                        }
                        .padding(.trailing, 12)
                        .padding(.top, 20)
                    }
                    .padding(.leading, 12)
                
                    Text(TextFactory.shared.getEmptyDayText(date: store.state.selectedDate))
                        .font(.myRegular(size: 16))
                        .foregroundStyle(.textMulticolor.opacity(0.6))
                        .padding(.bottom, 36)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.bottom, 80)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 42)
            }
        }
        .background(.backgroundFill)
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isShowFriendsList {
                HomeScreenToolbar {
                    store.send(.toFriendsList)
                } onCalendar: {
                    store.send(.toCalendar)
                } onSearch: {
                    store.send(.toSearch)
                } onNewNote: {
                    store.send(.createNewNote)
                }
            }
        }
    }
    
    @ViewBuilder
    private func storyView(_ story: Story) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(story.date.toReadable())
                .font(.myItalic(size: 14))
                .foregroundStyle(.textMulticolor.opacity(0.6))
                .padding(.bottom, 36)
                .padding(.leading, 12)
                .padding(.top, 16)
            
            screenBuilder.getComponent(type: .notesList(notes: story.notes, storyID: story.id, isShowDate: false, isShowFriendsList: $isShowFriendsList))
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
