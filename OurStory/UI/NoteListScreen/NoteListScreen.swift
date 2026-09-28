//
//  NoteListScreen.swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import SwiftUI

struct NoteListScreen: View {
    
    @State var title: String?
    @State var store: NoteListScreenStore
    
    init(title: String?, store: NoteListScreenStore) {
        self.store = store
        self.title = title
    }
    
    var body: some View {
        ScrollView(.vertical) {
            noteListContent
                .padding(.bottom, 80)
        }
        .background(.backgroundFill)
        .navigationTitle(title ?? "Истории")
        .navigationBarTitleDisplayMode(.automatic)
        .onChange(of: store.showMenuNote?.id) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.snappy) {
                    store.showFriendsNote = nil
                    store.isShowFriendsList = false
                }
            } else {
                store.isShowFriendsList = false
            }
        }
        .onChange(of: store.showFriendsNote) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.snappy) {
                    store.showMenuNoteId = nil
                }
            }
        }
    }
    
    // MARK: - Public content for embedding
    
    var noteListContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.state.notes, id: \.id) { note in
                noteView(note)
                    .padding(.vertical, 10)
                    .animatedSelectionBorder(isSelected: store.showMenuNote == note || store.showFriendsNote == note)
            }
            HStack { Spacer() }
        }
        .padding(.horizontal, 12)
        .onChange(of: store.showMenuNote?.id) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.snappy) {
                    store.showFriendsNote = nil
                    store.isShowFriendsList = false
                }
            } else {
                store.isShowFriendsList = false
            }
        }
        .onChange(of: store.showFriendsNote) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.snappy) {
                    store.showMenuNoteId = nil
                }
            }
        }
    }
    
    @ViewBuilder
    var friendsListOverlay: some View {
        if store.isShowFriendsList, let note = store.showMenuNote {
            FriendsListModalView(allFriends: store.state.allFriends, selectedFriends: store.showMenuNote?.friends ?? []) { friend in
                store.send(.updateFriendInNote(note: note, friend: friend))
            } onExit: {
                store.isShowFriendsList = false
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Note Views
    
    @ViewBuilder
    private func noteView(_ note: Note) -> some View {
        if note.owner == nil {
            HStack(alignment: .top, spacing: 0) {
                if store.showMenuNote != note {
                    Button {
                        withAnimation(.snappy) {
                            store.showFriendsNote = note
                        }
                    } label: {
                        Group {
                            if store.showFriendsNote == note {
                                VStack {
                                    friendsList(friends: note.friends)
                                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                                    Rectangle()
                                        .opacity(0.001)
                                        .onTapGesture {
                                            withAnimation(.snappy) {
                                                store.showFriendsNote = nil
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
                            .foregroundStyle(.textMulticolor)
                            .padding(.bottom, 4)
                    }
                    
                    Text(note.text)
                        .font(.myRegular(size: 16))
                        .foregroundStyle(.textMulticolor)
                }
                .padding(.horizontal, 16)
                .onTapGesture {
                    withAnimation(.snappy) {
                        if store.showMenuNote == note {
                            store.showMenuNoteId = nil
                        } else {
                            store.showMenuNoteId = note.id
                        }
                    }
                }
                
                if store.showMenuNote == note {
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
            VStack(alignment: .trailing, spacing: 12) {
                noteMenuItem(image: "pencil.and.scribble", text: "Редактировать", action: {
                    store.send(.editNote(note))
                })
                noteMenuItem(image: "person.badge.plus", text: "Отметить друга", action: {
                    withAnimation(.snappy) {
                        store.isShowFriendsList.toggle()
                    }
                })
                noteMenuItem(image: "trash", text: "Удалить", action: {})
                Spacer()
                Text(note.date.toHourMinuteDate())
                    .font(.myItalic(size: 12))
                    .foregroundStyle(.textMulticolor.opacity(0.5))
                    .padding(.trailing, 12)
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
                    .foregroundStyle(.textMulticolor.opacity(0.5))
                    .font(.system(size: 13))
                    .frame(width: 40)
                Text(text)
                    .foregroundStyle(.textMulticolor)
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
                        store.showFriendsNote = nil
                    }
                } label: {
                    HStack {
                        Circle()
                            .foregroundStyle(Color(hex: friend.color))
                            .frame(height: 20)
                        Text(friend.name)
                            .font(.myRegular(size: 14))
                            .foregroundStyle(.textMulticolor)
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
        let colors = friends.map { Color(hex: $0.color) }
        Rectangle()
            .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            .frame(width: 16)
    }
    
    private func friendNoteView(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let noteTitle = note.title {
                Text(noteTitle)
                    .font(.mySemiBoldItalic(size: 16))
                    .foregroundStyle(.textMulticolor)
            }
            
            Text(note.text)
                .font(.myItalic(size: 16))
                .foregroundStyle(.textMulticolor)
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
                    .foregroundStyle(.textMulticolor.opacity(0.6))
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
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .notes(title: "Notes", notes: []))
    }
}
