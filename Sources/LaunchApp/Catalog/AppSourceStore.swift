import Foundation

enum AppSourceStore {
    static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: LaunchConstants.Storage.appSourcesKey) ?? []
    }

    static func save(_ paths: [String]) {
        UserDefaults.standard.set(paths, forKey: LaunchConstants.Storage.appSourcesKey)
    }
}
