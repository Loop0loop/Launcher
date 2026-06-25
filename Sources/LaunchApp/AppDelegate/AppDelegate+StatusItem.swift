import AppKit

extension AppDelegate {
    func makeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else {
            LaunchLog.line("status item button missing")
            return
        }
        if let icon = menuBarImage() {
            button.image = icon
            button.title = ""
        } else {
            button.title = LaunchConstants.App.menuBarTitle
        }
        button.target = self
        button.action = #selector(statusBarClicked(_:))
        button.sendAction(on: [.leftMouseUp])
        startStatusRightClickMonitor(for: button)
        LaunchLog.line("status item ready")
    }

    func applyMenuBarVisibility() {
        if state.showMenuBarIcon {
            if statusItem == nil { makeStatusItem() }
        } else if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    func applyAppIcon() {
        if let image = state.appIcon.image() {
            NSApp.applicationIconImage = image
        }
        if let image = menuBarImage(), let button = statusItem?.button {
            button.image = image
            button.title = ""
        }
    }

    private func menuBarImage() -> NSImage? {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        defer { image.unlockFocus() }
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: 18, height: 18).fill()

        switch state.appIcon {
        case .launch:
            drawLaunchMenuBarGlyph()
        case .launchBlack:
            drawLaunchBlackMenuBarGlyph()
        }

        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = false
        return image
    }

    private func drawLaunchMenuBarGlyph() {
        NSColor.white.setFill()
        let size: CGFloat = 3.7
        let radius: CGFloat = 1
        let points: [NSPoint] = [
            NSPoint(x: 3.2, y: 11.6), NSPoint(x: 7.15, y: 11.6), NSPoint(x: 11.1, y: 11.6),
            NSPoint(x: 3.2, y: 7.65), NSPoint(x: 7.15, y: 7.65), NSPoint(x: 11.1, y: 7.65),
            NSPoint(x: 3.2, y: 3.7), NSPoint(x: 7.15, y: 3.7), NSPoint(x: 11.1, y: 3.7)
        ]
        for point in points {
            NSBezierPath(
                roundedRect: NSRect(x: point.x, y: point.y, width: size, height: size),
                xRadius: radius,
                yRadius: radius
            ).fill()
        }
    }

    private func drawLaunchBlackMenuBarGlyph() {
        NSColor.white.setStroke()
        let lineWidth: CGFloat = 1.6
        let width: CGFloat = 6.1
        let height: CGFloat = 3.6
        let centers: [(point: NSPoint, angle: CGFloat)] = [
            (NSPoint(x: 5.8, y: 12.0), -45),
            (NSPoint(x: 12.2, y: 12.0), 45),
            (NSPoint(x: 5.8, y: 6.0), 45),
            (NSPoint(x: 12.2, y: 6.0), -45)
        ]
        for item in centers {
            // Rotate around item.point: translate to it, rotate, translate back.
            var transform = AffineTransform(translationByX: item.point.x, byY: item.point.y)
            transform.rotate(byDegrees: item.angle)
            transform.translate(x: -item.point.x, y: -item.point.y)
            let rect = NSRect(
                x: item.point.x - width / 2,
                y: item.point.y - height / 2,
                width: width,
                height: height
            )
            let path = NSBezierPath(roundedRect: rect, xRadius: height / 2, yRadius: height / 2)
            path.transform(using: transform)
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    func makeStatusMenu() -> NSMenu {
        let menu = NSMenu()
        addStatusMenuItem(menu, title: LaunchConstants.Menu.toggle, action: #selector(toggleLauncher), key: LaunchConstants.Menu.toggleKey)
        addStatusMenuItem(menu, title: LaunchConstants.Menu.settings, action: #selector(showSettings), key: LaunchConstants.Menu.settingsKey)
        addStatusMenuItem(menu, title: LaunchConstants.Menu.checkForUpdates, action: #selector(checkForUpdates), key: LaunchConstants.Menu.checkForUpdatesKey)
        addStatusMenuItem(menu, title: LaunchConstants.Menu.refreshApps, action: #selector(refreshApps), key: LaunchConstants.Menu.refreshKey)
        addStatusMenuItem(menu, title: LaunchConstants.Menu.sortByName, action: #selector(sortAppsByName), key: LaunchConstants.Menu.sortByNameKey)
        menu.addItem(.separator())
        let quit = menu.addItem(withTitle: LaunchConstants.Menu.quit, action: #selector(NSApp.terminate), keyEquivalent: LaunchConstants.Menu.quitKey)
        quit.target = NSApp
        return menu
    }

    private func addStatusMenuItem(_ menu: NSMenu, title: String, action: Selector, key: String) {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
        item.target = self
    }

    @objc nonisolated func statusBarClicked(_ sender: NSStatusBarButton) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                LaunchLog.line("status bar action dropped self")
                return
            }
            LaunchLog.line("status bar left click")
            handleToggleLauncher()
        }
    }

    func startStatusRightClickMonitor(for button: NSStatusBarButton) {
        statusRightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .rightMouseUp]) { [weak self, weak button] event in
            guard let self, let button, event.window === button.window else { return event }
            let point = button.convert(event.locationInWindow, from: nil)
            guard button.bounds.contains(point) else { return event }
            if event.type == .rightMouseUp {
                LaunchLog.line("status bar right click")
                statusMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
            }
            return nil
        }
    }

    @objc nonisolated func toggleLauncher() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            handleToggleLauncher()
        }
    }

    func handleToggleLauncher() {
        LaunchLog.line("toggle launcher requested")
        launcherLifecycle?.toggle()
    }

    @objc nonisolated func refreshApps() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            handleRefreshApps()
        }
    }

    func handleRefreshApps() {
        state.refreshAppsAsync()
        iconCache.clear()
    }

    @objc nonisolated func checkForUpdates() {
        DispatchQueue.main.async { [weak self] in
            self?.updater.checkForUpdates()
        }
    }

    @objc nonisolated func sortAppsByName() {
        DispatchQueue.main.async { [weak self] in
            self?.handleSortAppsByName()
        }
    }

    private func handleSortAppsByName() {
        state.sortMode = .name
        state.applyNameSort()
    }
}
