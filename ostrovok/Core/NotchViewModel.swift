import AppKit

@Observable
@MainActor
final class NotchViewModel {
    enum NotchState {
        case collapsed
        case expanded
    }

    var state: NotchState = .collapsed
    var notchSize: CGSize = .zero
    let nowPlaying = NowPlayingService()

    var isExpanded: Bool { state == .expanded }
    var isPlaying: Bool { nowPlaying.isPlaying }
    var trackTitle: String { nowPlaying.title }
    var trackArtist: String { nowPlaying.artist }
    var artworkImage: NSImage? { nowPlaying.artworkImage }

    var currentWidth: CGFloat {
        isExpanded ? notchSize.width + 160 : notchSize.width
    }

    var currentHeight: CGFloat {
        isExpanded ? notchSize.height + 100 : notchSize.height
    }

    func start() {
        nowPlaying.start()
    }
}
