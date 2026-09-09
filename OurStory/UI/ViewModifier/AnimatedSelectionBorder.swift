//
//  AnimatedSelectionBorder.swift
//  OurStory
//
//  Created by Nebo on 09.09.2026.
//

import SwiftUI

struct AnimatedSelectionBorder: ViewModifier {
    let isSelected: Bool

    private let duration: TimeInterval = 2.0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isSelected {
                    TimelineView(.animation) { timeline in
                        let elapsed = timeline.date.timeIntervalSinceReferenceDate
                        let progress = elapsed.truncatingRemainder(dividingBy: duration) / duration

                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                AngularGradient(
                                    colors: [.clear, .clear,
                                        .blue, .purple, .pink,
                                        .clear, .clear],
                                    center: .center,
                                    angle: .degrees(progress * 360)
                                ),style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                            )
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isSelected)
    }
}
