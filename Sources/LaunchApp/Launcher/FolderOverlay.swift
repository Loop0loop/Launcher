import LaunchCore
import SwiftUI

struct FolderOverlay: View {
    let folder: LaunchFolder
    @ObservedObject var state: AppState
    @State private var folderName = ""

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(LaunchConstants.FolderOverlay.gridItemWidth), spacing: LaunchConstants.FolderOverlay.gridSpacing),
            count: LaunchConstants.FolderOverlay.columns
        )
    }

    var body: some View {
        // Open/close is animated by the parent `.transition` + `.animation(value: openFolder)`.
        folderContent
            .onAppear { folderName = folder.name }
            .onChange(of: folder.id) { _, _ in folderName = folder.name }
            .onChange(of: folder.name) { _, name in folderName = name }
    }

    @ViewBuilder
    private var folderContent: some View {
        // launchGlass handles macOS 26 real glass vs material fallback; the chrome
        // layer adds only the signature edge + shadow (no fill, so no muddy double-layer).
        folderPanel
            .launchGlass(
                in: RoundedRectangle(cornerRadius: LaunchConstants.FolderOverlay.cornerRadius, style: .continuous),
                interactive: false,
                clear: true
            )
            .tahoeFolderPanelChrome()
    }

    private var folderPanel: some View {
        VStack(spacing: LaunchConstants.FolderOverlay.spacing) {
            FolderTitleField(name: $folderName) {
                state.renameFolder(folder.id, to: folderName)
            }

            LazyVGrid(columns: columns, spacing: LaunchConstants.FolderOverlay.spacing) {
                ForEach(state.apps(in: folder)) { app in
                    FolderOverlayAppIcon(app: app, folderID: folder.id, state: state)
                }
            }
            .frame(minHeight: LaunchConstants.FolderOverlay.minGridHeight, alignment: .top)
        }
        .padding(LaunchConstants.FolderOverlay.padding)
        .frame(width: LaunchConstants.FolderOverlay.width)
        // contentShape absorbs taps on the panel (so inner clicks don't close the folder)
        // without an empty onTapGesture that would steal the title field's focus tap.
        .contentShape(
            RoundedRectangle(cornerRadius: LaunchConstants.FolderOverlay.cornerRadius, style: .continuous)
        )
    }
}

struct FolderTitleField: View {
    @Binding var name: String
    let commit: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $name)
            .textFieldStyle(.plain)
            .font(.system(size: LaunchConstants.FolderOverlay.titleFontSize, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.3), radius: 0.5, y: 0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .frame(maxWidth: LaunchConstants.FolderOverlay.width - 120)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(focused ? 0.12 : 0))
            )
            .focused($focused)
            .onSubmit { focused = false; commit() }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { commit() }
            }
            .onDisappear(perform: commit)
    }
}

struct FolderOverlayAppIcon: View {
    let app: LaunchApp
    let folderID: String
    @ObservedObject var state: AppState
    @Environment(\.iconCache) private var iconCache
    @State private var dragOffset: CGSize = .zero

    /// Drag distance past which releasing pulls the app out of the folder.
    private static let pullOutThreshold: CGFloat = 100

    var body: some View {
        VStack(spacing: LaunchConstants.Icon.spacing) {
            Image(nsImage: iconCache.icon(for: app, size: LaunchConstants.FolderOverlay.maxIconSize))
                .resizable()
                .interpolation(.high)
                .frame(width: LaunchConstants.FolderOverlay.maxIconSize, height: LaunchConstants.FolderOverlay.maxIconSize)
                .shadow(color: .black.opacity(0.28), radius: 1.5, y: 1)

            Text(app.name)
                .font(.system(size: LaunchConstants.Icon.labelFontSize, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: LaunchConstants.FolderOverlay.labelWidth, height: LaunchConstants.Icon.labelHeight, alignment: .top)
                .launchLabelStyle()
        }
        .frame(width: LaunchConstants.FolderOverlay.gridItemWidth)
        .contentShape(Rectangle())
        .offset(dragOffset)
        .scaleEffect(dragOffset == .zero ? 1 : 1.12)
        .zIndex(dragOffset == .zero ? 0 : 100)
        .onTapGesture {
            state.launch(app)
        }
        // Drag an app far enough to pull it out of the folder back into the grid.
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { dragOffset = $0.translation }
                .onEnded { value in
                    let pulledOut = hypot(value.translation.width, value.translation.height) > Self.pullOutThreshold
                    if pulledOut {
                        LaunchLog.line("folder pull-out app=\(app.id) folder=\(folderID)")
                        state.removeApp(app.id, fromFolder: folderID)
                    }
                    withAnimation(LaunchConstants.Animation.quick) { dragOffset = .zero }
                }
        )
        .contextMenu {
            launcherAppContextMenu(app: app, state: state)
            Divider()
            Button(LaunchConstants.Menu.removeFromFolder) {
                state.removeApp(app.id, fromFolder: folderID)
            }
        }
    }
}
