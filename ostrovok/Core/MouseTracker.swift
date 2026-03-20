import AppKit

@MainActor
final class MouseTracker {
    private weak var window: NotchWindow?
    private weak var viewModel: NotchViewModel?
    private var monitor: Any?
    private var collapseWorkItem: DispatchWorkItem?
    private var hoverZone: NSRect = .zero

    init(window: NotchWindow, viewModel: NotchViewModel) {
        self.window = window
        self.viewModel = viewModel
    }

    func install(notchRect: NSRect) {
        hoverZone = notchRect.insetBy(dx: -30, dy: -30)

        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleMouseMoved(event)
            }
        }
    }

    func uninstall() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        collapseWorkItem?.cancel()
    }

    private func handleMouseMoved(_ event: NSEvent) {
        guard let window, let viewModel else { return }

        let mouseLocation = NSEvent.mouseLocation

        // Quick check: is the mouse near the top of the screen?
        guard let screen = ScreenHelper.notchScreen() else { return }
        let topThreshold = screen.frame.maxY - 150
        guard mouseLocation.y > topThreshold else {
            scheduleCollapse(viewModel: viewModel, window: window)
            return
        }

        let effectiveZone: NSRect
        if viewModel.isExpanded {
            effectiveZone = window.frame.insetBy(dx: -20, dy: -20)
        } else {
            effectiveZone = hoverZone
        }

        if effectiveZone.contains(mouseLocation) {
            collapseWorkItem?.cancel()
            collapseWorkItem = nil

            if !viewModel.isExpanded {
                viewModel.state = .expanded
                window.ignoresMouseEvents = false
            }
        } else {
            scheduleCollapse(viewModel: viewModel, window: window)
        }
    }

    private func scheduleCollapse(viewModel: NotchViewModel, window: NotchWindow) {
        guard viewModel.isExpanded, collapseWorkItem == nil else { return }

        let workItem = DispatchWorkItem { [weak viewModel, weak window] in
            MainActor.assumeIsolated {
                viewModel?.state = .collapsed
                window?.ignoresMouseEvents = true
            }
        }
        collapseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
}
