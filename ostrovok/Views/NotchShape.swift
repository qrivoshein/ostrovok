import SwiftUI

struct NotchShape: Shape {
    var width: CGFloat
    var height: CGFloat
    var bottomRadius: CGFloat = 20

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get { AnimatablePair(AnimatablePair(width, height), bottomRadius) }
        set {
            width = newValue.first.first
            height = newValue.first.second
            bottomRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let halfW = width / 2
        let r = min(bottomRadius, halfW, height)

        var path = Path()

        // Top-left (tight corner blending with screen bezel)
        path.move(to: CGPoint(x: midX - halfW, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: midX + halfW, y: 0))

        // Right edge down to bottom-right curve
        path.addLine(to: CGPoint(x: midX + halfW, y: height - r))

        // Bottom-right: smooth cubic bezier for squircle-like corner
        path.addCurve(
            to: CGPoint(x: midX + halfW - r, y: height),
            control1: CGPoint(x: midX + halfW, y: height - r * 0.1),
            control2: CGPoint(x: midX + halfW - r * 0.1, y: height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: midX - halfW + r, y: height))

        // Bottom-left: smooth cubic bezier
        path.addCurve(
            to: CGPoint(x: midX - halfW, y: height - r),
            control1: CGPoint(x: midX - halfW + r * 0.1, y: height),
            control2: CGPoint(x: midX - halfW, y: height - r * 0.1)
        )

        path.closeSubpath()
        return path
    }
}
