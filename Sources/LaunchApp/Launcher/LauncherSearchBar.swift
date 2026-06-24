import AppKit
import SwiftUI

/// Single AppKit search bar — chrome, icon, field, and clear button share one hit target.
final class LauncherSearchBarView: NSView {
    let textField = LauncherSearchNSTextField()
    private let iconView = NSImageView()
    private let clearButton = NSButton()
    private let chromeView = NSVisualEffectView()
    private var onTextChange: ((String) -> Void)?
    private var onClear: (() -> Void)?

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func configureHandlers(onTextChange: @escaping (String) -> Void, onClear: @escaping () -> Void) {
        self.onTextChange = onTextChange
        self.onClear = onClear
    }

    private func configure() {
        wantsLayer = true

        chromeView.material = .hudWindow
        chromeView.blendingMode = .withinWindow
        chromeView.state = .active
        chromeView.wantsLayer = true
        chromeView.layer?.cornerRadius = LaunchConstants.Launcher.searchHeight / 2
        chromeView.layer?.masksToBounds = true
        addSubview(chromeView)

        if let icon = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil) {
            iconView.image = icon
            iconView.contentTintColor = NSColor.white.withAlphaComponent(0.7)
            iconView.imageScaling = .scaleProportionallyDown
        }
        addSubview(iconView)

        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.isEditable = true
        textField.isSelectable = true
        textField.isEnabled = true
        textField.placeholderString = LaunchConstants.Launcher.searchPlaceholder
        textField.font = NSFont.systemFont(ofSize: LaunchConstants.Launcher.searchFontSize, weight: .regular)
        textField.textColor = .white
        textField.placeholderAttributedString = NSAttributedString(
            string: LaunchConstants.Launcher.searchPlaceholder,
            attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.55)]
        )
        textField.target = self
        textField.action = #selector(textDidChange)
        addSubview(textField)

        clearButton.isBordered = false
        clearButton.bezelStyle = .inline
        clearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear")
        clearButton.imagePosition = .imageOnly
        clearButton.contentTintColor = NSColor.white.withAlphaComponent(0.55)
        clearButton.target = self
        clearButton.action = #selector(clearTapped)
        clearButton.isHidden = true
        addSubview(clearButton)
    }

    override func layout() {
        super.layout()
        chromeView.frame = bounds

        let padding = LaunchConstants.Launcher.searchHorizontalPadding
        let iconSide: CGFloat = 16
        iconView.frame = NSRect(x: padding, y: (bounds.height - iconSide) / 2, width: iconSide, height: iconSide)

        let clearSide: CGFloat = 18
        clearButton.frame = NSRect(
            x: bounds.width - padding - clearSide,
            y: (bounds.height - clearSide) / 2,
            width: clearSide,
            height: clearSide
        )

        let textX = iconView.frame.maxX + 8
        let textWidth = max(0, clearButton.frame.minX - 8 - textX)
        textField.frame = NSRect(x: textX, y: 0, width: textWidth, height: bounds.height)
    }

    func updateText(_ text: String) {
        if textField.stringValue != text {
            textField.stringValue = text
        }
        clearButton.isHidden = text.isEmpty
    }

    @objc private func textDidChange() {
        clearButton.isHidden = textField.stringValue.isEmpty
        onTextChange?(textField.stringValue)
    }

    @objc private func clearTapped() {
        textField.stringValue = ""
        clearButton.isHidden = true
        onClear?()
        onTextChange?("")
        window?.makeFirstResponder(textField)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(textField)
        LaunchLog.line("search bar mouseDown")
        super.mouseDown(with: event)
    }
}

struct LauncherSearchBarRepresentable: NSViewRepresentable {
    @Binding var text: String
    var onBarReady: (LauncherSearchBarView) -> Void

    func makeNSView(context: Context) -> LauncherSearchBarView {
        let bar = LauncherSearchBarView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: LaunchConstants.Launcher.searchWidth,
                height: LaunchConstants.Launcher.searchHeight
            )
        )
        bar.textField.delegate = context.coordinator
        bar.configureHandlers(
            onTextChange: { context.coordinator.text = $0 },
            onClear: { context.coordinator.text = "" }
        )
        bar.updateText(text)
        onBarReady(bar)
        return bar
    }

    func updateNSView(_ bar: LauncherSearchBarView, context: Context) {
        bar.updateText(text)
        onBarReady(bar)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            text = field.stringValue
        }
    }
}

final class LauncherSearchNSTextField: NSTextField {
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        (window as? LauncherWindow)?.allowsKeyboardFocus = true
        window?.makeKey()
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        // Editing ended — drop key focus so the launcher stops holding the keyboard.
        if resigned, let window = window as? LauncherWindow {
            window.allowsKeyboardFocus = false
            window.resignKey()
        }
        return resigned
    }
}
