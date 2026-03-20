import SwiftUI

struct NowPlayingWidget: View {
    var viewModel: NotchViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Album artwork
            artworkView

            VStack(alignment: .leading, spacing: 4) {
                if viewModel.trackTitle.isEmpty {
                    Text("No music playing")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    Text(viewModel.trackTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(viewModel.trackArtist)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                controlsView
            }
        }
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
                    Color.white.opacity(0.1)
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var controlsView: some View {
        HStack(spacing: 16) {
            Button { viewModel.nowPlaying.previousTrack() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 12))
            }
            Button { viewModel.nowPlaying.togglePlayPause() } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
            }
            Button { viewModel.nowPlaying.nextTrack() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.9))
    }
}
