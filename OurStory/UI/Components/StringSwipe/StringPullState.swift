//
//  StringPullState.swift
//  OurStory
//

import SwiftUI

struct StringPullState: Equatable {

    var edge: Edge?
    var bend: CGFloat = 0
    var anchor: CGFloat = 0
    var distance: CGFloat = 0
    var isPastThreshold = false

    /// Rubber-band curve: bend grows quickly at first and asymptotically approaches `maxBend`.
    static func bend(for distance: CGFloat, style: StringSwipeStyle) -> CGFloat {
        style.maxBend * (1 - exp(-distance / style.resistance))
    }
}
