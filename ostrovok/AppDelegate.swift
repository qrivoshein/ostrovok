import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var notchManager: NotchManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupNotch()
    }

    private func setupNotch() {
        let manager = NotchManager()
        manager.setup()
        self.notchManager = manager
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "sparkles",
                accessibilityDescription: "Ostrovok"
            )
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Ostrovok v0.1", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        statusItem?.menu = menu
    }
}
