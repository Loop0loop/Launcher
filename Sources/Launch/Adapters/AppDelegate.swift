import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    let trackpadMonitor = TrackpadGestureMonitor()
    var window: NSWindow?
    var settingsWindow: NSWindow?
    var statusItem: NSStatusItem?
    var previousApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        makeWindow()
        makeStatusItem()
        state.closeLauncher = { [weak self] in self?.hideLauncher() }
        state.dismissLauncher = { [weak self] in self?.dismissLauncher() }
        state.requestAccessibilityPermission()
        startTrackpadMonitor()
    }

    func makeWindow() {
        let frame = NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 1440, height: 900)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: LauncherView(state: state))
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .mainMenu
        self.window = window
    }

    func makeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.title = "L"
        let menu = NSMenu()
        menu.addItem(withTitle: "Toggle Launch", action: #selector(toggleLauncher), keyEquivalent: "l")
        menu.addItem(withTitle: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        menu.addItem(withTitle: "Refresh Apps", action: #selector(refreshApps), keyEquivalent: "r")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc func toggleLauncher() {
        if window?.isVisible == true {
            hideLauncher()
        } else {
            showLauncher()
        }
    }

    func showLauncher() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.processIdentifier != NSRunningApplication.current.processIdentifier {
            previousApp = frontmost
        }
        state.query = ""
        window?.setFrame(NSScreen.main?.frame ?? window?.frame ?? .zero, display: true)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hideLauncher() {
        dismissLauncher()
        if #available(macOS 14.0, *) {
            previousApp?.activate()
        } else {
            previousApp?.activate(options: [.activateIgnoringOtherApps])
        }
    }

    func dismissLauncher() {
        window?.orderOut(nil)
    }

    @objc func refreshApps() {
        state.refreshApps()
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: .init(x: 0, y: 0, width: 360, height: 180),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Launch Settings"
            window.contentView = NSHostingView(rootView: SettingsView(state: state))
            settingsWindow = window
        }

        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func startTrackpadMonitor() {
        trackpadMonitor.start { [weak self] intent in
            guard let self else { return }
            switch intent {
            case .open:
                self.showLauncher()
            case .close:
                self.hideLauncher()
            case .previousPage:
                self.state.changePage(-1)
            case .nextPage:
                self.state.changePage(1)
            }
        }
    }
}

