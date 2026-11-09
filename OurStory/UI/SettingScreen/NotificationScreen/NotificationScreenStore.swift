//
//  NotificationScreenStore.swift
//  OurStory
//

import SwiftUI

@Observable
final class NotificationScreenStore: BaseStore {
    
    private(set) var notificationsEnabled = false
    private(set) var dailyReminderEnabled = false
    private(set) var reminderTime = Date()
    private(set) var isSystemDenied = false
    
    @ObservationIgnored
    private let notificationService = NotificationService.shared
    @ObservationIgnored
    private let userDefaultsManager = UserDefaultsManager()
    
    private var calendar = Calendar.current
    
    var state: NotificationScreenState {
        NotificationScreenState(
            notificationsEnabled: notificationsEnabled,
            dailyReminderEnabled: dailyReminderEnabled,
            reminderTime: reminderTime,
            isSystemDenied: isSystemDenied
        )
    }
    
    override init(appStore: AppStoreProtocol) {
        super.init(appStore: appStore)
        loadSettings()
    }
    
    func send(_ action: NotificationScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .toggleNotifications(let enabled):
                Task { await handleNotificationsToggle(enabled) }
            case .toggleDailyReminder(let enabled):
                handleDailyReminderToggle(enabled)
            case .changeReminderTime(let date):
                handleReminderTimeChange(date)
            case .checkSystemPermission:
                Task { await checkSystemPermission() }
            case .openSystemSettings:
                openSystemSettings()
            }
        }
    }
    
    // MARK: - Private
    
    private func loadSettings() {
        notificationsEnabled = userDefaultsManager.isNotificationsEnabled
        dailyReminderEnabled = userDefaultsManager.isDailyReminderEnabled
        
        var components = DateComponents()
        components.hour = userDefaultsManager.dailyReminderHour
        components.minute = userDefaultsManager.dailyReminderMinute
        reminderTime = calendar.date(from: components) ?? Date()
    }
    
    private func checkSystemPermission() async {
        let status = await notificationService.currentAuthorizationStatus()
        let denied = status == .denied
        isSystemDenied = denied
        if denied && notificationsEnabled {
            notificationsEnabled = false
            dailyReminderEnabled = false
            userDefaultsManager.isNotificationsEnabled = false
            userDefaultsManager.isDailyReminderEnabled = false
            notificationService.cancelDailyReminder()
        }
    }
    
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func handleNotificationsToggle(_ enabled: Bool) async {
        if enabled {
            let status = await notificationService.currentAuthorizationStatus()
            if status == .denied {
                isSystemDenied = true
                notificationsEnabled = false
                return
            }
            let granted = await notificationService.requestPermission()
            if !granted {
                notificationsEnabled = false
                isSystemDenied = true
                return
            }
            isSystemDenied = false
        } else {
            dailyReminderEnabled = false
            notificationService.cancelDailyReminder()
            userDefaultsManager.isDailyReminderEnabled = false
        }
        notificationsEnabled = enabled
        userDefaultsManager.isNotificationsEnabled = enabled
    }
    
    private func handleDailyReminderToggle(_ enabled: Bool) {
        dailyReminderEnabled = enabled
        userDefaultsManager.isDailyReminderEnabled = enabled
        if enabled {
            notificationService.scheduleDailyReminder(
                hour: calendar.component(.hour, from: reminderTime),
                minute: calendar.component(.minute, from: reminderTime)
            )
        } else {
            notificationService.cancelDailyReminder()
        }
    }
    
    private func handleReminderTimeChange(_ date: Date) {
        reminderTime = date
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        userDefaultsManager.dailyReminderHour = hour
        userDefaultsManager.dailyReminderMinute = minute
        if dailyReminderEnabled {
            notificationService.scheduleDailyReminder(hour: hour, minute: minute)
        }
    }
}
