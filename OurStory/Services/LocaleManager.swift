//
//  LocaleManager.swift
//  OurStory
//

import SwiftUI

enum AppLanguage: String, CaseIterable {
    case russian = "ru"
    case english = "en"
    
    var title: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        }
    }
    
    var icon: String {
        switch self {
        case .russian: return "r.circle"
        case .english: return "e.circle"
        }
    }
    
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

@Observable
@MainActor
final class LocaleManager {
    static let shared = LocaleManager()
    
    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            L10n.language = currentLanguage
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.russian.rawValue
        currentLanguage = AppLanguage(rawValue: saved) ?? .russian
    }
}
