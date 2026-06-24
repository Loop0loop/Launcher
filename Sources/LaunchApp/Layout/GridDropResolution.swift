import CoreGraphics
import LaunchCore
import SwiftUI

enum LauncherItem: Identifiable {
    case app(LaunchApp)
    case folder(LaunchFolder, [LaunchApp])

    var id: String {
        switch self {
        case .app(let app): app.id
        case .folder(let folder, _): folder.id
        }
    }
}

struct GridDropResolution {
    let onIconID: String?
    let slotID: String?
}

extension AppState {
    var isDraggingLauncherItem: Bool { draggingItemID != nil }

    func beginItemDrag(_ id: String) {
        guard query.isEmpty, openFolder == nil else { return }
        draggingItemID = id
        dragTranslation = .zero
        dragHoverTargetID = nil
    }

    func updateItemDrag(translation: CGSize, hoveredID: String?) {
        guard let dragging = draggingItemID else { return }
        dragTranslation = translation
        dragHoverTargetID = (hoveredID != nil && hoveredID != dragging) ? hoveredID : nil
    }

    func endItemDrag(onIconID: String?, slotID: String?) {
        defer { cancelDrag() }
        guard let dragged = draggingItemID, query.isEmpty, openFolder == nil else { return }

        if let target = onIconID, target != dragged {
            let draggedIsApp = appByID(dragged) != nil
            if draggedIsApp, appByID(target) != nil {
                createFolder(draggedID: dragged, targetID: target)
                return
            }
            if draggedIsApp, folders.contains(where: { $0.id == target }) {
                addApp(dragged, toFolder: target)
                return
            }
        }

        if let slot = slotID, slot != dragged {
            move(dragged, before: slot)
        }
    }

    func cancelDrag() {
        draggingItemID = nil
        dragHoverTargetID = nil
        dragTranslation = .zero
    }

    /// Maps a pointer location (in the `"launcherGrid"` coordinate space) to the item under it.
    func dropResolution(at location: CGPoint, layout: LaunchpadLayoutMetrics) -> GridDropResolution {
        let items = items(forPage: currentPage)
        guard location.y >= 0 else { return GridDropResolution(onIconID: nil, slotID: nil) }
        let pitchX = layout.columnWidth + layout.gridColumnSpacing
        let x = location.x - layout.horizontalPadding
        guard x >= 0 else { return GridDropResolution(onIconID: nil, slotID: nil) }
        let col = Int(x / pitchX)
        let row = Int(location.y / layout.rowHeight)
        guard col >= 0, col < layout.columns, row >= 0, row < layout.rows else {
            return GridDropResolution(onIconID: nil, slotID: nil)
        }
        let index = row * layout.columns + col
        guard index < items.count else { return GridDropResolution(onIconID: nil, slotID: nil) }
        let id = items[index].id

        let cellCenterX = layout.horizontalPadding + CGFloat(col) * pitchX + layout.columnWidth / 2
        let cellCenterY = CGFloat(row) * layout.rowHeight + layout.rowHeight / 2
        let onIcon = abs(location.x - cellCenterX) < layout.iconSize / 2
            && abs(location.y - cellCenterY) < layout.iconSize / 2
        return GridDropResolution(onIconID: onIcon ? id : nil, slotID: id)
    }
}
