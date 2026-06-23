public enum LayoutCleanup {
    public static func cleanup(folders: [LaunchFolder], order: [String], validAppIDs: Set<String>) -> (folders: [LaunchFolder], order: [String]) {
        let cleanedFolders = folders.compactMap { folder -> LaunchFolder? in
            let appIDs = folder.appIDs.filter(validAppIDs.contains)
            guard !appIDs.isEmpty else { return nil }
            var next = folder
            next.appIDs = appIDs
            return next
        }
        let validItemIDs = validAppIDs.union(cleanedFolders.map(\.id))
        return (cleanedFolders, order.filter(validItemIDs.contains))
    }
}

