import AppKit

/// Dock/app icon choice. Backed by the icon assets bundled in Resources.
enum AppIconOption: String, CaseIterable, Identifiable {
    case launch
    case launchBlack

    var id: String { rawValue }
    var title: String {
        switch self {
        case .launch: return "Launch"
        case .launchBlack: return "Launch black"
        }
    }
    private var resourceName: String {
        switch self {
        case .launch: return "Launch"
        case .launchBlack: return "Launch_black"
        }
    }

    func image() -> NSImage? {
        if let url = Self.resourceURL(named: resourceName, extension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        return nil
    }

    static func load() -> AppIconOption {
        switch UserDefaults.standard.string(forKey: LaunchConstants.Storage.appIconKey) {
        case AppIconOption.launchBlack.rawValue, "mono":
            return .launchBlack
        default:
            return .launch
        }
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: LaunchConstants.Storage.appIconKey)
    }

    static func resourceURL(named name: String, extension fileExtension: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
            return url
        }

        let cwdURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let devURL = cwdURL.appendingPathComponent("Resources").appendingPathComponent("\(name).\(fileExtension)")
        if FileManager.default.fileExists(atPath: devURL.path) { return devURL }

        let publicURL = cwdURL.appendingPathComponent("public").appendingPathComponent("\(name).\(fileExtension)")
        return FileManager.default.fileExists(atPath: publicURL.path) ? publicURL : nil
    }

}

/// Grid ordering mode. `.name` keeps the grid alphabetized; `.custom` is manual drag order.
enum SortMode: String, CaseIterable, Identifiable {
    case custom
    case name

    var id: String { rawValue }
    var title: String { self == .custom ? Localized.t("사용자 지정", "Custom") : Localized.t("이름순", "Name") }

    static func load() -> SortMode {
        SortMode(rawValue: UserDefaults.standard.string(forKey: LaunchConstants.Storage.sortModeKey) ?? "") ?? .custom
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: LaunchConstants.Storage.sortModeKey)
    }
}
