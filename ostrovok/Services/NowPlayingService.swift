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
    private var progressTimer: Timer?
    private var lastArtworkTitle: String = ""

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
                self.updateTrackInfo(info)
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

    private func updateTrackInfo(_ info: [String: Any]) {
        let newTitle = info[MediaRemoteBridge.keyTitle] as? String ?? ""
        let newArtist = info[MediaRemoteBridge.keyArtist] as? String ?? ""
        let newAlbum = info[MediaRemoteBridge.keyAlbum] as? String ?? ""

        if !newTitle.isEmpty {
            if newTitle != title { title = newTitle }
            if newArtist != artist { artist = newArtist }
            if newAlbum != album { album = newAlbum }
        }

        duration = info[MediaRemoteBridge.keyDuration] as? TimeInterval ?? duration
        elapsedTime = info[MediaRemoteBridge.keyElapsedTime] as? TimeInterval ?? elapsedTime

        // Try MediaRemote artwork first
        if let artworkData = info[MediaRemoteBridge.keyArtwork] as? Data,
           let image = NSImage(data: artworkData) {
            artworkImage = image
            lastArtworkTitle = title
        } else if title != lastArtworkTitle && !title.isEmpty {
            // MediaRemote didn't provide artwork — try AppleScript
            fetchArtworkViaAppleScript()
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
                    self?.handlePlayerNotification(notification.userInfo, app: "Music")
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
                    self?.handlePlayerNotification(notification.userInfo, app: "Spotify")
                }
            }
        )
    }

    private func handlePlayerNotification(_ userInfo: [AnyHashable: Any]?, app: String) {
        guard let info = userInfo else { return }

        let newTitle = info["Name"] as? String ?? ""
        let newArtist = info["Artist"] as? String ?? ""
        let newAlbum = info["Album"] as? String ?? ""
        let state = info["Player State"] as? String ?? ""

        if !newTitle.isEmpty {
            if newTitle != title { title = newTitle }
            if newArtist != artist { artist = newArtist }
            if newAlbum != album { album = newAlbum }
        }

        isPlaying = (state == "Playing")

        if app == "Spotify", let durationMs = info["Duration"] as? Int {
            duration = TimeInterval(durationMs) / 1000.0
        } else if let totalTime = info["Total Time"] as? Double {
            duration = totalTime / 1000.0
        }

        // Always try artwork on track change
        if newTitle != lastArtworkTitle && !newTitle.isEmpty {
            fetchArtworkViaAppleScript()
        }
    }

    // MARK: - Artwork via AppleScript

    private func fetchArtworkViaAppleScript() {
        let currentTitle = title
        Task.detached(priority: .userInitiated) { [weak self] in
            // Try Spotify first, then Music
            let image = Self.fetchSpotifyArtwork() ?? Self.fetchMusicArtwork()
            await MainActor.run {
                guard let self else { return }
                if let image {
                    self.artworkImage = image
                    self.lastArtworkTitle = currentTitle
                }
            }
        }
    }

    private static nonisolated func fetchSpotifyArtwork() -> NSImage? {
        let script = """
        tell application "System Events"
            if not (exists process "Spotify") then return ""
        end tell
        tell application "Spotify"
            return artwork url of current track
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        guard error == nil, let urlString = result.stringValue,
              !urlString.isEmpty,
              let url = URL(string: urlString),
              let data = try? Data(contentsOf: url) else { return nil }
        return NSImage(data: data)
    }

    private static nonisolated func fetchMusicArtwork() -> NSImage? {
        let script = """
        tell application "System Events"
            if not (exists process "Music") then return ""
        end tell
        tell application "Music"
            try
                return raw data of artwork 1 of current track
            end try
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        guard error == nil else { return nil }
        let data = result.data
        guard !data.isEmpty else { return nil }
        return NSImage(data: data)
    }
}
