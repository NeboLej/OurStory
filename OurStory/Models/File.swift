//
//  File.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import Foundation

struct TestUser {
    let id: UUID
    let name: String
    let color: String

    init(id: UUID = UUID(), name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
}
