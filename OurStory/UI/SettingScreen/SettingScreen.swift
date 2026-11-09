//
//  SettingScreen.swift
//  OurStory
//
//  Created by Nebo on 22.09.2026.
//

import SwiftUI


struct SettingScreen: View {
    
    @State private var store: SettingScreenStore
    @State private var isThemeExpanded = false
    @State private var isLanguageExpanded = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ThemeManager.self) private var themeManager
    
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
        .navigationTitle(L10n.settings)
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
                Text(L10n.edit)
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
            
            languageSection()
            
            themeSection()
            
            settingsRow(icon: "bell", title: L10n.notifications) {
                store.send(.toNotificationSettings)
            }
            
            settingsRow(icon: "icloud.and.arrow.down", title: L10n.icloudSync) {
                store.send(.syncFromCloud)
            }
            
            settingsRow(icon: "questionmark.circle", title: L10n.help) {
                store.send(.toHelpListScreen)
            }
            
            settingsRow(icon: "note", title: L10n.logs) {
                store.send(.toLogScreen)
            }
            
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Секция языка
    @ViewBuilder
    private func languageSection() -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isLanguageExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.textMulticolor.opacity(0.7))
                        .frame(width: 24)
                    
                    Text(L10n.languageLabel)
                        .font(.myMedium(size: 16))
                        .foregroundStyle(.textMulticolor)
                    
                    Spacer()
                    
                    Text(LocaleManager.shared.currentLanguage.title)
                        .font(.myRegular(size: 14))
                        .foregroundStyle(.textMulticolor.opacity(0.5))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.textMulticolor.opacity(0.4))
                        .rotationEffect(.degrees(isLanguageExpanded ? 90 : 0))
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isLanguageExpanded {
                languagePicker()
            }
        }
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.textMulticolor.opacity(0.2))
        }
    }
    
    @ViewBuilder
    private func languagePicker() -> some View {
        VStack(spacing: 0) {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                let isSelected = LocaleManager.shared.currentLanguage == language
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        LocaleManager.shared.currentLanguage = language
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text(language.title)
                            .font(.myMedium(size: 15))
                            .foregroundStyle(.textMulticolor)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.myPrimary)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                    .padding(.leading, 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Секция темы
    @ViewBuilder
    private func themeSection() -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isThemeExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "paintbrush")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.textMulticolor.opacity(0.7))
                        .frame(width: 24)
                    
                    Text(L10n.theme)
                        .font(.myMedium(size: 16))
                        .foregroundStyle(.textMulticolor)
                    
                    Spacer()
                    
                    Text(themeManager.currentTheme.title)
                        .font(.myRegular(size: 14))
                        .foregroundStyle(.textMulticolor.opacity(0.5))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.textMulticolor.opacity(0.4))
                        .rotationEffect(.degrees(isThemeExpanded ? 90 : 0))
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isThemeExpanded {
                themePicker()
            }
        }
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.textMulticolor.opacity(0.2))
        }
    }
    
    @ViewBuilder
    private func themePicker() -> some View {
        HStack(spacing: 0) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                let isSelected = themeManager.currentTheme == theme
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        themeManager.currentTheme = theme
                    }
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.backgroundFill))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? Color.textMulticolor : Color.textMulticolor.opacity(0.2),
                                                lineWidth: isSelected ? 2 : 1
                                        )
                                }
                            
                            Image(systemName: theme.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.myPrimary)
                        }
                        .environment(\.colorScheme, theme == .dark ? .dark : theme == .light ? .light : colorScheme)
                        
                        Text(theme.title)
                            .font(.myMedium(size: 12))
                            .foregroundStyle(
                                isSelected ? .textMulticolor : .textMulticolor.opacity(0.5)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
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
            .contentShape(Rectangle())
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
