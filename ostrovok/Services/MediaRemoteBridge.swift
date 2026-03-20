import Foundation

enum MediaRemoteBridge {
    typealias GetNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    typealias GetIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    typealias RegisterNotificationsFn = @convention(c) (DispatchQueue) -> Void
    typealias SendCommandFn = @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool

    private static let handle: UnsafeMutableRawPointer? = {
        dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY)
    }()

    static let getNowPlayingInfo: GetNowPlayingInfoFn? = {
        guard let handle, let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else { return nil }
        return unsafeBitCast(sym, to: GetNowPlayingInfoFn.self)
    }()

    static let getIsPlaying: GetIsPlayingFn? = {
        guard let handle, let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") else { return nil }
        return unsafeBitCast(sym, to: GetIsPlayingFn.self)
    }()

    static let registerForNotifications: RegisterNotificationsFn? = {
        guard let handle, let sym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") else { return nil }
        return unsafeBitCast(sym, to: RegisterNotificationsFn.self)
    }()

    static let sendCommand: SendCommandFn? = {
        guard let handle, let sym = dlsym(handle, "MRMediaRemoteSendCommand") else { return nil }
        return unsafeBitCast(sym, to: SendCommandFn.self)
    }()

    // Info dictionary keys
    static let keyTitle = "kMRMediaRemoteNowPlayingInfoTitle"
    static let keyArtist = "kMRMediaRemoteNowPlayingInfoArtist"
    static let keyAlbum = "kMRMediaRemoteNowPlayingInfoAlbum"
    static let keyArtwork = "kMRMediaRemoteNowPlayingInfoArtworkData"
    static let keyDuration = "kMRMediaRemoteNowPlayingInfoDuration"
    static let keyElapsedTime = "kMRMediaRemoteNowPlayingInfoElapsedTime"

    // Notification names
    static let infoDidChange = Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
    static let isPlayingDidChange = Notification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")

    // Command constants
    static let commandTogglePlayPause: UInt32 = 2
    static let commandNextTrack: UInt32 = 4
    static let commandPreviousTrack: UInt32 = 5
}
