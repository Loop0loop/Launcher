import LaunchCore

enum CatalogStore {
    static func scanApps() -> [LaunchApp] {
        AppCatalog.scan()
    }
}

