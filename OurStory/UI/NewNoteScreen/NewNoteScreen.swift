//
//  NewNoteScreen.swift
//  OurStory
//
//  Created by Nebo on 01.09.2026.
//

import SwiftUI

struct NewNoteScreen: View {
    
    @State private var store: NewNoteScreenStore
    
    @State private var title = ""
    @State private var story = ""
    
    @State private var selectedDate = Date()
    @State private var isShowCalendar = false
    @State private var isShowFriendsList = false
    
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?
    
    init(store: NewNoteScreenStore) {
        self.store = store
    }
    
    enum Field {
        case title
        case story
    }
    
    private var canSave: Bool {
        !story.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(Color.backgroundFill)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header()
                
                Divider()
                    .overlay(Color.textMulticolor.opacity(0.15))
                
                friendsIndicatorView(store.state.selectedFriends)
                
                titleTextField()
                storyTextEditor()
                
                Spacer(minLength: 0)
            }.padding(.horizontal, 24)
                .onChange(of: focusedField) { oldValue, newValue in
                    if newValue != nil {
                        withAnimation {
                            isShowCalendar = false
                            isShowFriendsList = false
                        }
                    }
                }
                .onChange(of: isShowCalendar) { oldValue, newValue in
                    if isShowCalendar {
                        withAnimation {
                            focusedField = nil
                            isShowFriendsList = false
                        }
                    }
                }
                .onChange(of: isShowFriendsList) { oldValue, newValue in
                    if isShowFriendsList {
                        withAnimation {
                            focusedField = nil
                            isShowCalendar = false
                        }
                    }
                }
        }
        .onAppear {
            focusedField = .story
        }
    }
    
    
    @ViewBuilder
    private func header() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("НОВАЯ ИСТОРИЯ")
                    .font(.mySemiBold(size: 14))
                    .tracking(2)
                    .foregroundStyle(.textMulticolor)
                Text(store.state.date.toReadableDate())
                    .font(.myRegular(size: 12))
                    .tracking(2)
                    .foregroundStyle(.textMulticolor.opacity(0.7))
            }
            
            Spacer()
            
            Button {
                saveStory()
            } label: {
                Text("СОХРАНИТЬ")
                    .font(.mySemiBold(size: 11))
                    .tracking(1.5)
                    .foregroundStyle(canSave ? Color.textMulticolor.opacity(0.85) : Color.textMulticolor.opacity(0.25))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(canSave ? Color.textMulticolor.opacity(0.35) : Color.textMulticolor.opacity(0.12), lineWidth: 1)
                    }
            }
            .disabled(!canSave)
        }
        .padding(.top, 18)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func titleTextField() -> some View {
        HStack {
            TextField("", text: $title,
                      prompt: Text("Название итории")
                .font(.myRegular(size: 17))
                .foregroundStyle(.textMulticolor.opacity(0.32)), axis: .vertical)
            .lineLimit(1...4)
            .foregroundStyle(.textMulticolor.opacity(0.88))
            .focused($focusedField, equals: .title)
            .font(.myMedium(size: 20))
            .submitLabel(.next)
            .onSubmit {
                focusedField = .story
            }
            .padding(.top, 28)
            .padding(.bottom, 18)
            
            if title.isEmpty {
                Image(systemName: "pencil.and.scribble")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.textMulticolor.opacity(0.32))
                    .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func friendsIndicatorView(_ friends: [Friend]) -> some View {
        let colors = friends.map {  Color(hex: $0.color) }
        Rectangle()
            .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
            .frame(height: 16)
    }
    
    @ViewBuilder
    private func storyTextEditor() -> some View {
        HStack {
            Text("ТЕКСТ")
                .font(.mySemiBold(size: 11))
                .tracking(2)
                .foregroundStyle(.textMulticolor)
            
            Spacer()
            
            if !story.isEmpty {
                Text("\(story.count) знаков")
                    .font(.myRegular(size: 14))
                    .foregroundStyle(.textMulticolor)
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 8)
        
        
        TextEditor(text: $story)
            .font(.myMedium(size: 16))
            .scrollContentBackground(.hidden)
            .foregroundStyle(.textMulticolor.opacity(0.7))
            .focused($focusedField, equals: .story)
        //            .focused($isTextEditorFocused)
            .overlay(alignment: .topLeading) {
                if story.isEmpty {
                    Text("Начните писать свою историю...")
                        .font(.myRegular(size: 17))
                        .foregroundStyle(.textMulticolor.opacity(0.32))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(.leading, -5)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                
                VStack(spacing: 8) {
                    if isShowCalendar {
                        DatePicker("",selection: $selectedDate, displayedComponents: [.date , .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .padding(12)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .transition(.scale(scale: 0.75).combined(with: .opacity))
                            .onChange(of: selectedDate) { oldValue, newValue in
                                store.send(.selectDate(newValue))
                            }
                    } else if isShowFriendsList {
                        FriendsListModalView(allFriends: store.state.allFriends, selectedFriends: store.state.selectedFriends) { friend in
                            store.send(.selectFriend(friend))
                        }
                    }
                    
                    NewNoteToolbar(
                        circleColors: store.state.selectedFriends.map { Color(hex: $0.color) },
                        onAddFriend: {
                            withAnimation(.spring(response: 0.3)) {
                                isShowFriendsList.toggle()
                            }
                        },
                        onCalendar: {
                            withAnimation(.spring(response: 0.3)) {
                                isShowCalendar.toggle()
                            }
                        }
                    )
                }
            }
    }
    
    private func saveStory() {
        guard canSave else { return }
        
        print("Saving story")
        print("Title: \(title)")
        print("Story: \(story)")
        
        store.send(.saveNote(title: title, text: story))
        focusedField = nil
        dismiss()
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .createNote)
}
