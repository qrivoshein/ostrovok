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
        let r = min(bottomRadius, halfW, height / 2)

        // Apple squircle factor: 0.55 approximates a circular arc with cubic bezier
        let k: CGFloat = 0.55

        var path = Path()

        // Top-left: flush with screen top (no rounding needed — hidden by bezel)
        path.move(to: CGPoint(x: midX - halfW, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: midX + halfW, y: 0))

        // Right edge down to start of bottom-right curve
        path.addLine(to: CGPoint(x: midX + halfW, y: height - r))

        // Bottom-right corner: smooth continuous curve (squircle)
        path.addCurve(
            to: CGPoint(x: midX + halfW - r, y: height),
            control1: CGPoint(x: midX + halfW, y: height - r + r * k),
            control2: CGPoint(x: midX + halfW - r + r * k, y: height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: midX - halfW + r, y: height))

        // Bottom-left corner: smooth continuous curve (squircle)
        path.addCurve(
            to: CGPoint(x: midX - halfW, y: height - r),
            control1: CGPoint(x: midX - halfW + r - r * k, y: height),
            control2: CGPoint(x: midX - halfW, y: height - r + r * k)
        )

        path.closeSubpath()
        return path
    }
}
