//
//  NotificationScreen.swift
//  OurStory
//

import SwiftUI

struct NotificationScreen: View {
    
    @State private var store: NotificationScreenStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    init(store: NotificationScreenStore) {
        self.store = store
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundFill)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if store.state.isSystemDenied {
                    deniedBanner()
                        .padding(.horizontal, 12)
                        .padding(.top, 20)
                }
                
                VStack(spacing: 16) {
                    notificationToggleRow()
                    separator()
                    dailyReminderRow()
                    separator()
                }
                .padding(.horizontal, 12)
                .padding(.top, store.state.isSystemDenied ? 20 : 32)
                
                Spacer()
            }
        }
        .navigationTitle(L10n.notifications)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            store.send(.checkSystemPermission, animation: nil)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.send(.checkSystemPermission)
            }
        }
    }
    
    // MARK: - Denied Banner
    
    @ViewBuilder
    private func deniedBanner() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.myAccentColor1)
                
                Text(L10n.notificationDeniedMessage)
                    .font(.myRegular(size: 16))
                    .foregroundStyle(.textMulticolor.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            
            Button {
                store.send(.openSystemSettings)
            } label: {
                Text(L10n.notificationOpenSettings)
                    .font(.mySemiBold(size: 11))
                    .tracking(1.5)
                    .foregroundStyle(.textMulticolor.opacity(0.85))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .overlay {
                        Rectangle()
                            .stroke(Color.textMulticolor.opacity(0.35), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .padding(.leading, 26)
            .padding(.vertical, 8)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.myAccentColor1.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.myAccentColor1.opacity(0.7), lineWidth: 0.5)
                }
        }
    }
    
    // MARK: - Rows
    
    @ViewBuilder
    private func notificationToggleRow() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.textMulticolor.opacity(0.7))
                .frame(width: 24)
            
            Text(L10n.notificationsEnabled)
                .font(.myRegular(size: 16))
                .foregroundStyle(.textMulticolor)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { store.state.notificationsEnabled },
                set: { store.send(.toggleNotifications($0)) }
            ))
            .labelsHidden()
            .tint(.myPrimary)
        }
    }
    
    @ViewBuilder
    private func dailyReminderRow() -> some View {
        let enabled = store.state.notificationsEnabled
        
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(enabled ? .textMulticolor.opacity(0.7) : .textMulticolor.opacity(0.25))
                    .frame(width: 24)
                
                Text(L10n.dailyReminderEnabled)
                    .font(.myRegular(size: 16))
                    .foregroundStyle(enabled ? .textMulticolor : .textMulticolor.opacity(0.35))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { store.state.dailyReminderEnabled },
                    set: { store.send(.toggleDailyReminder($0)) }
                ))
                .labelsHidden()
                .tint(.myPrimary)
                .disabled(!enabled)
            }
            
            reminderTimeRow()
        }
    }
    
    @ViewBuilder
    private func reminderTimeRow() -> some View {
        let isActive = store.state.notificationsEnabled && store.state.dailyReminderEnabled
        
        HStack(spacing: 12) {
            Text(L10n.reminderTime)
                .font(.myMedium(size: 16))
                .foregroundStyle(isActive ? .textMulticolor : .textMulticolor.opacity(0.35))
                .padding(.leading, 30)
            
            Spacer()
            
            DatePicker("", selection: Binding(
                get: { store.state.reminderTime },
                set: { store.send(.changeReminderTime($0), animation: nil) }
            ), displayedComponents: .hourAndMinute)
            .labelsHidden()
            .disabled(!isActive)
            .opacity(isActive ? 1 : 0.35)
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private func separator() -> some View {
        Rectangle()
            .frame(height: 0.5)
            .foregroundStyle(.textMulticolor.opacity(0.15))
            .padding(.leading, 40)
    }
}

#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .notificationSettings)
    }
}
