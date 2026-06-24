import CoreGraphics
import Foundation
import LaunchCore

@MainActor
final class AppState: ObservableObject {
    @Published var apps: [LaunchApp] = []
    @Published var folders: [LaunchFolder] = []
    @Published var query = "" {
        didSet {
            handleQueryChange(oldValue: oldValue)
        }
    }
    @Published var currentPage = 0
    @Published var selectedItemID: String?
    @Published var keyboardSelectionActive = false
    @Published var draggedAppID: String?
    @Published var openFolder: LaunchFolder?
    @Published var launchAtLogin = false
    @Published var loginItemError: String?
    @Published var accessibilityTrusted = false
    @Published var accessibilityState: PermissionState = .unknown
    @Published var globalHotKeyState: PermissionState = .unknown
    @Published var f4KeyState: PermissionState = .unknown
    @Published var trackpadGateState: TrackpadGateState = .unknown
    @Published var launcherVisible = false
    @Published var pageDragOffset: CGFloat = 0
    let searchFocus = SearchFocusController()
    @Published var appSourcePaths = AppSourceStore.load()
    @Published var hiddenAppIDs = Set(LayoutPersistenceAdapter.stringArray(forKey: LaunchConstants.Storage.hiddenAppsKey))
    @Published var gridLayout = GridLayoutStore.load() {
        didSet {
            guard oldValue != gridLayout else { return }
            GridLayoutStore.save(gridLayout)
            currentPage = min(currentPage, pageCount - 1)
            ensureSelection()
        }
    }
    @Published var displayMode = LauncherDisplayModeStore.load() {
        didSet {
            guard oldValue != displayMode else { return }
            LauncherDisplayModeStore.save(displayMode)
            currentPage = 0
        }
    }
    @Published var windowBrowsingMode = UserDefaults.standard.bool(forKey: LaunchConstants.Storage.windowBrowsingModeKey) {
        didSet {
            guard oldValue != windowBrowsingMode else { return }
            UserDefaults.standard.set(windowBrowsingMode, forKey: LaunchConstants.Storage.windowBrowsingModeKey)
            actions.applyWindowBrowsingMode()
        }
    }
    @Published var appearance = AppearanceStore.load() {
        didSet {
            guard oldValue != appearance else { return }
            AppearanceStore.save(appearance)
        }
    }
    @Published var showMenuBarIcon = (UserDefaults.standard.object(forKey: LaunchConstants.Storage.showMenuBarIconKey) as? Bool) ?? true {
        didSet {
            guard oldValue != showMenuBarIcon else { return }
            UserDefaults.standard.set(showMenuBarIcon, forKey: LaunchConstants.Storage.showMenuBarIconKey)
            actions.applyMenuBarVisibility()
        }
    }
    @Published var appIcon = AppIconOption.load() {
        didSet {
            guard oldValue != appIcon else { return }
            appIcon.save()
            actions.applyAppIcon()
        }
    }
    @Published var sortMode = SortMode.load() {
        didSet {
            guard oldValue != sortMode else { return }
            sortMode.save()
            if sortMode == .name { applyNameSort() }
        }
    }
    @Published var order: [String] = []

    let layoutStore = LayoutStore()
    var pageBeforeSearch = 0
    var selectionBeforeSearch: String?
    var pageChangeLockedUntil = Date.distantPast
    var folderReopenLockedUntil = Date.distantPast
    var actions = LauncherActions()

    init() {
        folders = layoutStore.loadFolders()
        order = layoutStore.loadOrder()
        refreshLoginItemStatus()
        refreshAccessibilityStatus()
        refreshApps()
    }

}
