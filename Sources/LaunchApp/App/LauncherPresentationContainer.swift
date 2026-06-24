import AppKit

/// Borderless windows can't become key by default, which blocks keyboard focus on the
/// native search field. Override so the launcher can become key and accept typing.
final class LauncherWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
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
