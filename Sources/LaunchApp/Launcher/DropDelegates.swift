import SwiftUI

struct AppDropDelegate: DropDelegate {
    let targetID: String
    var state: AppState

    func dropEntered(info: DropInfo) {
        if let dragged = state.draggedAppID {
            LaunchLog.line("app drop entered dragged=\(dragged) target=\(targetID)")
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        if let dragged = state.draggedAppID {
            LaunchLog.line("app drop perform dragged=\(dragged) target=\(targetID)")
            state.dropApp(dragged, on: targetID)
        }
        state.draggedAppID = nil
        return true
    }
}

struct FolderDropDelegate: DropDelegate {
    let targetID: String
    var state: AppState

    func dropEntered(info: DropInfo) {
        if let dragged = state.draggedAppID {
            LaunchLog.line("folder drop entered dragged=\(dragged) target=\(targetID)")
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        if let dragged = state.draggedAppID {
            LaunchLog.line("folder drop perform dragged=\(dragged) target=\(targetID)")
            state.dropApp(dragged, on: targetID)
        }
        state.draggedAppID = nil
        return true
    }
}
