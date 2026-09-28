//
//  EditProfileScreen.swift
//  OurStory
//
//  Created by Nebo on 28.09.2026.
//

import SwiftUI

struct EditProfileScreen: View {
    
    @State private var store: SettingScreenStore
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    @Environment(\.dismiss) var dismiss
    
    init(store: SettingScreenStore) {
        self.store = store
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundFill)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
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
                    Text("МОЕ ИМЯ")
                        .font(.myMedium(size: 12))
                        .tracking(3)
                        .foregroundColor(.textMulticolor)
                    
                    TextField("Введите ваше имя...", text: $name)
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
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .background(.backgroundFill)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
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
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.saveUser(name: name, color: selectedColor.toHex()))
                    dismiss()
                } label: {
                    Text("СОХРАНИТЬ")
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
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            name = store.state.user.name
            selectedColor = Color(hex: store.state.user.color)
        }
    }
}

#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .editProfile)
    }
}
