import AppKit
import LaunchCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppState: ObservableObject {
    @Published var apps: [LaunchApp] = []
    @Published var query = "" {
        didSet { currentPage = 0 }
    }
    @Published var currentPage = 0
    @Published var draggedAppID: String?

    private let pageSize = 35
    private let layoutKey = "layoutOrder"

    init() {
        refreshApps()
    }

    var visibleApps: [LaunchApp] {
        guard !query.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var pageCount: Int {
        max(1, Int(ceil(Double(visibleApps.count) / Double(pageSize))))
    }

    var pageApps: [LaunchApp] {
        Array(visibleApps.dropFirst(currentPage * pageSize).prefix(pageSize))
    }

    func refreshApps() {
        apps = LayoutOrder.apply(savedOrder(), to: AppCatalog.scan())
        saveOrder()
    }

    func launch(_ app: LaunchApp) {
        NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
        NSApp.hide(nil)
    }

    func move(_ id: String, before targetID: String) {
        let nextOrder = LayoutOrder.move(id, before: targetID, in: apps.map(\.id))
        apps = LayoutOrder.apply(nextOrder, to: apps)
        saveOrder()
    }

    func changePage(_ delta: Int) {
        currentPage = min(max(currentPage + delta, 0), pageCount - 1)
    }

    private func savedOrder() -> [String] {
        UserDefaults.standard.stringArray(forKey: layoutKey) ?? []
    }

    private func saveOrder() {
        UserDefaults.standard.set(apps.map(\.id), forKey: layoutKey)
    }
}

struct LauncherView: View {
    @ObservedObject var state: AppState

    private let columns = Array(repeating: GridItem(.fixed(112), spacing: 18), count: 7)

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            Color.black.opacity(0.22).ignoresSafeArea()

            VStack(spacing: 34) {
                TextField("Search Applications", text: $state.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 18)
                    .frame(width: 420, height: 44)
                    .background(.ultraThinMaterial, in: Capsule())

                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(state.pageApps) { app in
                        AppIcon(app: app, state: state)
                    }
                }
                .frame(height: 620, alignment: .top)

                HStack(spacing: 8) {
                    ForEach(0..<state.pageCount, id: \.self) { page in
                        Circle()
                            .fill(page == state.currentPage ? .white : .white.opacity(0.35))
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(height: 14)
            }
            .padding(.top, 70)
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -60 {
                        state.changePage(1)
                    } else if value.translation.width > 60 {
                        state.changePage(-1)
                    }
                }
        )
        .onExitCommand {
            if state.query.isEmpty {
                NSApp.hide(nil)
            } else {
                state.query = ""
            }
        }
    }
}

struct AppIcon: View {
    let app: LaunchApp
    @ObservedObject var state: AppState

    var body: some View {
        Button {
            state.launch(app)
        } label: {
            VStack(spacing: 8) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                    .resizable()
                    .frame(width: 72, height: 72)
                Text(app.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 104, height: 34, alignment: .top)
            }
            .foregroundStyle(.white)
            .opacity(state.draggedAppID == app.id ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .onDrag {
            state.draggedAppID = app.id
            return NSItemProvider(object: app.id as NSString)
        }
        .onDrop(of: [UTType.text], delegate: AppDropDelegate(targetID: app.id, state: state))
    }
}

struct AppDropDelegate: DropDelegate {
    let targetID: String
    @ObservedObject var state: AppState

    func dropEntered(info: DropInfo) {
        guard let dragged = state.draggedAppID else { return }
        state.move(dragged, before: targetID)
    }

    func performDrop(info: DropInfo) -> Bool {
        state.draggedAppID = nil
        return true
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    var window: NSWindow?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        makeWindow()
        makeStatusItem()
        showLauncher()
    }

    func makeWindow() {
        let frame = NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 1440, height: 900)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: LauncherView(state: state))
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .mainMenu
        self.window = window
    }

    func makeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.title = "L"
        let menu = NSMenu()
        menu.addItem(withTitle: "Show Launch", action: #selector(showLauncher), keyEquivalent: "l")
        menu.addItem(withTitle: "Refresh Apps", action: #selector(refreshApps), keyEquivalent: "r")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc func showLauncher() {
        state.query = ""
        window?.setFrame(NSScreen.main?.frame ?? window?.frame ?? .zero, display: true)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func refreshApps() {
        state.refreshApps()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
