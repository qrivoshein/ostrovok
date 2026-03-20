import SwiftUI

struct NowPlayingWidget: View {
    var viewModel: NotchViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Left: artwork + track info
            HStack(spacing: 10) {
                artworkView

                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.trackTitle.isEmpty {
                        Text("Not playing")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    } else {
                        Text(viewModel.trackTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(viewModel.trackArtist)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Right: controls
            controlsView
        }
        .frame(width: viewModel.notchSize.width + 160)
    }

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
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var controlsView: some View {
        HStack(spacing: 14) {
            Button { viewModel.nowPlaying.previousTrack() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 13))
            }
            Button { viewModel.nowPlaying.togglePlayPause() } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16))
                    .frame(width: 20)
            }
            Button { viewModel.nowPlaying.nextTrack() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 13))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.85))
    }
}
