import Foundation

struct GridLayoutSettings: Equatable, Hashable, Codable, Identifiable {
    let columns: Int
    let rows: Int

    var id: String {
        "\(columns)x\(rows)"
    }

    var label: String {
        id
    }

    var pageSize: Int {
        columns * rows
    }

    static let classic = GridLayoutSettings(columns: 7, rows: 5)
    static let presets = [
        classic,
        GridLayoutSettings(columns: 8, rows: 5),
        GridLayoutSettings(columns: 8, rows: 6)
    ]
}

enum GridLayoutStore {
    static func load() -> GridLayoutSettings {
        guard let data = UserDefaults.standard.data(forKey: LaunchConstants.Storage.gridLayoutKey),
              let decoded = try? JSONDecoder().decode(GridLayoutSettings.self, from: data),
              GridLayoutSettings.presets.contains(decoded) else { return .classic }
        return decoded
    }

    static func save(_ settings: GridLayoutSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: LaunchConstants.Storage.gridLayoutKey)
    }
}
