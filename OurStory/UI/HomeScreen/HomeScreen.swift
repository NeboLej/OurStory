//
//  HomeScreen.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI
import Lottie

struct HomeScreen: View {
    
    @Environment(LocaleManager.self) private var localeManager
    @State private var store: HomeScreenStore
    @State private var screenBuilder: ScreenBuilder
    @State private var isShowFriendsList: Bool = false
    @State private var notesTransitionEdge: Edge?
    
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
                .stringSwipeExcluded()
//                .frame(height: 120)
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
            
            if !store.state.selectedNotes.isEmpty {
                notesView(date: store.state.selectedDate)
                    .transition(notesTransition)
//                    .id(store.state.selectedNotes)
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
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.2), value: store.state.selectedDate)
                            
                            Text(store.state.selectedDate.toMonth())
                                .font(.myRegular(size: 14))
                                .foregroundStyle(.myPrimary)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.2), value: store.state.selectedDate)
                        }
                        .padding(.trailing, 12)
                        .padding(.top, 20)
                    }
                    .padding(.leading, 12)
                
                    Text(store.state.emptyStateText)
                        .font(.myRegular(size: 16))
                        .foregroundStyle(.textMulticolor.opacity(0.6))
                        .padding(.bottom, 36)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.bottom, 80)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 42)
                .transition(.opacity.animation(.easeOut(duration: 0.15)))
            }
        }
        .background(.backgroundFill)
        .ignoresSafeArea()
        .stringSwipe(edges: .horizontal) { edge in
            // The outgoing view keeps the transition from its last render,
            // so apply the edge first and change the date on the next run loop.
            notesTransitionEdge = edge
            Task { @MainActor in
                store.send(.swipeDate(days: edge == .trailing ? 1 : -1))
            }
        }
        .onChange(of: store.state.selectedDate) {
            notesTransitionEdge = nil
        }
        .onChange(of: localeManager.currentLanguage) {
            store.clearEmptyTextCache()
        }
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
    private func notesView(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(date.toReadable())
                .font(.myItalic(size: 14))
                .foregroundStyle(.textMulticolor.opacity(0.6))
                .padding(.bottom, 20)
                .padding(.leading, 12)
                .padding(.top, 16)
            
            ZStack {
                screenBuilder.getComponent(type: .notesList(filter: .byDate(BaseDate(date: date)), isShowDate: false, isShowFriendsList: $isShowFriendsList))
                    .id(date)
                    .transition(notesTransition)
            }
        }
        .padding(.bottom, 80)
    }

    private var notesTransition: AnyTransition {
        guard let edge = notesTransitionEdge else { return .opacity }
        let opposite: Edge = switch edge {
        case .leading: .trailing
        case .trailing: .leading
        case .top: .bottom
        case .bottom: .top
        }
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: opposite).combined(with: .opacity)
        )
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .home)
        .environment(LocaleManager.shared)
        .environment(ThemeManager.shared)
}
