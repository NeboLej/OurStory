//
//  AppMetricaAnalyticsService.swift
//  OurStory
//
//  Created by Nebo on 07.11.2026.
//

import Foundation
import AppMetricaCore

protocol AnalyticsServiceProtocol {
    func log(event: AnalyticsEvent)
}

protocol AnalyticsEvent {
    var name: String { get }
    var parameters: [String: Any]? { get }
}

enum AppEvent: AnalyticsEvent {
    case appOpened
    case newNote
    case newFriend
    case noteSyncSuccess(count: Int)
    case noteSyncFailed
    case calendarOpened
    case helpOpened

    var name: String {
        switch self {
        case .appOpened: "app_opened"
        case .newNote: "new_note"
        case .newFriend: "new_friend"
        case .noteSyncSuccess: "note_sync_success"
        case .noteSyncFailed: "note_sync_failed"
        case .calendarOpened: "calendar_opened"
        case .helpOpened: "help_opened"
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case .noteSyncSuccess(count: let count): ["count": count]
        default: nil
        }
    }
}


final class AppMetricaAnalyticsService: AnalyticsServiceProtocol {

    init(apiKey: String) {
        let configuration = AppMetricaConfiguration(apiKey: apiKey)

        AppMetrica.activate(with: configuration!)
    }

    func log(event: AnalyticsEvent) {
        AppMetrica.reportEvent(name: event.name, parameters: event.parameters, onFailure: nil)
    }
}

