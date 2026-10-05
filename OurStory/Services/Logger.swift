//
//  Logger.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation

final class Logger {
    
    enum Location {
        case GRDB
        case cloudKit
        case unowned
        
        var text: String {
            switch self {
            case .GRDB: return "💿"
            case .cloudKit: return "☁️"
            case .unowned: return "🧭"
            }
        }
    }
    
    enum Status {
        case success
        case error(Error? = nil)
        case processing
        case unowned
        
        var text: String {
            switch self {
            case .success: "☘️"
            case let .error(error): "🆘 ERROR: \(error?.localizedDescription ?? "N/A")"
            case .processing: "🌬️"
            case .unowned: "👾"
            }
        }
    }
    
    private init() {}
    
    static var allLogs = [String]()
    
    static func log(_ text: String = "", location: Location = .unowned, event: Status = .unowned) {
        let log = ["LOG: ", location.text, event.text, " ---- ",  text].joined()
        allLogs.append(log)
        print(log)
    }
}

