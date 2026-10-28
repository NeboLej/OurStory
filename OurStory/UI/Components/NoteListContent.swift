//
//  NoteListContent.swift
//  OurStory
//
//  Created by Nebo on 30.09.2026.
//

import SwiftUI

struct NoteListContent: View {
    
    @State var store: NoteListScreenStore
    @Binding var isShowFriendsList: Bool
    @State private var isShowNewFriend = false
    var isShowDate: Bool
    
    var body: some View {
        noteList
            .overlay {
                if isShowFriendsList {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                isShowFriendsList = false
                            }
                        }
                }
            }
            .overlay(alignment: .bottom) {
                friendsListOverlay
            }
    }
    
    private var noteList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(store.state.groupedNotes, id: \.date) { group in
                    if isShowDate {
                        Text(group.date.toReadable())
                            .font(.myMedium(size: 14))
                            .foregroundStyle(.textMulticolor.opacity(0.5))
                            .padding(.top, 20)
                            .padding(.bottom, 4)
                            .padding(.leading, 4)
                    }
                    
                    ForEach(group.notes, id: \.id) { note in
                        noteView(note)
                            .padding(.vertical, 10)
                            .animatedSelectionBorder(isSelected: store.showMenuNote == note || store.showFriendsNote == note)
                    }
                }
                HStack { Spacer() }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.snappy) {
                    store.send(.selectMenuNote(nil))
                    store.send(.selectFriendsNote(nil))
                }
            }
            .padding(.bottom, 200)
        }
        .scrollIndicators(.hidden)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.snappy) {
                store.send(.selectMenuNote(nil))
                store.send(.selectFriendsNote(nil))
            }
        }
        
        .padding(.horizontal, 12)
        .onChange(of: store.showMenuNote?.id) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.snappy) {
                    store.send(.selectFriendsNote(nil))
                    isShowFriendsList = false
                }
            } else {
                isShowFriendsList = false
            }
        }
        .onChange(of: store.showFriendsNote) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.snappy) {
                    store.send(.selectMenuNote(nil))
                }
            }
        }
    }
    
    @ViewBuilder
    var friendsListOverlay: some View {
        if isShowFriendsList, let note = store.showMenuNote {
            FriendsListModalView(allFriends: store.state.allFriends, selectedFriends: store.showMenuNote?.friends ?? []) { friend in
                store.send(.updateFriendInNote(note: note, friend: friend))
            } onAddFriend: {
                isShowFriendsList = false
                store.send(.addNewFriend)
            } onExit: {
                isShowFriendsList = false
            }
            .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Note Views
    
    @ViewBuilder
    private func noteView(_ note: Note) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if note.owner == nil {
                HStack(alignment: .top, spacing: 0) {
                    Button {
                        withAnimation(.snappy) {
                            store.send(.selectFriendsNote(note))
                        }
                    } label: {
                        friendsIndicatorView(note.friends)
                            .transition(.scale(scale: 0.1).combined(with: .opacity))
                            .frame(width: store.showFriendsNote == note ? 0 : store.showMenuNote == note ? 4 : 16)
                            .padding(.vertical, store.showMenuNote == note ? 8 : 0)
                    }
                    
                    if store.showMenuNote != note {
                        Button {
                            withAnimation(.snappy) {
                                store.send(.selectFriendsNote(note))
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
                                                    store.send(.selectFriendsNote(nil))
                                                }
                                            }
                                    }
                                }
                            }
                        }.disabled(note.friends.isEmpty)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        if let noteTitle = note.title, !noteTitle.isEmpty {
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
                                store.send(.selectMenuNote(nil))
                            } else {
                                store.send(.selectMenuNote(note.id))
                            }
                        }
                    }
                    
                }
            } else {
                friendNoteView(note)
            }
            
            if store.showMenuNote == note {
                noteMenu(note: note)
                    .frame(maxWidth: 160)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            }
        }
    }
    
    @ViewBuilder
    private func noteMenu(note: Note) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.black.opacity(0.2))
            VStack(alignment: .trailing, spacing: 12) {
                if note.owner == nil {
                    noteMenuItem(image: "pencil.and.scribble", text: "Редактировать", action: {
                        store.send(.editNote(note))
                    })
                    noteMenuItem(image: "person.badge.plus", text: "Отметить друга", action: {
                        withAnimation(.snappy) {
                            isShowFriendsList.toggle()
                        }
                    })
                }
                noteMenuItem(image: "trash", text: "Удалить", action: {
                    store.send(.deleteNote(note))
                })
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
                        store.send(.selectFriendsNote(nil))
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
//            .frame(width: 16)
    }
    
    private func friendNoteView(_ note: Note) -> some View {
        HStack(alignment: .top, spacing: 0) {
            let isSelected = store.showMenuNote == note
            WavyLine(amplitude: isSelected ? 0 : 6, wavelength: isSelected ? 100 : 20)
                .stroke(Color(hex: note.owner?.color ?? ""), lineWidth: 2)
                .frame(width: isSelected ? 2 : 16)
                .padding(.leading, isSelected ? 1 : 6)
                .padding(.bottom, 18)
            
            VStack(alignment: .leading, spacing: 0) {
                if let noteTitle = note.title {
                    Text(noteTitle)
                        .font(.mySemiBold(size: 16))
                        .foregroundStyle(.textMulticolor)
                }
                
                Text(note.text)
                    .font(.myRegular(size: 16))
                    .foregroundStyle(.textMulticolor)
                    .padding(.top, 2)
                
                HStack(alignment: .center, spacing: 3) {
                    Spacer()
                    Circle()
                        .fill(Color(hex: note.owner?.color ?? ""))
                        .frame(width: 16)
                        .overlay {
                            Circle()
                                .stroke(.textMulticolor, lineWidth: 1)
                        }
                    Text("\(note.owner?.name ?? "")")
                        .font(.myRegular(size: 14))
                        .foregroundStyle(.textMulticolor.opacity(0.6))
                        .padding(.horizontal, 4)
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 8)
        }
        .padding([.top, .bottom, .trailing], 8)
        .overlay {
            if store.showMenuNote != note {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.textMulticolor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            withAnimation(.snappy) {
                if store.showMenuNote == note {
                    store.send(.selectMenuNote(nil))
                } else {
                    store.send(.selectMenuNote(note.id))
                }
            }
        }
    }
}

#Preview {

   
    NavigationStack {
//        ScreenBuilder.previewBuilder.getScreen(type: .home)
        ScreenBuilder.previewBuilder.getScreen(type: .notes(title: "ffff1", notes: tmpNotes, isShowFriendsList: .init(get: { true }, set: { _ in
            
        })))
    }

}
