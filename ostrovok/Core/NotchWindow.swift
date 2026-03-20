import AppKit

final class NotchWindow: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) - 1)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true

        isFloatingPanel = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false

        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        acceptsMouseMovedEvents = true
    }

    // Prevent macOS from constraining the window below the menu bar
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
