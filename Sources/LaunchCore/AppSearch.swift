import Foundation

public enum AppSearch {
    public static func rankedApps(_ apps: [LaunchApp], matching query: String) -> [LaunchApp] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return apps }

        return apps.compactMap { app -> (LaunchApp, Int)? in
            guard let rank = rank(app, query: normalizedQuery) else { return nil }
            return (app, rank)
        }
        .sorted {
            if $0.1 != $1.1 { return $0.1 < $1.1 }
            return $0.0.name.localizedStandardCompare($1.0.name) == .orderedAscending
        }
        .map(\.0)
    }

    private static func rank(_ app: LaunchApp, query: String) -> Int? {
        let name = normalize(app.name)
        let id = normalize(app.id)
        let fileName = normalize(URL(fileURLWithPath: app.path).deletingPathExtension().lastPathComponent)

        if name.hasPrefix(query) { return 0 }
        if name.contains(query) { return 1 }
        if id.contains(query) { return 2 }
        if fileName.contains(query) { return 3 }
        return nil
    }

    private static func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
