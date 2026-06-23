import Foundation

public struct LaunchApp: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let path: String

    public init(id: String, name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
    }
}

public enum AppCatalog {
    public static func defaultRoots(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [URL] {
        [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            home.appendingPathComponent("Applications")
        ]
    }

    public static func scan(roots: [URL] = defaultRoots()) -> [LaunchApp] {
        let fm = FileManager.default
        var seen = Set<String>()
        var apps: [LaunchApp] = []

        for root in roots where fm.fileExists(atPath: root.path) {
            guard let files = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in files where url.pathExtension == "app" {
                let bundle = Bundle(url: url)
                let key = bundle?.bundleIdentifier ?? url.standardizedFileURL.path
                guard seen.insert(key).inserted else { continue }

                apps.append(LaunchApp(
                    id: key,
                    name: displayName(for: url, bundle: bundle),
                    path: url.path
                ))
            }
        }

        return apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public static func displayName(for url: URL, bundle: Bundle? = nil) -> String {
        let info = bundle?.localizedInfoDictionary ?? bundle?.infoDictionary
        return info?["CFBundleDisplayName"] as? String
            ?? info?["CFBundleName"] as? String
            ?? url.deletingPathExtension().lastPathComponent
    }
}

