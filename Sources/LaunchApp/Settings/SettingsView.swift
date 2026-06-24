import AppKit
import SwiftUI

/// Tabbed settings panel (General / Interface / Apps / Advanced / About), liquid-glass styled.
/// Stage 1 wires every control that already has backing in `AppState`; new-backend controls
/// (menu bar icon, app icon, configurable hotkey, hot corner, trackpad fingers) land in later stages.
struct SettingsView: View {
    @ObservedObject var state: AppState
    @State private var tab: SettingsTab = .general

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            Color.black.opacity(LaunchConstants.Appearance.settingsBackdropOpacity)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                SettingsTabBar(selection: $tab)
                    .padding(.top, LaunchConstants.Settings.titleBarInset)
                    .padding(.horizontal, LaunchConstants.Settings.padding)
                    .padding(.bottom, 8)

                Divider().opacity(0.12)

                ScrollView {
                    VStack(alignment: .leading, spacing: LaunchConstants.Settings.sectionSpacing) {
                        switch tab {
                        case .general: generalTab
                        case .interface: interfaceTab
                        case .apps: appsTab
                        case .advanced: advancedTab
                        case .about: aboutTab
                        }
                    }
                    .padding(LaunchConstants.Settings.padding)
                }
            }
        }
        .frame(
            width: LaunchConstants.Settings.width,
            height: LaunchConstants.Settings.height,
            alignment: .top
        )
        .foregroundStyle(.white)
    }

    // MARK: General

    private var generalTab: some View {
        Group {
            SettingsSection(title: "Launch") {
                SettingsToggleRow(
                    title: LaunchConstants.Settings.launchAtLogin,
                    isOn: Binding(get: { state.launchAtLogin }, set: { state.setLaunchAtLogin($0) })
                )
                if let error = state.loginItemError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            SettingsSection(title: LaunchConstants.Settings.appearanceSection) {
                SettingsToggleRow(title: LaunchConstants.Settings.showMenuBarIcon, isOn: $state.showMenuBarIcon)
                SettingsRow(title: LaunchConstants.Settings.appIcon) {
                    AppIconPicker(selection: $state.appIcon)
                }
            }
        }
    }

    // MARK: Interface

    private var interfaceTab: some View {
        Group {
            SettingsSection(title: "Layout") {
                SettingsRow(title: LaunchConstants.Settings.sortBy) {
                    Picker("", selection: $state.sortMode) {
                        ForEach(SortMode.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }

                SettingsRow(title: "Browsing Style") {
                    Picker("", selection: $state.displayMode) {
                        ForEach(LauncherDisplayMode.allCases) { mode in
                            Text(mode.browsingLabel).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .fixedSize()
                }

                SettingsRow(title: "Icon Grid") {
                    HStack(spacing: 8) {
                        Stepper(value: columnsBinding, in: 4...12) {
                            Text("\(state.gridLayout.columns)").monospacedDigit()
                        }
                        .fixedSize()
                        Text("×").foregroundStyle(.secondary)
                        Stepper(value: rowsBinding, in: 3...10) {
                            Text("\(state.gridLayout.rows)").monospacedDigit()
                        }
                        .fixedSize()
                    }
                }
            }

            SettingsSection(title: "Background") {
                SettingsSliderRow(
                    title: LaunchConstants.Settings.backgroundTransparency,
                    help: LaunchConstants.Settings.backgroundTransparencyHelp,
                    value: bind(\.appearance.backgroundTransparency),
                    display: percent(state.appearance.backgroundTransparency)
                )
                SettingsSliderRow(
                    title: LaunchConstants.Settings.folderDim,
                    help: LaunchConstants.Settings.folderDimHelp,
                    value: bind(\.appearance.folderDimOpacity),
                    range: LaunchConstants.Appearance.minFolderDim...LaunchConstants.Appearance.maxFolderDim,
                    display: percent(state.appearance.folderDimOpacity)
                )
            }
        }
    }

    // MARK: Apps

    private var appsTab: some View {
        Group {
            SettingsSection(title: "App Sources") {
                if state.appSourcePaths.isEmpty {
                    Text("Default application folders only")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(state.appSourcePaths, id: \.self) { path in
                        HStack(spacing: 10) {
                            Text(path).font(.caption).lineLimit(1).truncationMode(.middle)
                            Spacer()
                            Button(LaunchConstants.Settings.removeAppSource) { state.removeAppSource(path) }
                                .buttonStyle(.plain)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.red)
                        }
                    }
                }
                SettingsActionRow(title: LaunchConstants.Settings.addAppSource) { state.requestAppSource() }
            }

            SettingsSection(title: "Catalog") {
                SettingsActionRow(title: LaunchConstants.Menu.refreshApps) { state.refreshApps() }
                SettingsActionRow(title: LaunchConstants.Settings.importNativeLayout) { state.importNativeLaunchpadLayout() }
            }
        }
    }

    // MARK: Advanced

    private var advancedTab: some View {
        Group {
            SettingsSection(title: "Permissions") {
                SettingsStatusRow(title: LaunchConstants.Settings.accessibility, status: state.accessibilityState.label, positive: state.accessibilityState == .allowed)
                SettingsStatusRow(title: LaunchConstants.Settings.trackpad, status: state.trackpadGateState.label, positive: state.trackpadGateState == .exactPinch)
                SettingsStatusRow(title: LaunchConstants.Settings.globalHotKey, status: state.globalHotKeyState.label, positive: state.globalHotKeyState == .allowed)
                SettingsStatusRow(title: LaunchConstants.Settings.f4Key, status: state.f4KeyState.label, positive: state.f4KeyState == .allowed)
                SettingsActionRow(title: LaunchConstants.Settings.requestAccessibility) { state.requestAccessibilityPermission() }
            }

            SettingsSection(title: "Window") {
                SettingsToggleRow(title: LaunchConstants.Settings.windowBrowsingMode, isOn: $state.windowBrowsingMode)
            }
        }
    }

    // MARK: About

    private var aboutTab: some View {
        SettingsSection(title: "About") {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                    .resizable().frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LaunchConstants.App.settingsTitle.replacingOccurrences(of: " Settings", with: ""))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("Version \(Self.appVersion)").font(.subheadline).foregroundStyle(.secondary)
                    Text(Self.bundleID).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    // MARK: Bindings / helpers

    private var columnsBinding: Binding<Int> {
        Binding(get: { state.gridLayout.columns },
                set: { state.gridLayout = GridLayoutSettings(columns: $0, rows: state.gridLayout.rows) })
    }
    private var rowsBinding: Binding<Int> {
        Binding(get: { state.gridLayout.rows },
                set: { state.gridLayout = GridLayoutSettings(columns: state.gridLayout.columns, rows: $0) })
    }
    private func bind(_ keyPath: ReferenceWritableKeyPath<AppState, Double>) -> Binding<Double> {
        Binding(get: { state[keyPath: keyPath] }, set: { state[keyPath: keyPath] = $0 })
    }
    private func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }

    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private static var bundleID: String { Bundle.main.bundleIdentifier ?? "—" }
}

// MARK: - Tabs

extension LauncherDisplayMode {
    /// Video reference labels the vertical mode "Scroll".
    var browsingLabel: String {
        switch self {
        case .paged: "Paged"
        case .vertical: "Scroll"
        }
    }
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, interface, apps, advanced, about
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .interface: "slider.horizontal.3"
        case .apps: "square.grid.2x2"
        case .advanced: "wrench.and.screwdriver"
        case .about: "info.circle"
        }
    }
}

private struct SettingsTabBar: View {
    @Binding var selection: SettingsTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases) { tab in
                let active = tab == selection
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage).font(.system(size: 15, weight: .medium))
                        Text(tab.title).font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(active ? Color.accentColor : .secondary)
                    .background {
                        if active {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.white.opacity(0.12))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Building blocks

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
            VStack(alignment: .leading, spacing: 14) { content }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .settingsGlassCard()
        }
    }
}

/// Label on the left, trailing control on the right.
private struct SettingsRow<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer(minLength: 12)
            trailing
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        SettingsRow(title: title) {
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(.switch)
        }
    }
}

private struct SettingsSliderRow: View {
    let title: String
    let help: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    let display: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text(display).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
            Text(help).font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct SettingsActionRow: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AppIconPicker: View {
    @Binding var selection: AppIconOption

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AppIconOption.allCases) { option in
                Button {
                    selection = option
                } label: {
                    Image(nsImage: option.image() ?? NSImage())
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.accentColor, lineWidth: selection == option ? 2.5 : 0)
                        }
                }
                .buttonStyle(.plain)
                .help(option.title)
            }
        }
    }
}

private struct SettingsStatusRow: View {
    let title: String
    let status: String
    let positive: Bool
    var body: some View {
        SettingsRow(title: title) {
            Text(status)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill((positive ? Color.green : Color.orange).opacity(0.18)))
                .foregroundStyle(positive ? .green : .orange)
        }
    }
}
