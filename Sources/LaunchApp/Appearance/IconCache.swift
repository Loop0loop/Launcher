import AppKit
import LaunchCore
import SwiftUI

private struct IconCacheKey: EnvironmentKey {
    static let defaultValue: IconCache = IconCache()
}

extension EnvironmentValues {
    var iconCache: IconCache {
        get { self[IconCacheKey.self] }
        set { self[IconCacheKey.self] = newValue }
    }
}

@MainActor
final class IconCache {
    private var icons: [String: NSImage] = [:]

    func icon(for app: LaunchApp, size: CGFloat = LaunchConstants.Launcher.maxIconSize) -> NSImage {
        if let cached = icons[app.path] { return cached }

        let image = NSWorkspace.shared.icon(forFile: app.path)
        let pixelSize = size * 2
        image.size = NSSize(width: pixelSize, height: pixelSize)
        icons[app.path] = image
        return image
    }

    func preload(apps: [LaunchApp], size: CGFloat = LaunchConstants.Launcher.maxIconSize) {
        let paths = apps.map { $0.path }
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            for path in paths {
                let cached = await MainActor.run {
                    self.icons[path] != nil
                }
                if cached { continue }
                
                let image = NSWorkspace.shared.icon(forFile: path)
                let pixelSize = size * 2
                image.size = NSSize(width: pixelSize, height: pixelSize)
                
                await MainActor.run {
                    self.icons[path] = image
                }
            }
        }
    }

    func clear() {
        icons.removeAll()
    }
}
