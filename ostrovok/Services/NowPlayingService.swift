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
    private var mediaRemoteWorks = false

    func start() {
        setupMediaRemote()
        setupDistributedNotifications()
    }

    func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.forEach { DistributedNotificationCenter.default().removeObserver($0) }
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

    // MARK: - MediaRemote (may be blocked on macOS 15.4+)

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

    // MARK: - Distributed Notifications fallback (Apple Music, Spotify)

    private func setupDistributedNotifications() {
        let dnc = DistributedNotificationCenter.default()

        // Apple Music / iTunes
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

        // Spotify
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
        duration = info["Total Time"] as? TimeInterval ?? 0

        fetchArtwork(from: "Music")
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

        fetchArtwork(from: "Spotify")
    }

    private func fetchArtwork(from app: String) {
        let script: String
        if app == "Spotify" {
            script = """
            tell application "Spotify"
                if it is running then
                    return artwork url of current track
                end if
            end tell
            """
        } else {
            script = """
            tell application "Music"
                if it is running then
                    try
                        set artData to raw data of artwork 1 of current track
                        return artData
                    end try
                end if
            end tell
            """
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if app == "Spotify" {
                self?.fetchSpotifyArtwork(script: script)
            } else {
                self?.fetchMusicArtwork(script: script)
            }
        }
    }

    private nonisolated func fetchSpotifyArtwork(script: String) {
        guard let appleScript = NSAppleScript(source: script) else { return }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        guard error == nil, let urlString = result.stringValue,
              let url = URL(string: urlString) else { return }

        guard let data = try? Data(contentsOf: url),
              let image = NSImage(data: data) else { return }

        MainActor.assumeIsolated {
            self.artworkImage = image
        }
    }

    private nonisolated func fetchMusicArtwork(script: String) {
        guard let appleScript = NSAppleScript(source: script) else { return }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        guard error == nil else { return }
        let data = result.data
        guard let image = NSImage(data: data) else { return }

        MainActor.assumeIsolated {
            self.artworkImage = image
        }
    }
}
