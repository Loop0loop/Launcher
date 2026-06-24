import CoreGraphics
import SwiftUI

/// Gesture-based live drag for the launcher grid. Replaces OS drag-and-drop
/// (NSItemProvider/onDrop) so the pasteboard is never used — dragging an icon can
/// never interact with other apps. A drop onto another icon creates/extends a folder;
/// a drop into a gap reorders. (cf. native Launchpad, macos-launchy.)
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

    /// Commit the drag: folder-merge when released on a different icon, else reorder.
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

    /// Maps a pointer location (in the `"launcherGrid"` coordinate space) to the item under
    /// it. `onIconID` is non-nil only when the pointer is over the icon's central box
    /// (folder-merge intent); `slotID` is the cell's item regardless (reorder target).
    func dropResolution(at location: CGPoint, layout: LaunchpadLayoutMetrics) -> (onIconID: String?, slotID: String?) {
        let items = items(forPage: currentPage)
        guard location.y >= 0 else { return (nil, nil) }
        let pitchX = layout.columnWidth + layout.gridColumnSpacing
        let x = location.x - layout.horizontalPadding
        guard x >= 0 else { return (nil, nil) }
        let col = Int(x / pitchX)
        let row = Int(location.y / layout.rowHeight)
        guard col >= 0, col < layout.columns, row >= 0, row < layout.rows else { return (nil, nil) }
        let index = row * layout.columns + col
        guard index < items.count else { return (nil, nil) }
        let id = items[index].id

        let cellCenterX = layout.horizontalPadding + CGFloat(col) * pitchX + layout.columnWidth / 2
        let cellCenterY = CGFloat(row) * layout.rowHeight + layout.rowHeight / 2
        let onIcon = abs(location.x - cellCenterX) < layout.iconSize / 2
            && abs(location.y - cellCenterY) < layout.iconSize / 2
        return (onIcon ? id : nil, id)
    }
}

/// Applies the lift/follow visual + drag gesture to a grid icon. The grid container must
/// declare `.coordinateSpace(name: "launcherGrid")`.
struct LauncherDragModifier: ViewModifier {
    let id: String
    @ObservedObject var state: AppState
    let layout: LaunchpadLayoutMetrics

    func body(content: Content) -> some View {
        let isDragging = state.draggingItemID == id
        let isMergeTarget = state.dragHoverTargetID == id
        return content
            .scaleEffect(isDragging ? 1.12 : (isMergeTarget ? 1.16 : 1))
            .opacity(isDragging ? 0.9 : 1)
            .offset(isDragging ? state.dragTranslation : .zero)
            .zIndex(isDragging ? 100 : 0)
            .animation(LaunchConstants.Animation.quick, value: isMergeTarget)
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named("launcherGrid"))
                    .onChanged { value in
                        if state.draggingItemID == nil { state.beginItemDrag(id) }
                        let resolved = state.dropResolution(at: value.location, layout: layout)
                        state.updateItemDrag(translation: value.translation, hoveredID: resolved.onIconID)
                    }
                    .onEnded { value in
                        let resolved = state.dropResolution(at: value.location, layout: layout)
                        state.endItemDrag(onIconID: resolved.onIconID, slotID: resolved.slotID)
                    }
            )
    }
}

extension View {
    func launcherDrag(id: String, state: AppState, layout: LaunchpadLayoutMetrics) -> some View {
        modifier(LauncherDragModifier(id: id, state: state, layout: layout))
    }
}
