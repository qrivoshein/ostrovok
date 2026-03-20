import AppKit

@MainActor
final class MouseTracker {
    private weak var window: NotchWindow?
    private weak var viewModel: NotchViewModel?
    private var globalMoveMonitor: Any?
    private var localMoveMonitor: Any?
    private var globalScrollMonitor: Any?
    private var localScrollMonitor: Any?
    private var collapseWorkItem: DispatchWorkItem?
    private var notchRect: NSRect = .zero
    private var scrollAccumulator: CGFloat = 0
    private var lastScrollTime: TimeInterval = 0

    init(window: NotchWindow, viewModel: NotchViewModel) {
        self.window = window
        self.viewModel = viewModel
    }

    func install(notchRect: NSRect) {
        self.notchRect = notchRect

        // Global monitors: fire when mouse is outside our window
        globalMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleMouseMoved() }
        }

        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            MainActor.assumeIsolated { self?.handleScroll(event) }
        }

        // Local monitors: fire when mouse is inside our window (expanded state)
        localMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            MainActor.assumeIsolated { self?.handleMouseMoved() }
            return event
        }

        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            MainActor.assumeIsolated { self?.handleScroll(event) }
            return event
        }
    }

    func uninstall() {
        for monitor in [globalMoveMonitor, localMoveMonitor, globalScrollMonitor, localScrollMonitor] {
            if let m = monitor { NSEvent.removeMonitor(m) }
        }
        globalMoveMonitor = nil
        localMoveMonitor = nil
        globalScrollMonitor = nil
        localScrollMonitor = nil
        collapseWorkItem?.cancel()
    }

    // MARK: - Mouse Move

    private func handleMouseMoved() {
        guard let window, let viewModel else { return }
        let mouse = NSEvent.mouseLocation

        guard let screen = ScreenHelper.notchScreen() else { return }
        let topThreshold = screen.frame.maxY - 250
        guard mouse.y > topThreshold else {
            scheduleCollapse(viewModel: viewModel, window: window)
            return
        }

        let zone: NSRect
        if viewModel.isExpanded {
            zone = window.frame.insetBy(dx: -20, dy: -20)
        } else {
            // Hover zone: notch area + generous padding
            zone = notchRect.insetBy(dx: -30, dy: -20)
        }

        if zone.contains(mouse) {
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            if viewModel.state == .collapsed {
                viewModel.state = .hovering
            }
        } else {
            scheduleCollapse(viewModel: viewModel, window: window)
        }
    }

    // MARK: - Scroll Gesture

    private func handleScroll(_ event: NSEvent) {
        guard let window, let viewModel else { return }
        let mouse = NSEvent.mouseLocation

        // Wide scroll detection: notch area + 60pt padding all around
        let scrollZone: NSRect
        if viewModel.isExpanded {
            scrollZone = window.frame.insetBy(dx: -50, dy: -50)
        } else {
            scrollZone = notchRect.insetBy(dx: -60, dy: -40)
        }

        guard scrollZone.contains(mouse) else { return }

        // Reset accumulator if too much time has passed
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastScrollTime > 0.4 {
            scrollAccumulator = 0
        }
        lastScrollTime = now

        // Use raw scrollingDeltaY directly:
        // Positive deltaY = content scrolls down = "swipe down" intent
        // Negative deltaY = content scrolls up = "swipe up" intent
        let fingerDelta = event.scrollingDeltaY

        scrollAccumulator += fingerDelta

        // Swipe down (positive accumulated) → expand
        // Swipe up (negative accumulated) → collapse
        if scrollAccumulator > 2.0 && !viewModel.isExpanded {
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            viewModel.state = .expanded
            window.ignoresMouseEvents = false
            scrollAccumulator = 0
        } else if scrollAccumulator < -2.0 && viewModel.isExpanded {
            viewModel.state = .collapsed
            window.ignoresMouseEvents = true
            scrollAccumulator = 0
        }
    }

    // MARK: - Collapse

    private func scheduleCollapse(viewModel: NotchViewModel, window: NotchWindow) {
        guard viewModel.state != .collapsed, collapseWorkItem == nil else { return }

        let delay: TimeInterval = viewModel.isExpanded ? 0.4 : 0.1

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
