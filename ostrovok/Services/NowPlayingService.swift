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

    private var observers: [Any] = []
    private var mediaRemoteWorks = false
    private var progressTimer: Timer?

    func start() {
        setupMediaRemote()
        setupDistributedNotifications()
        startProgressTimer()
    }

    func stop() {
        progressTimer?.invalidate()
        progressTimer = nil
        for obs in observers {
            NotificationCenter.default.removeObserver(obs)
            DistributedNotificationCenter.default().removeObserver(obs)
        }
        observers.removeAll()
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isPlaying, self.duration > 0 else { return }
                self.elapsedTime = min(self.elapsedTime + 1.0, self.duration)
            }
        }
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

    // MARK: - MediaRemote

    private func setupMediaRemote() {
        MediaRemoteBridge.registerForNotifications?(DispatchQueue.main)

        observers.append(
            NotificationCenter.default.addObserver(
                forName: MediaRemoteBridge.infoDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.fetchMediaRemoteInfo()
            }
        )

        observers.append(
            NotificationCenter.default.addObserver(
                forName: MediaRemoteBridge.isPlayingDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.fetchMediaRemoteIsPlaying()
            }
        )

        fetchMediaRemoteInfo()
        fetchMediaRemoteIsPlaying()
    }

    private func fetchMediaRemoteInfo() {
        MediaRemoteBridge.getNowPlayingInfo?(DispatchQueue.main) { [weak self] info in
            MainActor.assumeIsolated {
                guard let self else { return }
                let newTitle = info[MediaRemoteBridge.keyTitle] as? String ?? ""
                if !newTitle.isEmpty {
                    self.mediaRemoteWorks = true
                    self.updateFromMediaRemote(info)
                }
            }
        }
    }

    private func fetchMediaRemoteIsPlaying() {
        MediaRemoteBridge.getIsPlaying?(DispatchQueue.main) { [weak self] playing in
            MainActor.assumeIsolated {
                self?.isPlaying = playing
            }
        }
    }

    private func updateFromMediaRemote(_ info: [String: Any]) {
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
        }
    }

    // MARK: - Distributed Notifications fallback

    private func setupDistributedNotifications() {
        let dnc = DistributedNotificationCenter.default()

        observers.append(
            dnc.addObserver(
                forName: NSNotification.Name("com.apple.Music.playerInfo"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    self?.handleMusicNotification(notification.userInfo)
                }
            }
        )

        observers.append(
            dnc.addObserver(
                forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    self?.handleSpotifyNotification(notification.userInfo)
                }
            }
        )
    }

    private func handleMusicNotification(_ userInfo: [AnyHashable: Any]?) {
        guard !mediaRemoteWorks, let info = userInfo else { return }

        let newTitle = info["Name"] as? String ?? ""
        let newArtist = info["Artist"] as? String ?? ""
        let newAlbum = info["Album"] as? String ?? ""
        let state = info["Player State"] as? String ?? ""

        if newTitle != title { title = newTitle }
        if newArtist != artist { artist = newArtist }
        if newAlbum != album { album = newAlbum }
        isPlaying = (state == "Playing")

        if let totalTime = info["Total Time"] as? Double {
            duration = totalTime / 1000.0
        }

        fetchArtworkAsync(from: "Music")
    }

    private func handleSpotifyNotification(_ userInfo: [AnyHashable: Any]?) {
        guard !mediaRemoteWorks, let info = userInfo else { return }

        let newTitle = info["Name"] as? String ?? ""
        let newArtist = info["Artist"] as? String ?? ""
        let newAlbum = info["Album"] as? String ?? ""
        let state = info["Player State"] as? String ?? ""

        if newTitle != title { title = newTitle }
        if newArtist != artist { artist = newArtist }
        if newAlbum != album { album = newAlbum }
        isPlaying = (state == "Playing")

        if let durationMs = info["Duration"] as? Int {
            duration = TimeInterval(durationMs) / 1000.0
        }

        fetchArtworkAsync(from: "Spotify")
    }

    private func fetchArtworkAsync(from app: String) {
        Task.detached(priority: .userInitiated) { [weak self] in
            let image: NSImage?
            if app == "Spotify" {
                image = Self.fetchSpotifyArtwork()
            } else {
                image = Self.fetchMusicArtwork()
            }
            if let image {
                await MainActor.run {
                    self?.artworkImage = image
                }
            }
        }
    }

    private static nonisolated func fetchSpotifyArtwork() -> NSImage? {
        let script = """
        tell application "Spotify"
            if it is running then
                return artwork url of current track
            end if
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        guard error == nil, let urlString = result.stringValue,
              let url = URL(string: urlString),
              let data = try? Data(contentsOf: url) else { return nil }
        return NSImage(data: data)
    }

    private static nonisolated func fetchMusicArtwork() -> NSImage? {
        let script = """
        tell application "Music"
            if it is running then
                try
                    return raw data of artwork 1 of current track
                end try
            end if
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        guard error == nil else { return nil }
        return NSImage(data: result.data)
    }
}
