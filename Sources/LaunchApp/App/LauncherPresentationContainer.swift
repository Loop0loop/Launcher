import AppKit

/// Borderless windows can't become key by default, which blocks keyboard focus on the
/// native search field. We only allow key focus while the user is actively editing the
/// search field (set on click, cleared when editing ends) so the launcher doesn't sit
/// on the keyboard the rest of the time.
final class LauncherWindow: NSWindow {
    var allowsKeyboardFocus = false
    override var canBecomeKey: Bool { allowsKeyboardFocus }
    override var canBecomeMain: Bool { allowsKeyboardFocus }
}

/// Hosts SwiftUI content and receives open/close scale animation without breaking hit testing inside `NSHostingView`.
final class LauncherPresentationContainer: NSView {
    override var isFlipped: Bool { true }

    override func layout() {
        super.layout()
        for subview in subviews {
            subview.frame = bounds
        }
        updateLayerPosition()
    }

    func updateLayerPosition() {
        guard wantsLayer, let layer else { return }
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }
}
