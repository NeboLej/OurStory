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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            if isEditMode {
                editMode()
            } else {
                showMode()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
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
            }.sharedBackgroundVisibility(.hidden)
        }
        .onAppear {
            name = store.state.friend.name
            selectedColor = Color(hex: store.state.friend.color)
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
                
                Text(store.state.friend.name.uppercased())
                    .font(.myMedium(size: 22))
                    .tracking(1)
                    .foregroundColor(.textMulticolor)
            }
            .padding(.top, 32)
            .padding(.bottom, 40)
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.textMulticolor.opacity(0.35))
            
            statisticElement(title: "Общих историй", value: "\(store.state.allStoriesCount)") {
                // Действие
            }
            
            statisticElement(title: "Историй не рассказано", value: "\(store.state.notSeenStoriesCount)") {
                // Действие
            }
            
            statisticElement(title: "Последняя синхронизация", value: "\(Date().toReadableDate())", onClick: nil)
            
            Spacer()
            
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
            .padding(.bottom, 16)
            .buttonStyle(.plain)
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
            
            Spacer()
            
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
            .buttonStyle(.plain)
            
        }
    }
}


#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .friend(Friend(name: "София", color: "F16C6C")))
    }
}
