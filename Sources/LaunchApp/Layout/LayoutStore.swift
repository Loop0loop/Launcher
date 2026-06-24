import Foundation
import LaunchCore

enum LayoutStore {
    static func loadOrder() -> [String] {
        UserDefaults.standard.stringArray(forKey: LaunchConstants.Storage.layoutOrderKey) ?? []
    }

    static func saveOrder(_ order: [String]) {
        UserDefaults.standard.set(order, forKey: LaunchConstants.Storage.layoutOrderKey)
    }

    static func loadFolders() -> [LaunchFolder] {
        guard let data = UserDefaults.standard.data(forKey: LaunchConstants.Storage.foldersKey),
              let decoded = try? JSONDecoder().decode([LaunchFolder].self, from: data) else { return [] }
        return decoded
    }

    static func saveFolders(_ folders: [LaunchFolder]) {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        UserDefaults.standard.set(data, forKey: LaunchConstants.Storage.foldersKey)
    }

    static func cleanup(folders: [LaunchFolder], order: [String], validAppIDs: Set<String>) -> (folders: [LaunchFolder], order: [String]) {
        LayoutCleanup.cleanup(folders: folders, order: order, validAppIDs: validAppIDs)
    }
}
