//
//  StringSwipeModifier.swift
//  OurStory
//

import SwiftUI

struct StringSwipeModifier: ViewModifier {

    let edges: Edge.Set
    let threshold: CGFloat
    let style: StringSwipeStyle
    let onCommit: (Edge) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pull = StringPullState()
    @State private var lockedAxis: Axis?
    @State private var excludedFrames: [CGRect] = []
    @State private var isIgnoringCurrentDrag = false
    @GestureState private var isDragging = false

    private static let flickVelocity: CGFloat = 500
    private static let flickMinDistance: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion, let edge = pull.edge {
                    StringBendShape(edge: edge, bend: pull.bend, anchor: pull.anchor)
                        .stroke(style.color, style: StrokeStyle(lineWidth: style.lineWidth, lineCap: .round))
                        .opacity(min(max(pull.bend / 6, 0), 1))
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            // Simultaneous so nested scroll views don't delay the pull until they give up the touch.
            .simultaneousGesture(dragGesture)
            .coordinateSpace(.named(StringSwipeCoordinateSpace.name))
            .onPreferenceChange(StringSwipeExclusionKey.self) { excludedFrames = $0 }
            .sensoryFeedback(.impact(weight: .light), trigger: pull.isPastThreshold) { _, isPast in isPast }
            .onChange(of: isDragging) { _, dragging in
                guard !dragging else { return }
                isIgnoringCurrentDrag = false
                if pull.bend != 0 { release(commit: false) }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .named(StringSwipeCoordinateSpace.name))
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                if lockedAxis == nil {
                    isIgnoringCurrentDrag = excludedFrames.contains { $0.contains(value.startLocation) }
                }
                guard !isIgnoringCurrentDrag else {
                    lockedAxis = .horizontal
                    return
                }
                handleChange(translation: value.translation, location: value.location)
            }
            .onEnded { value in
                guard !isIgnoringCurrentDrag else {
                    lockedAxis = nil
                    isIgnoringCurrentDrag = false
                    return
                }
                release(commit: shouldCommit(velocity: value.velocity))
            }
    }

    private func handleChange(translation: CGSize, location: CGPoint) {
        let axis = lockedAxis ?? (abs(translation.width) > abs(translation.height) ? .horizontal : .vertical)
        lockedAxis = axis

        let edge: Edge
        let distance: CGFloat
        let anchor: CGFloat
        switch axis {
        case .horizontal:
            edge = translation.width < 0 ? .trailing : .leading
            distance = abs(translation.width)
            anchor = location.y
        case .vertical:
            edge = translation.height < 0 ? .bottom : .top
            distance = abs(translation.height)
            anchor = location.x
        }

        guard edges.contains(Edge.Set(edge)) else {
            pull.bend = 0
            pull.distance = 0
            pull.isPastThreshold = false
            return
        }

        pull.edge = edge
        pull.anchor = anchor
        pull.bend = StringPullState.bend(for: distance, style: style)
        pull.distance = distance
        pull.isPastThreshold = distance >= threshold
    }

    /// Commits either by distance or by a quick flick toward the screen center.
    private func shouldCommit(velocity: CGSize) -> Bool {
        guard !pull.isPastThreshold else { return true }
        guard let edge = pull.edge, pull.distance >= Self.flickMinDistance else { return false }
        let inwardVelocity: CGFloat = switch edge {
        case .leading: velocity.width
        case .trailing: -velocity.width
        case .top: velocity.height
        case .bottom: -velocity.height
        }
        return inwardVelocity >= Self.flickVelocity
    }

    private func release(commit: Bool) {
        lockedAxis = nil
        if commit, let edge = pull.edge {
            onCommit(edge)
        }
        pull.distance = 0
        withAnimation(commit ? style.commitAnimation : style.cancelAnimation) {
            pull.bend = 0
            pull.isPastThreshold = false
        }
    }
}

enum StringSwipeCoordinateSpace {
    static let name = "StringSwipeCoordinateSpace"
}

struct StringSwipeExclusionKey: PreferenceKey {
    static let defaultValue: [CGRect] = []

    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {

    /// Swipe gesture that visually pulls a string from the screen edge opposite to the finger's direction.
    /// `onCommit` receives the edge the string was pulled from once `threshold` is exceeded.
    func stringSwipe(
        edges: Edge.Set,
        threshold: CGFloat = 80,
        style: StringSwipeStyle = .default,
        onCommit: @escaping (Edge) -> Void
    ) -> some View {
        modifier(StringSwipeModifier(edges: edges, threshold: threshold, style: style, onCommit: onCommit))
    }

    /// Marks a region (e.g. a horizontal scroll view) where drags must not start a string pull.
    func stringSwipeExcluded() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: StringSwipeExclusionKey.self,
                    value: [proxy.frame(in: .named(StringSwipeCoordinateSpace.name))]
                )
            }
        }
    }
}
