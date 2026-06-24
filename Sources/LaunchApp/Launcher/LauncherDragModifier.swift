import SwiftUI

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

