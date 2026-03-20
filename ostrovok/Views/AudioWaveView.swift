import SwiftUI

struct AudioWaveView: View {
    var isPlaying: Bool
    var color: Color

    @State private var animating = false

    private let barCount = 5
    private let barWidth: CGFloat = 3

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.5)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: barWidth, height: barHeight(for: index))
                    .animation(
                        isPlaying
                            ? .easeInOut(duration: speed(for: index))
                              .repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.3),
                        value: animating
                    )
            }
        }
        .frame(width: CGFloat(barCount) * (barWidth + 2.5), height: 30)
        .onChange(of: isPlaying) { _, playing in
            animating = playing
        }
        .onAppear {
            if isPlaying { animating = true }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        if !animating {
            return 4
        }
        let heights: [CGFloat] = [16, 26, 20, 30, 14]
        return heights[index % heights.count]
    }

    private func speed(for index: Int) -> Double {
        let speeds: [Double] = [0.45, 0.35, 0.5, 0.3, 0.55]
        return speeds[index % speeds.count]
    }
}

extension NSImage {
    func dominantColor() -> NSColor {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return .white
        }

        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        var count: CGFloat = 0

        let sampleSize = min(bitmap.pixelsWide, bitmap.pixelsHigh, 20)
        let stepX = max(bitmap.pixelsWide / sampleSize, 1)
        let stepY = max(bitmap.pixelsHigh / sampleSize, 1)

        for x in stride(from: 0, to: bitmap.pixelsWide, by: stepX) {
            for y in stride(from: 0, to: bitmap.pixelsHigh, by: stepY) {
                if let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) {
                    totalR += color.redComponent
                    totalG += color.greenComponent
                    totalB += color.blueComponent
                    count += 1
                }
            }
        }

        guard count > 0 else { return .white }
        return NSColor(
            red: totalR / count,
            green: totalG / count,
            blue: totalB / count,
            alpha: 1.0
        )
    }
}
