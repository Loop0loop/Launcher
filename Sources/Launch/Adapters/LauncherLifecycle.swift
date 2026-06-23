import AppKit
import LaunchCore

@MainActor
final class LauncherLifecycle {
    private let state: AppState
    private let window: NSWindow
    private var previousApp: NSRunningApplication?

    init(state: AppState, window: NSWindow) {
        self.state = state
        self.window = window
    }

    var isVisible: Bool {
        window.isVisible
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.processIdentifier != NSRunningApplication.current.processIdentifier {
            previousApp = frontmost
        }

        state.query = ""
        window.setFrame(NSScreen.main?.frame ?? window.frame, display: true)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        dismiss()
        if #available(macOS 14.0, *) {
            previousApp?.activate()
        } else {
            previousApp?.activate(options: [.activateIgnoringOtherApps])
        }
    }

    func dismiss() {
        window.orderOut(nil)
    }

    func launch(_ app: LaunchApp) {
        AppSystemAdapter.launch(app)
        dismiss()
    }
}

