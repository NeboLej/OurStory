//
//  StringSwipeStyle.swift
//  OurStory
//

import SwiftUI

struct StringSwipeStyle {

    var color: Color = .myPrimary
    var lineWidth: CGFloat = 1
    var maxBend: CGFloat = 60
    var resistance: CGFloat = 120
    var commitAnimation: Animation = .interpolatingSpring(stiffness: 320, damping: 16)
    var cancelAnimation: Animation = .spring(duration: 0.35, bounce: 0.3)

    static let `default` = StringSwipeStyle()
}
