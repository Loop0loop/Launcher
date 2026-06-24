import AppKit

/// Dock/app icon choice. Backed by the icon assets bundled in Resources.
enum AppIconOption: String, CaseIterable, Identifiable {
    case color
    case mono

    var id: String { rawValue }
    var title: String { self == .color ? "Color" : "Mono" }
    private var resourceName: String { self == .color ? "AppIconColor" : "AppIconMono" }

    func image() -> NSImage? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }

    static func load() -> AppIconOption {
        AppIconOption(rawValue: UserDefaults.standard.string(forKey: LaunchConstants.Storage.appIconKey) ?? "") ?? .color
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: LaunchConstants.Storage.appIconKey)
    }
}

/// Grid ordering mode. `.name` keeps the grid alphabetized; `.custom` is manual drag order.
enum SortMode: String, CaseIterable, Identifiable {
    case custom
    case name

    var id: String { rawValue }
    var title: String { self == .custom ? "Custom" : "Name" }

    static func load() -> SortMode {
        SortMode(rawValue: UserDefaults.standard.string(forKey: LaunchConstants.Storage.sortModeKey) ?? "") ?? .custom
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: LaunchConstants.Storage.sortModeKey)
    }
}
