import AppKit

@MainActor
final class MouseTracker {
    private weak var window: NotchWindow?
    private weak var viewModel: NotchViewModel?
    private var moveMonitor: Any?
    private var scrollMonitor: Any?
    private var localScrollMonitor: Any?
    private var collapseWorkItem: DispatchWorkItem?
    private var hoverZone: NSRect = .zero

    init(window: NotchWindow, viewModel: NotchViewModel) {
        self.window = window
        self.viewModel = viewModel
    }

    func install(notchRect: NSRect) {
        hoverZone = notchRect.insetBy(dx: -20, dy: -15)

        // Global mouse move monitor
        moveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleMouseMoved()
            }
        }

        // Global scroll monitor (two-finger swipe)
        scrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleScroll(event)
            }
        }

        // Local scroll monitor (when window accepts events)
        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleScroll(event)
            }
            return event
        }
    }

    func uninstall() {
        if let moveMonitor { NSEvent.removeMonitor(moveMonitor) }
        if let scrollMonitor { NSEvent.removeMonitor(scrollMonitor) }
        if let localScrollMonitor { NSEvent.removeMonitor(localScrollMonitor) }
        moveMonitor = nil
        scrollMonitor = nil
        localScrollMonitor = nil
        collapseWorkItem?.cancel()
    }

    private func handleMouseMoved() {
        guard let window, let viewModel else { return }

        let mouseLocation = NSEvent.mouseLocation

        // Quick exit: is mouse near the top of screen?
        guard let screen = ScreenHelper.notchScreen() else { return }
        let topThreshold = screen.frame.maxY - 200
        guard mouseLocation.y > topThreshold else {
            scheduleCollapse(viewModel: viewModel, window: window)
            return
        }

        let effectiveZone: NSRect
        if viewModel.isExpanded {
            effectiveZone = window.frame.insetBy(dx: -30, dy: -30)
        } else {
            effectiveZone = hoverZone
        }

        if effectiveZone.contains(mouseLocation) {
            collapseWorkItem?.cancel()
            collapseWorkItem = nil

            if viewModel.state == .collapsed {
                viewModel.state = .hovering
            }
        } else {
            scheduleCollapse(viewModel: viewModel, window: window)
        }
    }

    private func handleScroll(_ event: NSEvent) {
        guard let window, let viewModel else { return }

        let mouseLocation = NSEvent.mouseLocation

        // Only respond to scroll near the notch
        let effectiveZone: NSRect
        if viewModel.isExpanded {
            effectiveZone = window.frame.insetBy(dx: -30, dy: -30)
        } else {
            effectiveZone = hoverZone.insetBy(dx: -20, dy: -20)
        }

        guard effectiveZone.contains(mouseLocation) else { return }

        // Two-finger swipe: deltaY < 0 = swipe down (natural scrolling)
        let threshold: CGFloat = 3.0

        if event.scrollingDeltaY < -threshold && !viewModel.isExpanded {
            // Swipe down → expand
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            viewModel.state = .expanded
            window.ignoresMouseEvents = false
        } else if event.scrollingDeltaY > threshold && viewModel.isExpanded {
            // Swipe up → collapse
            viewModel.state = .collapsed
            window.ignoresMouseEvents = true
        }
    }

    private func scheduleCollapse(viewModel: NotchViewModel, window: NotchWindow) {
        guard viewModel.state != .collapsed, collapseWorkItem == nil else { return }

        let delay: TimeInterval = viewModel.isExpanded ? 0.5 : 0.15

        let workItem = DispatchWorkItem { [weak viewModel, weak window] in
            MainActor.assumeIsolated {
                viewModel?.state = .collapsed
                window?.ignoresMouseEvents = true
            }
        }
        collapseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}
