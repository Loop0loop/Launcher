import AppKit
import LaunchCore
import SwiftUI

@MainActor
final class IconCache: ObservableObject {
    private var icons: [String: NSImage] = [:]

    func icon(for app: LaunchApp) -> NSImage {
        if let icon = icons[app.path] { return icon }
        let icon = NSWorkspace.shared.icon(forFile: app.path)
        icons[app.path] = icon
        return icon
    }
}
