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
    private var scrollAccumulator: CGFloat = 0
    private var lastScrollTime: TimeInterval = 0

    init(window: NotchWindow, viewModel: NotchViewModel) {
        self.window = window
        self.viewModel = viewModel
    }

    func install(notchRect: NSRect) {
        // Generous hover zone around the notch
        hoverZone = notchRect.insetBy(dx: -25, dy: -20)

        moveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleMouseMoved()
            }
        }

        scrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleScroll(event)
            }
        }

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

    // MARK: - Mouse

    private func handleMouseMoved() {
        guard let window, let viewModel else { return }

        let mouseLocation = NSEvent.mouseLocation
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

    // MARK: - Scroll (two-finger gesture)

    private func handleScroll(_ event: NSEvent) {
        guard let window, let viewModel else { return }

        let mouseLocation = NSEvent.mouseLocation

        // Wide detection zone: entire notch area + generous padding
        let scrollZone: NSRect
        if viewModel.isExpanded {
            scrollZone = window.frame.insetBy(dx: -40, dy: -40)
        } else {
            scrollZone = hoverZone.insetBy(dx: -40, dy: -40)
        }

        guard scrollZone.contains(mouseLocation) else { return }

        // Accumulate scroll delta over a short time window
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastScrollTime > 0.3 {
            scrollAccumulator = 0
        }
        lastScrollTime = now

        // Determine physical finger direction:
        // We want physical finger-down to expand, finger-up to collapse.
        // With natural scrolling (isDirectionInvertedFromDevice=true):
        //   finger down → scrollingDeltaY < 0
        // Without natural scrolling:
        //   finger down → scrollingDeltaY > 0
        let delta = event.scrollingDeltaY
        let physicalDelta: CGFloat
        if event.isDirectionInvertedFromDevice {
            physicalDelta = -delta  // invert back to physical direction
        } else {
            physicalDelta = delta
        }

        scrollAccumulator += physicalDelta

        let expandThreshold: CGFloat = 4.0
        let collapseThreshold: CGFloat = 4.0

        if scrollAccumulator > expandThreshold && !viewModel.isExpanded {
            // Physical finger down → expand
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            viewModel.state = .expanded
            window.ignoresMouseEvents = false
            scrollAccumulator = 0
        } else if scrollAccumulator < -collapseThreshold && viewModel.isExpanded {
            // Physical finger up → collapse
            viewModel.state = .collapsed
            window.ignoresMouseEvents = true
            scrollAccumulator = 0
        }
    }

    // MARK: - Collapse

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
