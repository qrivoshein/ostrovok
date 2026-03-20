import SwiftUI

struct NowPlayingWidget: View {
    var viewModel: NotchViewModel

    private var waveColor: Color {
        if let image = viewModel.artworkImage {
            return Color(nsColor: image.dominantColor())
        }
        return .white.opacity(0.6)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Top: artwork + track info
            trackInfoRow

            // Middle: progress bar
            progressRow

            // Bottom: controls + wave
            controlsRow
        }
        .frame(width: viewModel.notchSize.width + 200)
    }

    // MARK: - Track Info

    private var trackInfoRow: some View {
        HStack(spacing: 12) {
            artworkView

            VStack(alignment: .leading, spacing: 2) {
                if viewModel.trackTitle.isEmpty {
                    Text("Not playing")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                } else {
                    Text(viewModel.trackTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(viewModel.trackArtist)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Artwork (circle)

    @ViewBuilder
    private var artworkView: some View {
        Group {
            if let image = viewModel.artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.white.opacity(0.08)
                    Image(systemName: "music.note")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    // MARK: - Progress

    private var progressRow: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 4)

                    // Progress fill
                    Capsule()
                        .fill(.white.opacity(0.9))
                        .frame(
                            width: max(4, geo.size.width * viewModel.progress),
                            height: 4
                        )

                    // Knob
                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                        .offset(
                            x: max(0, min(
                                geo.size.width * viewModel.progress - 5,
                                geo.size.width - 10
                            ))
                        )
                }
                .frame(height: 10)
            }
            .frame(height: 10)

            HStack {
                Text(viewModel.elapsedText)
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text(viewModel.remainingText)
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Controls + Wave

    private var controlsRow: some View {
        HStack(spacing: 0) {
            Spacer()

            HStack(spacing: 20) {
                Button { viewModel.nowPlaying.previousTrack() } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16))
                }

                Button { viewModel.nowPlaying.togglePlayPause() } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 36, height: 36)
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.black)
                    }
                }

                Button { viewModel.nowPlaying.nextTrack() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.85))

            Spacer()

            AudioWaveView(
                isPlaying: viewModel.isPlaying,
                color: waveColor
            )
            .padding(.trailing, 4)
        }
    }
}
