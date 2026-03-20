import AppKit
import SwiftUI

@MainActor
final class NotchManager {
    private var notchWindow: NotchWindow?
    private var mouseTracker: MouseTracker?
    private let viewModel = NotchViewModel()

    func setup() {
        guard let screen = ScreenHelper.notchScreen(),
              let notchRect = ScreenHelper.notchRect(for: screen),
              let notchSize = ScreenHelper.notchSize(for: screen) else {
            print("[Ostrovok] No notch detected")
            return
        }

        viewModel.notchSize = notchSize

        let maxExpandedWidth = notchSize.width + 240
        let maxExpandedHeight = notchSize.height + 140
        let windowRect = NSRect(
            x: notchRect.midX - maxExpandedWidth / 2,
            y: notchRect.maxY - maxExpandedHeight,
            width: maxExpandedWidth,
            height: maxExpandedHeight
        )

        let window = NotchWindow(contentRect: windowRect)
        let hostingView = NSHostingView(
            rootView: NotchContentView(viewModel: viewModel)
                .ignoresSafeArea()
        )
        window.contentView = hostingView
        window.orderFrontRegardless()
        self.notchWindow = window

        let tracker = MouseTracker(window: window, viewModel: viewModel)
        tracker.install(notchRect: notchRect)
        self.mouseTracker = tracker

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.screenDidChange()
        }

        viewModel.start()

        print("[Ostrovok] Notch overlay active: \(notchSize.width)x\(notchSize.height)")
    }

    private func screenDidChange() {
        mouseTracker?.uninstall()
        mouseTracker = nil
        notchWindow?.orderOut(nil)
        notchWindow = nil
        setup()
    }
}
