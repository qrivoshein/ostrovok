import SwiftUI

struct CollapsedNotchView: View {
    var viewModel: NotchViewModel

    var body: some View {
        HStack(spacing: 6) {
            if viewModel.isPlaying {
                MusicBarsView()
            }
        }
        .frame(height: viewModel.notchSize.height)
    }
}

struct MusicBarsView: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(.white.opacity(0.8))
                    .frame(width: 2.5, height: animating ? barHeight(for: index) : 4)
                    .animation(
                        .easeInOut(duration: duration(for: index))
                            .repeatForever(autoreverses: true),
                        value: animating
                    )
            }
        }
        .frame(width: 14, height: 14)
        .onAppear { animating = true }
    }

    private func barHeight(for index: Int) -> CGFloat {
        switch index {
        case 0: return 10
        case 1: return 14
        default: return 8
        }
    }

    private func duration(for index: Int) -> Double {
        switch index {
        case 0: return 0.5
        case 1: return 0.35
        default: return 0.45
        }
    }
}
