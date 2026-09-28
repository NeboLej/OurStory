//
//  FriendScreen.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import SwiftUI

struct FriendScreen: View {
    
    @State var store: FriendScreenStore
    @State var isEditMode: Bool = false
    @State var name: String = ""
    @State var selectedColor: Color = .red
    
    @State var syncUserIsConfirmet: Bool = false
    @State var showUserSuggestion: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        if isEditMode {
                            editMode()
                        } else {
                            showMode()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                if isEditMode {
                    deleteButton()
                } else {
                    syncButton()
                }
            }
            if !store.syncPgogressStates.isEmpty {
                syncProgressScreen()
                    .transition(.asymmetric(insertion: .offset(x: 10).combined(with: .opacity),
                                            removal: .push(from: .bottom)))
            }
        }
        .animation(.easeInOut, value: store.syncPgogressStates.isEmpty)
        .frame(maxWidth: .infinity)
        .background(.backgroundFill)
        .navigationBarBackButtonHidden(isEditMode)
        .toolbar {
            if isEditMode {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            isEditMode = false
                            name = store.state.friend.name
                            selectedColor = Color(hex: store.state.friend.color)
                        }
                    } label: {
                        Text("ОТМЕНА")
                            .font(.mySemiBold(size: 11))
                            .tracking(1.5)
                            .foregroundStyle(Color.textMulticolor.opacity(0.6))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.textMulticolor.opacity(0.2), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }.sharedBackgroundVisibility(.hidden)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        if isEditMode {
                            store.send(.editFriend(name: name, color: selectedColor.toHex()))
                        }
                        isEditMode.toggle()
                    }
                } label: {
                    Text(isEditMode ? "СОХРАНИТЬ" : "ИЗМЕНИТЬ")
                        .font(.mySemiBold(size: 11))
                        .tracking(1.5)
                        .foregroundStyle(Color.textMulticolor.opacity(0.85))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        
                        .overlay {
                            Rectangle()
                                .stroke(Color.textMulticolor.opacity(0.35), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .opacity(store.state.syncPgogressStates.isEmpty ? 1 : 0)
            }
            .sharedBackgroundVisibility(.hidden)
            
        }
        .onAppear {
            name = store.state.friend.name
            selectedColor = Color(hex: store.state.friend.color)
            showUserSuggestion = false
        }
        .onChange(of: store.syncPgogressStates) {
            if store.syncPgogressStates.last == .completed && store.hasUserProfileDifference {
                showUserSuggestion = true
            }
        }
    }
    
    @ViewBuilder
    private func statisticElement(title: String, value: String, onClick: (() -> Void)?) -> some View {
        Button {
            onClick?()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.mySemiBold(size: 10))
                        .tracking(1.5)
                        .foregroundStyle(.textMulticolor.opacity(0.75))
                    
                    if onClick == nil {
                        Text(value)
                            .font(.myMedium(size: 14))
                            .foregroundStyle(.textMulticolor.opacity(0.5))
                    }
                }
                
                Spacer()
                
                if onClick != nil {
                    Text(value)
                        .font(.mySemiBold(size: 20))
                        .foregroundStyle(.textMulticolor)
                        .padding(.trailing, 8)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.textMulticolor.opacity(0.4))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 4)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.textMulticolor.opacity(0.2))
        }
        .disabled(onClick == nil)
    }
    
    // MARK: - Предложение обновить профиль
    @ViewBuilder
    private func userSuggestionBanner(showCloseButton: Bool = true) -> some View {
        if let user = store.state.friend.user, store.hasUserProfileDifference {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 0) {
                    Text("ПРЕДЛОЖЕНИЕ")
                        .font(.mySemiBold(size: 10))
                        .tracking(1.5)
                        .foregroundStyle(.textMulticolor.opacity(0.5))
                    Spacer()
                    if showCloseButton {
                        Button {
                            withAnimation {
                                showUserSuggestion = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.textMulticolor.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Text("Ваш друг указал другое имя и цвет для своего профиля")
                    .font(.myRegular(size: 13))
                    .foregroundStyle(.textMulticolor.opacity(0.7))
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: user.color))
                            .frame(width: 32, height: 32)
                        Circle()
                            .stroke(Color.backgroundFill, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if user.name != store.state.friend.name {
                            HStack(spacing: 4) {
                                Text(store.state.friend.name)
                                    .font(.myRegular(size: 13))
                                    .foregroundStyle(.textMulticolor.opacity(0.4))
                                    .strikethrough()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.textMulticolor.opacity(0.4))
                                Text(user.name)
                                    .font(.myMedium(size: 14))
                                    .foregroundStyle(.textMulticolor)
                            }
                        }
                        if user.color != store.state.friend.color {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: store.state.friend.color))
                                    .frame(width: 12, height: 12)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.textMulticolor.opacity(0.4))
                                Circle()
                                    .fill(Color(hex: user.color))
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button {
                        withAnimation {
                            store.send(.applyUserProfile)
                            name = user.name
                            selectedColor = Color(hex: user.color)
                            showUserSuggestion = false
                        }
                    } label: {
                        Text("ПРИМЕНИТЬ")
                            .font(.mySemiBold(size: 12))
                            .tracking(1.5)
                            .foregroundStyle(Color.textMulticolor.opacity(0.85))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.textMulticolor.opacity(0.35), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .overlay {
                Rectangle()
                    .stroke(Color.textMulticolor.opacity(0.15), lineWidth: 1)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    // MARK: - Режим Просмотра
    @ViewBuilder
    private func showMode() -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: store.state.friend.color))
                        .frame(width: 48, height: 48)
                    Circle()
                        .stroke(Color.backgroundFill, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
                
                let name: String = {
                    guard let user = store.state.friend.user, user.name != store.state.friend.name else {
                        return store.state.friend.name.uppercased()
                    }
                    return store.state.friend.name.uppercased() + "/" + user.name.uppercased()
                }()
                Text(name)
                    .font(.myMedium(size: 22))
                    .tracking(1)
                    .foregroundColor(.textMulticolor)
            }
            .padding(.top, 32)
            .padding(.bottom, 40)
            
            if showUserSuggestion {
                userSuggestionBanner()
                    .padding(.bottom, 16)
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.textMulticolor.opacity(0.35))
            
            statisticElement(title: "Общих историй", value: "\(store.state.allStoriesCount)") {
                // Действие
            }
            
            statisticElement(title: "Историй не рассказано", value: "\(store.state.notSeenStoriesCount)") {
                // Действие
            }
            
            statisticElement(title: "Последняя синхронизация", value: store.state.lastSyncDate?.toReadableDate() ?? "—", onClick: nil)
        }
    }
    
    @ViewBuilder
    private func syncProgressScreen() -> some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("СИНХРОНИЗАЦИЯ")
                        .font(.myMedium(size: 20))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    ForEach(Array(store.state.syncPgogressStates.enumerated()), id: \.element) { index, event in
                        HStack {
                            Text("\(index + 1). \(event.descriptionText)")
                                .font(.myRegular(size: 16))
                                .foregroundStyle(.black)
                                .padding(8)
                            
                            Spacer()
                        }
                        syncProgressOption(state: event)
                        
                    }
                    .transition(.asymmetric(insertion: .offset(x: 10).combined(with: .opacity), removal: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.4), value: store.state.syncPgogressStates)
                    
                    Spacer()
                }
            }
            
            .frame(maxWidth: .infinity)
            .background(store.syncPgogressStates.count == 0 ? Color.clear : .myPrimary)
        }
        
        if store.state.syncPgogressStates.last == .completed {
            VStack {
                Spacer()
                
                Button {
                    store.send(.exitSync)
                } label: {
                    VStack(spacing: 2) {
                        Text("ЗАКРЫТЬ")
                            .font(.mySemiBold(size: 14))
                            .tracking(2)
                            .foregroundStyle(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.backgroundFill)
                    .overlay {
                        Rectangle()
                            .stroke(Color.black.opacity(0.15), lineWidth: 1)
                            .padding(3)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
            }

        }
    }
    
    @ViewBuilder
    private func syncProgressOption(state: SyncProgressState) -> some View {
        switch state {
        case .waitingForUserConfirmation(let user):
            VStack(alignment: .leading) {
                Text("Вы хотите обменяться историями с пользователем?")
//                    .multilineTextAlignment(.center)
                    .font(.myMedium(size: 16))
                    .foregroundStyle(.black)
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: user.color))
                            .frame(width: 36, height: 36)
                        
                        Circle()
                            .stroke(.myPrimary, lineWidth: 2)
                            .frame(width: 31, height: 31)
                    }
                    Text(user.name)
                        .font(.myMedium(size: 16))
                        .foregroundStyle(.black)
                    Spacer()
                }
                
                HStack {
                    VintageSmallButton(title: "ОТМЕНИТЬ") {
                        store.send(.confirmSyncFriend(false))
                        syncUserIsConfirmet = true
                    }
                    VintageSmallButton(title: "ОБМЕНЯТЬСЯ") {
                        store.send(.confirmSyncFriend(true))
                        syncUserIsConfirmet = true
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .disabled(syncUserIsConfirmet)
            
        case .completed:
            VStack(alignment: .leading) {
                
                Text("Отправлено историй: \(store.state.notSeenStoriesCount)")
                    .font(.myMedium(size: 16))
                    .foregroundStyle(.black)
                HStack {
                    Text("Получено историй:")
                        .font(.myMedium(size: 16))
                        .foregroundStyle(.black)
                    Text(String(store.state.newNotesCount))
                        .font(.myMedium(size: 16))
                        .foregroundStyle(.black)
                }

                HStack { Spacer() }
                if store.state.newNotesCount > 0 {
                    VintageSmallButton(title: "ПОСМОТРЕТЬ") {
                        store.send(.toNewNotes)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
        default: EmptyView()
        }
    }
    
    // MARK: - Режим Редактирования
    @ViewBuilder
    private func editMode() -> some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("РЕДАКТИРОВАТЬ\nПРОФИЛЬ")
                    .font(.mySemiBold(size: 25))
                    .tracking(2)
                    .foregroundColor(.textMulticolor)
                
                VStack(spacing: 4) {
                    Divider().frame(height: 3).background(.textMulticolor)
                    Divider().frame(height: 0.5).background(.textMulticolor)
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("ИМЯ ПОЛЬЗОВАТЕЛЯ")
                    .font(.myMedium(size: 12))
                    .tracking(3)
                    .foregroundColor(.textMulticolor)
                
                TextField("Введите имя...", text: $name)
                    .font(.myItalic(size: 20))
                    .foregroundColor(.textMulticolor)
                    .tint(.textMulticolor)
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "#A39E93"))
                    }
            }
            .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("ЦВЕТОВАЯ МЕТКА")
                    .font(.myMedium(size: 12))
                    .tracking(3)
                    .foregroundColor(.textMulticolor)
                
                CustomColorPicker(selectedColor: $selectedColor)
            }
            
            if store.hasUserProfileDifference {
                userSuggestionBanner(showCloseButton: false)
                    .padding(.top, 24)
            }
        }
    }
    
    // MARK: - Нижние кнопки
    @ViewBuilder
    private func syncButton() -> some View {
        Button {
            store.send(.syncFriend)
        } label: {
            VStack(spacing: 2) {
                Text("ПЕРЕДАТЬ ИСТОРИИ")
                    .font(.mySemiBold(size: 14))
                    .tracking(2)
                    .foregroundStyle(.black)
                
                Text("запустить процесс обмена")
                    .font(.myRegular(size: 10))
                    .opacity(0.6)
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.myPrimary)
            .overlay {
                Rectangle()
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    .padding(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func deleteButton() -> some View {
        Button {
            store.send(.deleteFriend)
            dismiss()
        } label: {
            VStack(spacing: 2) {
                Text("УДАЛИТЬ ДРУГА")
                    .font(.mySemiBold(size: 14))
                    .tracking(2)
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.7))
            .overlay {
                Rectangle()
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    .padding(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .buttonStyle(.plain)
    }
}


#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .friend(Friend(name: "София", color: "F16C6C")))
    }
}
