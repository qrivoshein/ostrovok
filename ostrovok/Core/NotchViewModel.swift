import AppKit

@Observable
@MainActor
final class NotchViewModel {
    enum NotchState {
        case collapsed
        case hovering
        case expanded
    }

    var state: NotchState = .collapsed
    var notchSize: CGSize = .zero
    let nowPlaying = NowPlayingService()

    var isExpanded: Bool { state == .expanded }
    var isHovering: Bool { state == .hovering }
    var isPlaying: Bool { nowPlaying.isPlaying }
    var trackTitle: String { nowPlaying.title }
    var trackArtist: String { nowPlaying.artist }
    var artworkImage: NSImage? { nowPlaying.artworkImage }
    var elapsed: TimeInterval { nowPlaying.elapsedTime }
    var duration: TimeInterval { nowPlaying.duration }

    var currentWidth: CGFloat {
        switch state {
        case .collapsed: return notchSize.width
        case .hovering: return notchSize.width + 24
        case .expanded: return notchSize.width + 240
        }
    }

    var currentHeight: CGFloat {
        switch state {
        case .collapsed: return notchSize.height
        case .hovering: return notchSize.height + 6
        case .expanded: return notchSize.height + 170
        }
    }

    var bottomCornerRadius: CGFloat {
        switch state {
        case .collapsed: return 8
        case .hovering: return 12
        case .expanded: return 24
        }
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(elapsed / duration, 1.0)
    }

    var elapsedText: String { formatTime(elapsed) }
    var remainingText: String { "-" + formatTime(max(duration - elapsed, 0)) }

    func start() {
        nowPlaying.start()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
