import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    let iconCache = IconCache()
    let trackpadMonitor = TrackpadGestureMonitor()
    var window: NSWindow?
    var launcherLifecycle: LauncherLifecycle?
    var settingsWindow: NSWindow?
    var statusItem: NSStatusItem?
    private lazy var statusMenu: NSMenu = makeStatusMenu()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        makeWindow()
        makeStatusItem()
        state.requestAccessibilityPermission()
        startTrackpadMonitor()
    }

    func makeWindow() {
        let frame = NSScreen.main?.frame ?? LaunchConstants.App.fallbackWindowFrame
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        let rootView = LauncherView(state: state).environment(\.iconCache, iconCache)
        let hosting = NSHostingView(rootView: rootView)
        hosting.safeAreaRegions = []
        window.contentView = hosting
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .mainMenu
        self.window = window
        launcherLifecycle = LauncherLifecycle(state: state, window: window)
        state.closeLauncher = { [weak self] in self?.launcherLifecycle?.hide() }
        state.dismissLauncher = { [weak self] in self?.launcherLifecycle?.dismiss() }
        state.launchApp = { [weak self] app in self?.launcherLifecycle?.launch(app) }
    }

    func makeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }
        button.title = LaunchConstants.App.menuBarTitle
        button.target = self
        button.action = #selector(statusBarClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    func makeStatusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: LaunchConstants.Menu.toggle, action: #selector(toggleLauncher), keyEquivalent: LaunchConstants.Menu.toggleKey)
        menu.addItem(withTitle: LaunchConstants.Menu.settings, action: #selector(showSettings), keyEquivalent: LaunchConstants.Menu.settingsKey)
        menu.addItem(withTitle: LaunchConstants.Menu.refreshApps, action: #selector(refreshApps), keyEquivalent: LaunchConstants.Menu.refreshKey)
        menu.addItem(.separator())
        menu.addItem(withTitle: LaunchConstants.Menu.quit, action: #selector(NSApp.terminate), keyEquivalent: LaunchConstants.Menu.quitKey)
        return menu
    }

    @objc func statusBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            toggleLauncher()
            return
        }

        if event.type == .rightMouseUp {
            statusMenu.popUp(
                positioning: nil,
                at: NSPoint(x: 0, y: sender.bounds.height + 4),
                in: sender
            )
            return
        }

        toggleLauncher()
    }

    @objc func toggleLauncher() {
        launcherLifecycle?.toggle()
    }

    @objc func refreshApps() {
        state.refreshApps()
        iconCache.clear()
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: .init(x: 0, y: 0, width: LaunchConstants.Settings.width, height: LaunchConstants.Settings.height),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = LaunchConstants.App.settingsTitle
            window.contentView = NSHostingView(rootView: SettingsView(state: state))
            settingsWindow = window
        }

        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func startTrackpadMonitor() {
        trackpadMonitor.start { [weak self] isActive in
            self?.state.setTrackpadGateActive(isActive)
        } onIntent: { [weak self] intent in
            guard let self else { return }
            switch intent {
            case .open:
                self.launcherLifecycle?.show()
            case .close:
                if self.launcherLifecycle?.isVisible == true {
                    self.launcherLifecycle?.hide()
                }
            case .previousPage:
                if self.launcherLifecycle?.isVisible == true {
                    self.state.changePage(-1)
                }
            case .nextPage:
                if self.launcherLifecycle?.isVisible == true {
                    self.state.changePage(1)
                }
            }
        }
    }
}
