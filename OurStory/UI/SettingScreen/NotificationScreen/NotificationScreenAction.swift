//
//  NotificationScreenAction.swift
//  OurStory
//

import Foundation

enum NotificationScreenAction {
    case toggleNotifications(Bool)
    case toggleDailyReminder(Bool)
    case changeReminderTime(Date)
    case checkSystemPermission
    case openSystemSettings
}
