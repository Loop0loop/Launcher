import LaunchCore
import SwiftUI

struct LauncherItemView: View {
    let item: LauncherItem
    @ObservedObject var state: AppState
    let layout: LaunchpadLayoutMetrics

    var body: some View {
        switch item {
        case .app(let app):
            AppIcon(app: app, state: state, layout: layout)
        case .folder(let folder, let apps):
            FolderIcon(folder: folder, apps: apps, state: state, layout: layout)
        }
    }
}

struct AppIcon: View {
    let app: LaunchApp
    @ObservedObject var state: AppState
    @Environment(\.iconCache) private var iconCache
    let layout: LaunchpadLayoutMetrics

    var body: some View {
        VStack(spacing: LaunchConstants.Icon.spacing) {
            Image(nsImage: iconCache.icon(for: app, size: layout.iconSize))
                .resizable()
                .interpolation(.high)
                .frame(width: layout.iconSize, height: layout.iconSize)
                .shadow(color: .black.opacity(0.28), radius: 1.5, y: 1)

            Text(app.name)
                .font(.system(size: LaunchConstants.Icon.labelFontSize, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: layout.labelWidth, height: LaunchConstants.Icon.labelHeight, alignment: .top)
                .launchLabelStyle()
        }
        .frame(width: max(layout.iconSize, layout.labelWidth))
        .contentShape(Rectangle())
        .frame(width: layout.columnWidth)
        .overlay(keyboardSelectionBackground(isSelected: state.showsKeyboardSelection(for: app.id)))
        .onTapGesture {
            state.launch(app)
        }
        .launcherDrag(id: app.id, state: state, layout: layout)
        .contextMenu {
            launcherAppContextMenu(app: app, state: state)
        }
    }
}

struct FolderIcon: View {
    let folder: LaunchFolder
    let apps: [LaunchApp]
    @ObservedObject var state: AppState
    @Environment(\.iconCache) private var iconCache
    let layout: LaunchpadLayoutMetrics

    private var miniIconSize: CGFloat {
        layout.iconSize * LaunchConstants.Icon.folderPreviewScale
    }

    var body: some View {
        VStack(spacing: LaunchConstants.Icon.spacing) {
            ZStack {
                RoundedRectangle(cornerRadius: LaunchConstants.Icon.folderCornerRadius)
                    .frame(width: layout.iconSize, height: layout.iconSize)
                    .launchpadFolderChrome(cornerRadius: LaunchConstants.Icon.folderCornerRadius)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(miniIconSize), spacing: 0),
                        count: LaunchConstants.Icon.folderPreviewColumns
                    ),
                    spacing: 0
                ) {
                    ForEach(apps.prefix(LaunchConstants.Icon.folderPreviewLimit)) { app in
                        Image(nsImage: iconCache.icon(for: app, size: layout.iconSize))
                            .resizable()
                            .interpolation(.high)
                            .frame(width: miniIconSize, height: miniIconSize)
                    }
                }
            }

            Text(folder.name)
                .font(.system(size: LaunchConstants.Icon.labelFontSize, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: layout.labelWidth, height: LaunchConstants.Icon.labelHeight, alignment: .top)
                .launchLabelStyle()
        }
        .frame(width: max(layout.iconSize, layout.labelWidth))
        .contentShape(Rectangle())
        .frame(width: layout.columnWidth)
        .overlay(keyboardSelectionBackground(isSelected: state.showsKeyboardSelection(for: folder.id)))
        .onTapGesture {
            state.openFolderFromTap(folder)
        }
        .launcherDrag(id: folder.id, state: state, layout: layout)
    }
}

@MainActor @ViewBuilder
func launcherAppContextMenu(app: LaunchApp, state: AppState) -> some View {
    Button(LaunchConstants.Menu.openApp) { state.launch(app) }
    Button(LaunchConstants.Menu.showInFinder) { state.revealInFinder(app) }
    Button(LaunchConstants.Menu.addToDock) { state.addToDock(app) }
    Divider()
    Button(LaunchConstants.Menu.hide) { state.hide(app) }
    Divider()
    Button(LaunchConstants.Menu.moveToTrash, role: .destructive) { state.moveToTrash(app) }
}

@ViewBuilder
private func keyboardSelectionBackground(isSelected: Bool) -> some View {
    if isSelected {
        RoundedRectangle(cornerRadius: LaunchConstants.Icon.folderCornerRadius)
            .strokeBorder(.white.opacity(0.45), lineWidth: 1.5)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
    }
}

