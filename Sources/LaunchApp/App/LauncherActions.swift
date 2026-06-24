import LaunchCore

@MainActor
struct LauncherActions {
    var close: () -> Void = {}
    var dismiss: () -> Void = {}
    var launch: (LaunchApp) -> Void = { _ in }
    var showInFinder: (LaunchApp) -> Void = { _ in }
    var moveToTrash: (LaunchApp) -> Void = { _ in }
    var addToDock: (LaunchApp) -> Void = { _ in }
    var chooseAppSource: () -> Void = {}
    var applyWindowBrowsingMode: () -> Void = {}
}
