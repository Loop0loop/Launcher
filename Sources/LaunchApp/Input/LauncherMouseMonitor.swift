import AppKit

/// Empty-space page swiping only. Icon dragging is owned by SwiftUI `DragGesture`
/// (see `LauncherDragModifier`); dismissal and folder close are owned by SwiftUI tap layers.
/// When an icon drag is active (`isDraggingLauncherItem`) paging backs off so the grid
/// doesn't shift under the dragged tile.
@MainActor
final class LauncherMouseMonitor {
    private weak var window: NSWindow?
    private weak var state: AppState?
    private var monitor: Any?
    private var isEnabled = false

    private var tracking = false
    private var dragOffset: CGFloat = 0
    private var dragStartPage = 0
    private var pageLockedUntil = Date.distantPast

    func configure(window: NSWindow, state: AppState) {
        self.window = window
        self.state = state
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self else { return event }
            return self.handle(event)
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled { reset() }
    }

    func stop() {
        setEnabled(false)
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func reset() {
        tracking = false
        dragOffset = 0
        state?.pageDragOffset = 0
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard isEnabled, let window, let state else { return event }
        guard state.launcherVisible, window.isVisible, event.window === window else { return event }
        switch event.type {
        case .leftMouseDown: return down(event, state)
        case .leftMouseDragged: return dragged(event, state)
        case .leftMouseUp: return up(event, state)
        default: return event
        }
    }

    private func down(_ event: NSEvent, _ state: AppState) -> NSEvent? {
        guard state.openFolder == nil, state.query.isEmpty, state.displayMode == .paged, Date() >= pageLockedUntil else {
            tracking = false
            return event
        }
        tracking = true
        dragOffset = 0
        dragStartPage = state.currentPage
        state.pageDragOffset = 0
        return event
    }

    private func dragged(_ event: NSEvent, _ state: AppState) -> NSEvent? {
        guard tracking else { return event }
        // A SwiftUI icon drag has taken over — stop paging so the grid doesn't shift.
        if state.isDraggingLauncherItem {
            reset()
            return event
        }
        dragOffset += event.deltaX
        let pageWidth = window?.frame.width ?? 0
        guard pageWidth > 0 else { return event }

        let maxRubber = pageWidth * LaunchConstants.Launcher.pageRubberBandRatio
        if dragStartPage == 0, dragOffset > 0 { dragOffset = min(dragOffset, maxRubber) }
        if dragStartPage == state.pageCount - 1, dragOffset < 0 { dragOffset = max(dragOffset, -maxRubber) }
        state.pageDragOffset = dragOffset
        return event
    }

    private func up(_ event: NSEvent, _ state: AppState) -> NSEvent? {
        defer { reset() }
        guard tracking, !state.isDraggingLauncherItem else { return event }
        let pageWidth = window?.frame.width ?? 0
        guard abs(dragOffset) >= LaunchConstants.Launcher.dragMinimumDistance, pageWidth > 0 else { return event }

        let threshold = max(pageWidth * LaunchConstants.Launcher.pageSwipeThresholdRatio, LaunchConstants.Launcher.pageDragThreshold)
        var target = dragStartPage
        if dragOffset < -threshold {
            target = min(dragStartPage + 1, state.pageCount - 1)
        } else if dragOffset > threshold {
            target = max(dragStartPage - 1, 0)
        }
        if target != dragStartPage {
            state.selectPage(target)
            pageLockedUntil = Date().addingTimeInterval(LaunchConstants.Launcher.pageChangeCooldown)
        }
        return event
    }
}
