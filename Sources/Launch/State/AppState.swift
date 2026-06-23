import Foundation
import LaunchCore

@MainActor
final class AppState: ObservableObject {
    @Published var apps: [LaunchApp] = []
    @Published var folders: [LaunchFolder] = []
    @Published var query = "" {
        didSet { currentPage = 0 }
    }
    @Published var currentPage = 0
    @Published var draggedAppID: String?
    @Published var openFolder: LaunchFolder?
    @Published var launchAtLogin = false
    @Published var loginItemError: String?
    @Published var accessibilityTrusted = false
    @Published private var order: [String] = []

    private let pageSize = 35
    private let layoutKey = "layoutOrder"
    private let foldersKey = "folders"
    var closeLauncher: (() -> Void)?
    var dismissLauncher: (() -> Void)?

    init() {
        loadFolders()
        order = savedOrder()
        refreshLoginItemStatus()
        refreshAccessibilityStatus()
        refreshApps()
    }

    var visibleApps: [LaunchApp] {
        guard !query.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var visibleItems: [LauncherItem] {
        if !query.isEmpty {
            return visibleApps.map(LauncherItem.app)
        }

        let folderedIDs = Set(folders.flatMap(\.appIDs))
        let rootApps = apps.filter { !folderedIDs.contains($0.id) }
        let appItems = rootApps.map { LauncherItem.app($0) }
        let folderItems = folders.map { folder in
            LauncherItem.folder(folder, folder.appIDs.compactMap(appByID))
        }
        let allItems = appItems + folderItems
        let byID = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
        let ordered = order.compactMap { byID[$0] }
        let orderedIDs = Set(ordered.map(\.id))
        return ordered + allItems.filter { !orderedIDs.contains($0.id) }
    }

    var pageCount: Int {
        max(1, Int(ceil(Double(visibleItems.count) / Double(pageSize))))
    }

    var pageItems: [LauncherItem] {
        Array(visibleItems.dropFirst(currentPage * pageSize).prefix(pageSize))
    }

    func refreshApps() {
        apps = AppCatalog.scan()
        saveOrder()
    }

    func launch(_ app: LaunchApp) {
        AppSystemAdapter.launch(app)
        dismissLauncher?()
    }

    func move(_ id: String, before targetID: String) {
        let nextOrder = LayoutOrder.move(id, before: targetID, in: visibleItems.map(\.id))
        saveOrder(nextOrder)
    }

    func createFolder(draggedID: String, targetID: String) {
        guard folders.allSatisfy({ !$0.appIDs.contains(draggedID) && !$0.appIDs.contains(targetID) }) else {
            return
        }

        let result = FolderLayout.createFolder(
            id: "folder-\(UUID().uuidString)",
            draggedID: draggedID,
            targetID: targetID,
            folders: folders,
            order: visibleItems.map(\.id)
        )
        folders = result.folders
        saveFolders()
        saveOrder(result.order)
        openFolder = folders.last
    }

    func appByID(_ id: String) -> LaunchApp? {
        apps.first { $0.id == id }
    }

    func closeFolder() {
        openFolder = nil
    }

    func apps(in folder: LaunchFolder) -> [LaunchApp] {
        folder.appIDs.compactMap(appByID)
    }

    func itemName(_ id: String) -> String {
        appByID(id)?.name ?? id
    }

    func saveOrder(_ order: [String]? = nil) {
        self.order = order ?? visibleItems.map(\.id)
        LayoutPersistenceAdapter.set(self.order, forKey: layoutKey)
    }

    func refreshLoginItemStatus() {
        launchAtLogin = LoginItemAdapter.isEnabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        loginItemError = nil

        do {
            try LoginItemAdapter.setEnabled(enabled)
        } catch {
            loginItemError = error.localizedDescription
        }

        refreshLoginItemStatus()
    }

    func refreshAccessibilityStatus() {
        accessibilityTrusted = AccessibilityAdapter.isTrusted
    }

    func requestAccessibilityPermission() {
        accessibilityTrusted = AccessibilityAdapter.requestPermission()
    }

    func changePage(_ delta: Int) {
        currentPage = min(max(currentPage + delta, 0), pageCount - 1)
    }

    func dropApp(_ draggedID: String, on targetID: String) {
        if draggedID == targetID { return }

        if appByID(targetID) != nil, appByID(draggedID) != nil {
            createFolder(draggedID: draggedID, targetID: targetID)
        } else {
            move(draggedID, before: targetID)
        }
    }

    private func loadFolders() {
        guard let data = LayoutPersistenceAdapter.data(forKey: foldersKey),
              let decoded = try? JSONDecoder().decode([LaunchFolder].self, from: data) else { return }
        folders = decoded
    }

    private func saveFolders() {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        LayoutPersistenceAdapter.set(data, forKey: foldersKey)
    }

    private func savedOrder() -> [String] {
        LayoutPersistenceAdapter.stringArray(forKey: layoutKey)
    }
}
