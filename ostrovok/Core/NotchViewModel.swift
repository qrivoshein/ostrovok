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

    var currentWidth: CGFloat {
        switch state {
        case .collapsed: return notchSize.width
        case .hovering: return notchSize.width + 24
        case .expanded: return notchSize.width + 200
        }
    }

    var currentHeight: CGFloat {
        switch state {
        case .collapsed: return notchSize.height
        case .hovering: return notchSize.height + 6
        case .expanded: return notchSize.height + 100
        }
    }

    var bottomCornerRadius: CGFloat {
        switch state {
        case .collapsed: return 8
        case .hovering: return 12
        case .expanded: return 20
        }
    }

    func start() {
        nowPlaying.start()
    }
}
