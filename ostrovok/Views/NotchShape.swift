import SwiftUI

struct NotchShape: Shape {
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat = 12
    var topCornerRadius: CGFloat = 6

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(width, height) }
        set {
            width = newValue.first
            height = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let halfW = width / 2
        let cr = cornerRadius
        let tcr = topCornerRadius

        var path = Path()

        // Start at top-left
        path.move(to: CGPoint(x: midX - halfW + tcr, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: midX + halfW - tcr, y: 0))

        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: midX + halfW, y: tcr),
            control: CGPoint(x: midX + halfW, y: 0)
        )

        // Right edge down
        path.addLine(to: CGPoint(x: midX + halfW, y: height - cr))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: midX + halfW - cr, y: height),
            control: CGPoint(x: midX + halfW, y: height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: midX - halfW + cr, y: height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: midX - halfW, y: height - cr),
            control: CGPoint(x: midX - halfW, y: height)
        )

        // Left edge up
        path.addLine(to: CGPoint(x: midX - halfW, y: tcr))

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: midX - halfW + tcr, y: 0),
            control: CGPoint(x: midX - halfW, y: 0)
        )

        path.closeSubpath()
        return path
    }
}
