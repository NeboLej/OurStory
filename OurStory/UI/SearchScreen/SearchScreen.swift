//
//  SearchScreen.swift
//  OurStory
//

import SwiftUI
import Lottie

struct SearchScreen: View {
    
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    @State private var store: SearchScreenStore
    @State private var screenBuilder: ScreenBuilder
    @State private var isShowFriendsList = false
    @State private var keyboardHeight: CGFloat = 0
    
    private var playback: LottiePlaybackMode {
        if searchText.count < 3 {
            .playing(.marker("idle", loopMode: .loop))
        } else if store.state.notes.isEmpty {
            .playing(.marker("not_found", loopMode: .loop))
        } else {
            .playing(.marker("", loopMode: .loop))
        }
    }
    
    init(store: SearchScreenStore, screenBuilder: ScreenBuilder) {
        self.store = store
        self.screenBuilder = screenBuilder
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            screenBuilder.getComponent(type: .notesList(notes: store.state.notes, storyID: UUID(), isShowDate: true, isShowFriendsList: $isShowFriendsList))
                .id(store.state.notes)
                .onScrollPhaseChange { _, newPhase in
                    if newPhase == .interacting {
                        isSearchFocused = false
                    }
                }.overlay(alignment: .top) {
                    if store.state.notes.isEmpty {
                        LottieView(animation: .named("search_empty"))
                            .resizable()
                            .playbackMode(playback)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: 180)
                            .padding(.top, 70)
                    }
                }
            //от слйчайных нажатий во круг searchBar
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 20)
                    .contentShape(Rectangle())
                    .onTapGesture { }
                
                searchBar
            }
            .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - bottomSafeArea : 0)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
        .background(.backgroundFill)
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Поиск")
        .toolbarBackground(.backgroundFill, for: .navigationBar)
        .onAppear {
            withAnimation {
                isSearchFocused = true
            }
        }
        .onChange(of: searchText) { _, newValue in
            store.send(.search(newValue))
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }
    
    private var bottomSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.textMulticolor.opacity(0.5))
                    .font(.system(size: 16))
                
                TextField("Поиск историй", text: $searchText)
                    .font(.myRegular(size: 16))
                    .foregroundStyle(.textMulticolor)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.textMulticolor.opacity(0.4))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .glassEffect(in: .rect(cornerRadius: 24))
            
            Button {
                store.send(.close)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.textMulticolor)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glass)
            .clipShape(Circle())
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
//        .background(.backgroundFill)
    }
}

#Preview {
//    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .search)
//    }
    
}
