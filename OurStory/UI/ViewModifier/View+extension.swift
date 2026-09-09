//
//  View+extension.swift
//  OurStory
//
//  Created by Nebo on 09.09.2026.
//

import SwiftUI

extension View {
    func animatedSelectionBorder(isSelected: Bool) -> some View {
        modifier(
            AnimatedSelectionBorder(isSelected: isSelected)
        )
    }
}
