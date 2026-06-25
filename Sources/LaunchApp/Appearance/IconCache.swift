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

final class IconCache: @unchecked Sendable {
    private let limit = 160
    private var icons: [String: NSImage] = [:]
    private var recentPaths: [String] = []

    @MainActor
    func icon(for app: LaunchApp, size: CGFloat = LaunchConstants.Launcher.maxIconSize) -> NSImage {
        if let cached = icons[app.path] {
            markRecent(app.path)
            return cached
        }

        let image = NSWorkspace.shared.icon(forFile: app.path)
        let pixelSize = size * 2
        image.size = NSSize(width: pixelSize, height: pixelSize)
        icons[app.path] = image
        markRecent(app.path)
        evictIfNeeded()
        return image
    }

    @MainActor func clear() {
        icons.removeAll()
        recentPaths.removeAll()
    }

    private func markRecent(_ path: String) {
        recentPaths.removeAll { $0 == path }
        recentPaths.append(path)
    }

    private func evictIfNeeded() {
        while icons.count > limit, let oldest = recentPaths.first {
            recentPaths.removeFirst()
            icons.removeValue(forKey: oldest)
        }
    }
}
