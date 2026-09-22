//
//  SettingScreen.swift
//  OurStory
//
//  Created by Nebo on 22.09.2026.
//

import SwiftUI


struct SettingScreen: View {
    
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
            ScrollView(.vertical) {
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: store.state.user.color))
                            .frame(width: 48, height: 48)
                        Circle()
                            .stroke(Color.backgroundFill, lineWidth: 2)
                            .frame(width: 44, height: 44)
                    }
                    
                    nameRow()
                        .padding(.top, 24)
                    colorPickerRow()
                    Spacer()
                    
                    Button {
                        store.send(.saveUser(name: name, color: selectedColor.toHex()))
                        dismiss()
                    } label: {
                        Text("Сохранить")
                            .foregroundStyle(.titleDark)
                            .font(.myMedium(size: 18))
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                    .tint(.myPrimary)
                    .buttonStyle(.glassProminent)
                    .padding(.top, 64)

                }
                .padding(.horizontal, 16)
                
            }
            
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            name = store.state.user.name
            selectedColor = Color(hex: store.state.user.color)
        }
    }
    
    
    @ViewBuilder
    private func nameRow() -> some View {
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
    }
    
    @ViewBuilder
    private func colorPickerRow() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ЦВЕТОВАЯ МЕТКА")
                .font(.myMedium(size: 12))
                .tracking(3)
                .foregroundColor(.textMulticolor)
            
            CustomColorPicker(selectedColor: $selectedColor)
        }
    }
}

#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .setting)
    }
}
