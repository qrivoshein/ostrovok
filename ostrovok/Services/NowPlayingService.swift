import AppKit

@Observable
@MainActor
final class NowPlayingService {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artworkImage: NSImage?
    var isPlaying: Bool = false
    var duration: TimeInterval = 0
    var elapsedTime: TimeInterval = 0

    private var observers: [NSObjectProtocol] = []

    func start() {
        MediaRemoteBridge.registerForNotifications?(DispatchQueue.main)

        observers.append(
            NotificationCenter.default.addObserver(
                forName: MediaRemoteBridge.infoDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.fetchNowPlayingInfo()
            }
        )

        observers.append(
            NotificationCenter.default.addObserver(
                forName: MediaRemoteBridge.isPlayingDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.fetchIsPlaying()
            }
        )

        fetchNowPlayingInfo()
        fetchIsPlaying()
    }

    func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }

    func togglePlayPause() {
        _ = MediaRemoteBridge.sendCommand?(MediaRemoteBridge.commandTogglePlayPause, nil)
    }

    func nextTrack() {
        _ = MediaRemoteBridge.sendCommand?(MediaRemoteBridge.commandNextTrack, nil)
    }

    func previousTrack() {
        _ = MediaRemoteBridge.sendCommand?(MediaRemoteBridge.commandPreviousTrack, nil)
    }

    private func fetchNowPlayingInfo() {
        MediaRemoteBridge.getNowPlayingInfo?(DispatchQueue.main) { [weak self] info in
            MainActor.assumeIsolated {
                self?.updateInfo(info)
            }
        }
    }

    private func fetchIsPlaying() {
        MediaRemoteBridge.getIsPlaying?(DispatchQueue.main) { [weak self] playing in
            MainActor.assumeIsolated {
                self?.isPlaying = playing
            }
        }
    }

    private func updateInfo(_ info: [String: Any]) {
        let newTitle = info[MediaRemoteBridge.keyTitle] as? String ?? ""
        let newArtist = info[MediaRemoteBridge.keyArtist] as? String ?? ""
        let newAlbum = info[MediaRemoteBridge.keyAlbum] as? String ?? ""

        if newTitle != title { title = newTitle }
        if newArtist != artist { artist = newArtist }
        if newAlbum != album { album = newAlbum }

        duration = info[MediaRemoteBridge.keyDuration] as? TimeInterval ?? 0
        elapsedTime = info[MediaRemoteBridge.keyElapsedTime] as? TimeInterval ?? 0

        if let artworkData = info[MediaRemoteBridge.keyArtwork] as? Data {
            artworkImage = NSImage(data: artworkData)
        } else {
            artworkImage = nil
        }
    }
}
