import AppKit

enum ScreenHelper {
    static func hasNotch(_ screen: NSScreen) -> Bool {
        screen.safeAreaInsets.top > 0
    }

    static func notchSize(for screen: NSScreen) -> NSSize? {
        guard hasNotch(screen),
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea else {
            return nil
        }
        let width = right.minX - left.maxX
        let height = screen.safeAreaInsets.top
        return NSSize(width: width, height: height)
    }

    static func notchRect(for screen: NSScreen) -> NSRect? {
        guard let size = notchSize(for: screen),
              let left = screen.auxiliaryTopLeftArea else {
            return nil
        }
        let x = screen.frame.origin.x + left.maxX
        let y = screen.frame.maxY - size.height
        return NSRect(origin: NSPoint(x: x, y: y), size: size)
    }

    static func notchScreen() -> NSScreen? {
        NSScreen.screens.first { hasNotch($0) }
    }
}
