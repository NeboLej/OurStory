//
//  SettingScreen.swift
//  OurStory
//
//  Created by Nebo on 22.09.2026.
//

import SwiftUI


struct SettingScreen: View {
    
    @State private var store: SettingScreenStore
    @Environment(\.dismiss) var dismiss
    
    init(store: SettingScreenStore) {
        self.store = store
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundFill)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Шапка профиля
                profileHeader()
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.textMulticolor.opacity(0.35))
                    .padding(.horizontal, 20)
                
                // MARK: - Список настроек
                settingsList()
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Шапка профиля
    @ViewBuilder
    private func profileHeader() -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: store.state.user.color))
                    .frame(width: 64, height: 64)
                Circle()
                    .stroke(Color.backgroundFill, lineWidth: 3)
                    .frame(width: 58, height: 58)
            }
            
            Text(store.state.user.name.uppercased())
                .font(.myMedium(size: 22))
                .tracking(1)
                .foregroundColor(.textMulticolor)
            
            Button {
                store.send(.toEditProfile)
            } label: {
                Text("ИЗМЕНИТЬ")
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
        .padding(.top, 32)
        .padding(.bottom, 28)
    }
    
    // MARK: - Список настроек
    @ViewBuilder
    private func settingsList() -> some View {
        VStack(spacing: 0) {
            settingsRow(icon: "paintbrush", title: "Тема") {
                // Заглушка
            }
            
            settingsRow(icon: "globe", title: "Язык") {
                // Заглушка
            }
            
            settingsRow(icon: "bell", title: "Уведомления") {
                // Заглушка
            }
            
            settingsRow(icon: "icloud.and.arrow.down", title: "Синхронизация iCloud") {
                store.send(.syncFromCloud)
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.textMulticolor.opacity(0.7))
                    .frame(width: 24)
                
                Text(title)
                    .font(.myMedium(size: 16))
                    .foregroundStyle(.textMulticolor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.textMulticolor.opacity(0.4))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.textMulticolor.opacity(0.2))
        }
    }
}

#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .setting)
    }
}
