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
    @State private var selectionDate: Date = .now
    @State private var showFrinedsNote: Note? = nil
    @State private var showMenuNote: Note? = nil
    @State private var isShowFriendsList: Bool = false
    
    init(store: HomeScreenStore, screenBuilder: ScreenBuilder) {
        self.store = store
        self.screenBuilder = screenBuilder
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .frame(height: 100)
                .foregroundStyle(Color.myPrimary)
            screenBuilder.getComponent(type: .horizontalCalendar)
                .padding(.top, 16)
            
            ScrollView(.vertical) {
                
                if let currentSroty = store.state.currentStory {
                    storyView(currentSroty)
                }
                
            }
            .frame(maxWidth: .infinity)
        }
        
        .background(.backgroundFill)
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                
                if isShowFriendsList {
                    if let note = showMenuNote {
                        FriendsListModalView(allFriends: store.state.allFriends, selectedFriends: note.friends) { friend in
                            print(friend.name)
                        }.padding(.horizontal)
                    }

                } else {
                    HomeScreenToolbar {
                       
                    } onCalendar: {
                        
                    } onNewNote: {
                        store.send(.createNewNote)
                    }
                }
            }
        }
        .onChange(of: showMenuNote) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.snappy) {
                    showFrinedsNote = nil
                }
            }
        }
        .onChange(of: showFrinedsNote) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.snappy) {
                    showMenuNote = nil
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
                    .foregroundStyle(.titleDark)
                    .padding(.bottom, 4)
                    .padding(.top, 20)
                Text(story.date.toReadable())
                    .font(.myItalic(size: 14))
                    .foregroundStyle(.titleDark.opacity(0.6))
                    .padding(.bottom, 36)
            }
            .padding(.leading, 30)
            
            ForEach(story.notes) { note in
                noteView(note)
                    .padding(.vertical, 10)
                    .animatedSelectionBorder(isSelected: showMenuNote == note || showFrinedsNote == note)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 100)
    }
    
    @ViewBuilder
    private func noteView(_ note: Note) -> some View {
        if note.owner == nil {
            
            HStack(alignment: .top) {
                if showMenuNote != note {
                    Button {
                        withAnimation(.snappy) {
                            showFrinedsNote = note
                        }
                    } label: {
                        Group {
                            if showFrinedsNote == note {
                                VStack {
                                    friendsList(friends: note.friends)
                                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                                    Rectangle()
                                        .opacity(0.001)
                                        .onTapGesture {
                                            withAnimation(.snappy) {
                                                showFrinedsNote = nil
                                            }
                                        }
                                }
                            } else {
                                friendsIndicatorView(note.friends)
                                    .transition(.scale(scale: 0.1).combined(with: .opacity))
                            }
                        }
                    }.disabled(note.friends.isEmpty)
                }
                VStack(alignment: .leading, spacing: 0) {
                    if let noteTitle = note.title {
                        Text(noteTitle)
                            .font(.mySemiBold(size: 16))
                            .foregroundStyle(.titleDark)
                            .padding(.bottom, 4)
                    }
                    
                    Text(note.text)
                        .font(.myRegular(size: 16))
                        .foregroundStyle(.titleDark)
                }
                .padding(.horizontal, 16)
                .onTapGesture {
                    withAnimation(.snappy) {
                        if showMenuNote == note {
                            showMenuNote = nil
                        } else {
                            showMenuNote = note
                        }
                    }
                }
                
                if showMenuNote == note {
                    noteMenu(note: note)
                        .transition(.scale(scale: 0.1).combined(with: .opacity))
                }
            }
        } else {
            friendNoteView(note)
        }
        
    }
    
    @ViewBuilder
    private func noteMenu(note: Note) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.black.opacity(0.2))
            VStack(spacing: 12) {
                noteMenuItem(image: "pencil.and.scribble", text: "Редактировать", action: {})
                noteMenuItem(image: "person.badge.plus", text: "Отметить друга", action: {
                    withAnimation(.snappy) {
                        isShowFriendsList.toggle()
                    }
                })
                noteMenuItem(image: "trash", text: "Удалить", action: {})
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func noteMenuItem(image: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Image(systemName: image)
                    .foregroundStyle(.titleDark.opacity(0.5))
                    .font(.system(size: 13))
                    .frame(width: 40)
                Text(text)
                    .foregroundStyle(.titleDark)
                    .font(.myMedium(size: 13))
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func friendsList(friends: [Friend]) -> some View {
        VStack(spacing: 0) {
            ForEach(friends) { friend in
                Button {
                    withAnimation(.snappy) {
                        showFrinedsNote = nil
                    }
                } label: {
                    HStack {
                        Circle()
                            .foregroundStyle(Color(hex: friend.color))
                            .frame(height: 20)
                        Text(friend.name)
                            .font(.myRegular(size: 14))
                            .foregroundStyle(.titleDark)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func friendsIndicatorView(_ friends: [Friend]) -> some View {
        let colors = friends.map {  Color(hex: $0.color) }
        Rectangle()
            .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            .frame(width: 16)
    }
    
    
    private func friendNoteView(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let noteTitle = note.title {
                Text(noteTitle)
                    .font(.mySemiBoldItalic(size: 16))
                    .foregroundStyle(.titleDark)
            }
            
            Text(note.text)
                .font(.myItalic(size: 16))
                .foregroundStyle(.titleDark)
                .padding(.top, 2)
            
            HStack(alignment: .center, spacing: 3) {
                Spacer()
                Circle()
                    .fill(Color(hex: note.owner?.color ?? ""))
                    .frame(width: 16)
                    .overlay {
                        Circle()
                            .stroke(.black, lineWidth: 0.5)
                    }
                Text("\(note.owner?.name ?? "")")
                    .font(.myRegular(size: 14))
                    .foregroundStyle(.titleDark.opacity(0.6))
            }
            .padding(.top, 2)
        }
        .padding(.leading, 30)
        .padding([.top, .bottom, .trailing], 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.black, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        )
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .home)
}
