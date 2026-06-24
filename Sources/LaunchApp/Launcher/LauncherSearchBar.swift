import AppKit
import SwiftUI

/// Single AppKit search bar — chrome, icon, field, and clear button share one hit target.
final class LauncherSearchBarView: NSView {
    let textField = LauncherSearchNSTextField()
    private let iconView = NSImageView()
    private let clearButton = NSButton()
    private let contentView = NSView()
    private var chromeView: NSView?
    private var glassChromeView: NSView?
    private var visualChromeView: NSVisualEffectView?
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

        configureChrome()

        if let icon = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil) {
            iconView.image = icon
            iconView.contentTintColor = NSColor.white.withAlphaComponent(0.7)
            iconView.imageScaling = .scaleProportionallyDown
        }
        contentView.addSubview(iconView)

        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.isEditable = true
        textField.isSelectable = true
        textField.isEnabled = true
        textField.cell?.usesSingleLineMode = true
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.placeholderString = LaunchConstants.Launcher.searchPlaceholder
        textField.font = NSFont.systemFont(ofSize: LaunchConstants.Launcher.searchFontSize, weight: .regular)
        textField.textColor = .white
        textField.placeholderAttributedString = NSAttributedString(
            string: LaunchConstants.Launcher.searchPlaceholder,
            attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.55)]
        )
        textField.target = self
        textField.action = #selector(textDidChange)
        contentView.addSubview(textField)

        clearButton.isBordered = false
        if #available(macOS 26.0, *) {
            clearButton.bezelStyle = .glass
        } else {
            clearButton.bezelStyle = .inline
        }
        clearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear")
        clearButton.imagePosition = .imageOnly
        clearButton.contentTintColor = NSColor.white.withAlphaComponent(0.55)
        clearButton.target = self
        clearButton.action = #selector(clearTapped)
        clearButton.isHidden = true
        contentView.addSubview(clearButton)
    }

    private func configureChrome() {
        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView()
            glass.style = .regular
            glass.cornerRadius = LaunchConstants.Launcher.searchHeight / 2
            glass.tintColor = NSColor.white.withAlphaComponent(0.10)
            glass.wantsLayer = true
            glass.layer?.shadowColor = NSColor.black.cgColor
            glass.layer?.shadowOpacity = 0.22
            glass.layer?.shadowRadius = 16
            glass.layer?.shadowOffset = NSSize(width: 0, height: -4)
            glass.contentView = contentView
            addSubview(glass)
            chromeView = glass
            glassChromeView = glass
        } else {
            let visual = NSVisualEffectView()
            visual.material = .hudWindow
            visual.blendingMode = .withinWindow
            visual.state = .inactive
            visual.wantsLayer = true
            visual.layer?.cornerRadius = LaunchConstants.Launcher.searchHeight / 2
            visual.layer?.masksToBounds = true
            addSubview(visual)
            addSubview(contentView)
            chromeView = visual
            visualChromeView = visual
        }

        wantsLayer = true
        layer?.cornerRadius = LaunchConstants.Launcher.searchHeight / 2
        layer?.masksToBounds = false
    }

    override func layout() {
        super.layout()
        chromeView?.frame = bounds
        contentView.frame = bounds
        addChromeHighlights()

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
        let font = textField.font ?? NSFont.systemFont(ofSize: LaunchConstants.Launcher.searchFontSize)
        let textHeight = ceil(font.ascender - font.descender) + 6
        textField.frame = NSRect(x: textX, y: (bounds.height - textHeight) / 2 + 4, width: textWidth, height: textHeight)
    }

    private func addChromeHighlights() {
        guard let layer else { return }
        layer.sublayers?.removeAll { $0.name == "searchChromeHighlight" }

        let shape = CAShapeLayer()
        shape.name = "searchChromeHighlight"
        shape.frame = bounds
        shape.path = CGPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerWidth: LaunchConstants.Launcher.searchHeight / 2,
            cornerHeight: LaunchConstants.Launcher.searchHeight / 2,
            transform: nil
        )
        shape.fillColor = NSColor.clear.cgColor
        shape.strokeColor = NSColor.white.withAlphaComponent(0.24).cgColor
        shape.lineWidth = 0.8
        layer.addSublayer(shape)
    }

    func setActive(_ active: Bool) {
        visualChromeView?.state = active ? .active : .inactive
        if #available(macOS 26.0, *) {
            (glassChromeView as? NSGlassEffectView)?.tintColor = NSColor.white.withAlphaComponent(active ? 0.16 : 0.10)
        }
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

    /// Pin the field to a fixed size so SwiftUI doesn't stretch the NSView to the full
    /// container width (the bar was filling the row without this).
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: LauncherSearchBarView, context: Context) -> CGSize? {
        CGSize(width: LaunchConstants.Launcher.searchWidth, height: LaunchConstants.Launcher.searchHeight)
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
        window?.makeKey()
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok { (superview as? LauncherSearchBarView)?.setActive(true) }
        return ok
    }

    override func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        if ok { (superview as? LauncherSearchBarView)?.setActive(false) }
        return ok
    }
}
