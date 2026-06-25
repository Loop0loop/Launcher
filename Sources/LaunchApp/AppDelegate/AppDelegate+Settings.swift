import AppKit
import SwiftUI

extension AppDelegate {
    @objc nonisolated func showSettings() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            handleShowSettings()
        }
    }

    private func handleShowSettings() {
        // Settings floats above the launcher instead of dismissing it, and the trackpad
        // monitor keeps running so the launcher can still be opened while Settings is up.
        state.refreshAccessibilityStatus()
        state.refreshLoginItemStatus()

        if settingsWindow == nil {
            let window = NSPanel(
                contentRect: .init(
                    x: 0,
                    y: 0,
                    width: LaunchConstants.Settings.width,
                    height: LaunchConstants.Settings.height
                ),
                styleMask: [.titled, .closable, .fullSizeContentView, .utilityWindow],
                backing: .buffered,
                defer: false
            )
            window.title = LaunchConstants.App.settingsTitle
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.hasShadow = true
            window.isFloatingPanel = true
            window.becomesKeyOnlyIfNeeded = false
            // Above the launcher (which sits at .screenSaver) so Settings stays on top
            // even when the launcher is reopened behind it.
            window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
            window.delegate = self
            let hosting = NSHostingView(rootView: SettingsView(state: state))
            hosting.safeAreaRegions = []
            window.contentView = hosting
            settingsWindow = window
        }

        settingsWindow?.center()

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === settingsWindow else { return }
        startTrackpadMonitor()
    }

    func chooseAppSource() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = LaunchConstants.Settings.addAppSource

        if panel.runModal() == .OK, let url = panel.url {
            state.addAppSource(url.path)
        }
    }
}
