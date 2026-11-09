//
//  NotificationService.swift
//  OurStory
//

import UserNotifications

final class NotificationService {
    
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    private let dailyReminderPrefix = "daily_story_reminder_"
    private let scheduleDays = 14
    
    private init() {}
    
    private static let lastRescheduleKey = "lastNotificationRescheduleDate"
    
    // MARK: - Auto Reschedule
    
    /// Call on app launch / foreground. Reschedules at most once per day.
    func rescheduleIfNeeded() {
        let defaults = UserDefaultsManager()
        guard defaults.isNotificationsEnabled,
              defaults.isDailyReminderEnabled else { return }
        
        let calendar = Calendar.current
        let lastDate = UserDefaults.standard.object(forKey: Self.lastRescheduleKey) as? Date
        if let lastDate, calendar.isDateInToday(lastDate) { return }
        
        scheduleDailyReminder(hour: defaults.dailyReminderHour, minute: defaults.dailyReminderMinute)
        UserDefaults.standard.set(Date(), forKey: Self.lastRescheduleKey)
    }
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            Logger.log("Notification permission: \(granted)", location: .unowned, event: granted ? .success : .error())
            return granted
        } catch {
            Logger.log("Notification permission error", location: .unowned, event: .error(error))
            return false
        }
    }
    
    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Daily Reminder
    
    func scheduleDailyReminder(hour: Int, minute: Int) {
        cancelDailyReminder()
        
        let calendar = Calendar.current
        let titles = L10n.notificationReminderTitles
        let bodies = L10n.notificationReminderBodies
        
        for dayOffset in 0..<scheduleDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: .now) else { continue }
            
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            components.minute = minute
            
            let content = UNMutableNotificationContent()
            content.title = titles.randomElement() ?? ""
            content.body = bodies.randomElement() ?? ""
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "\(dailyReminderPrefix)\(dayOffset)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error {
                    Logger.log("Schedule reminder[\(dayOffset)] failed", location: .unowned, event: .error(error))
                }
            }
        }
        
        Logger.log("Daily reminders scheduled (\(scheduleDays) days) at \(hour):\(String(format: "%02d", minute))", location: .unowned, event: .success)
    }
    
    func cancelDailyReminder() {
        let ids = (0..<scheduleDays).map { "\(dailyReminderPrefix)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        Logger.log("Daily reminders cancelled", location: .unowned, event: .success)
    }
}
