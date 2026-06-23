import AppKit
import LaunchCore
import SwiftUI

@MainActor
final class LauncherLifecycle {
    private let state: AppState
    private let window: NSWindow
    private var previousApp: NSRunningApplication?
    private var dismissToken = 0

    init(state: AppState, window: NSWindow) {
        self.state = state
        self.window = window
    }

    var isVisible: Bool {
        window.isVisible
    }

    func toggle() {
        if isVisible, state.launcherVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        if isVisible, state.launcherVisible { return }

        dismissToken += 1
        rememberPreviousApp()

        state.query = ""
        state.closeFolder()
        window.setFrame(NSScreen.main?.frame ?? window.frame, display: true)
        window.alphaValue = 1
        state.launcherVisible = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        withAnimation(LaunchConstants.Animation.showSpring) {
            state.launcherVisible = true
        }
    }

    func hide() {
        guard isVisible else { return }
        animatedDismiss(restorePreviousApp: true)
    }

    func animatedDismiss(restorePreviousApp: Bool = false) {
        dismissToken += 1
        let token = dismissToken

        withAnimation(LaunchConstants.Animation.hideSpring) {
            state.launcherVisible = false
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(LaunchConstants.Lifecycle.hideDuration * 1_000_000_000))
            guard token == self.dismissToken else { return }
            self.dismiss()
            if restorePreviousApp {
                self.activatePreviousApp()
            }
        }
    }

    func dismiss() {
        state.launcherVisible = false
        window.orderOut(nil)
    }

    func launch(_ app: LaunchApp) {
        AppSystemAdapter.launch(app)
        animatedDismiss(restorePreviousApp: false)
    }

    private func rememberPreviousApp() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.processIdentifier != NSRunningApplication.current.processIdentifier {
            previousApp = frontmost
        }
    }

    private func activatePreviousApp() {
        if #available(macOS 14.0, *) {
            previousApp?.activate()
        } else {
            previousApp?.activate(options: [.activateIgnoringOtherApps])
        }
    }
}
