//
//  ThemeManager.swift
//  OurStory
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case dark
    case light
    case system
    
    var colorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
    
    var title: String {
        switch self {
        case .dark: return L10n.themeDark
        case .light: return L10n.themeLight
        case .system: return L10n.themeSystem
        }
    }
    
    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "gearshape.fill"
        }
    }
}

@Observable
@MainActor
final class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.dark.rawValue
        currentTheme = AppTheme(rawValue: saved) ?? .dark
    }
}
