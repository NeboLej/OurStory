//
//  StringBendShape.swift
//  OurStory
//

import SwiftUI

/// A line lying along `edge` that is pulled inward by `bend` points at `anchor` (points along the edge).
struct StringBendShape: Shape {

    var edge: Edge
    var bend: CGFloat
    var anchor: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(bend, anchor) }
        set {
            bend = newValue.first
            anchor = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let length = edgeLength(in: rect)
        let peak = min(max(anchor, 0), length)
        let leftSpread = peak * 0.5
        let rightSpread = (length - peak) * 0.5

        var path = Path()
        path.move(to: point(along: 0, depth: 0, in: rect))
        path.addCurve(
            to: point(along: peak, depth: bend, in: rect),
            control1: point(along: leftSpread, depth: 0, in: rect),
            control2: point(along: peak - leftSpread * 0.5, depth: bend, in: rect)
        )
        path.addCurve(
            to: point(along: length, depth: 0, in: rect),
            control1: point(along: peak + rightSpread * 0.5, depth: bend, in: rect),
            control2: point(along: length - rightSpread, depth: 0, in: rect)
        )
        return path
    }

    private func edgeLength(in rect: CGRect) -> CGFloat {
        switch edge {
        case .leading, .trailing: rect.height
        case .top, .bottom: rect.width
        }
    }

    /// Maps edge-local coordinates (position along the edge, depth into the rect) to rect coordinates.
    private func point(along: CGFloat, depth: CGFloat, in rect: CGRect) -> CGPoint {
        switch edge {
        case .leading: CGPoint(x: rect.minX + depth, y: rect.minY + along)
        case .trailing: CGPoint(x: rect.maxX - depth, y: rect.minY + along)
        case .top: CGPoint(x: rect.minX + along, y: rect.minY + depth)
        case .bottom: CGPoint(x: rect.minX + along, y: rect.maxY - depth)
        }
    }
}
