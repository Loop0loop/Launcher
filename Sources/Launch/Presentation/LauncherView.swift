import LaunchCore
import SwiftUI
import UniformTypeIdentifiers

struct LauncherView: View {
    @ObservedObject var state: AppState
    @Environment(\.iconCache) private var iconCache
    @Namespace private var folderAnimation

    var body: some View {
        GeometryReader { geometry in
            let layout = LaunchpadLayoutMetrics(size: geometry.size)
            let columns = Array(
                repeating: GridItem(.fixed(layout.columnWidth), spacing: layout.gridColumnSpacing),
                count: layout.columns
            )

            ZStack {
                LauncherBackgroundView()
                    .contentShape(Rectangle())
                    .onTapGesture(perform: handleBackgroundTap)

                launcherContent(layout: layout, columns: columns)
                    .opacity(state.launcherVisible ? 1 : 0)
                    .scaleEffect(state.launcherVisible ? 1 : LaunchConstants.Launcher.contentHiddenScale)
                    .animation(LaunchConstants.Animation.showSpring, value: state.launcherVisible)

                if let folder = state.openFolder {
                    Color.black.opacity(LaunchConstants.Launcher.overlayOpacity)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture { state.closeFolder() }

                    FolderOverlay(folder: folder, state: state, namespace: folderAnimation)
                        .transition(.scale(scale: 0.88).combined(with: .opacity))
                }
            }
            .gesture(
                DragGesture(minimumDistance: LaunchConstants.Launcher.dragMinimumDistance)
                    .onEnded { value in
                        if value.translation.width < -LaunchConstants.Launcher.pageDragThreshold {
                            state.changePage(1)
                        } else if value.translation.width > LaunchConstants.Launcher.pageDragThreshold {
                            state.changePage(-1)
                        }
                    }
            )
        }
        .onExitCommand(perform: handleBackgroundTap)
        .animation(LaunchConstants.Animation.folderSpring, value: state.openFolder?.id)
    }

    @ViewBuilder
    private func launcherContent(layout: LaunchpadLayoutMetrics, columns: [GridItem]) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: layout.topInset)

            LauncherSearchField(query: $state.query)
                .padding(.bottom, layout.searchToGridGap)

            ZStack {
                LazyVGrid(columns: columns, spacing: layout.gridRowSpacing) {
                    ForEach(state.pageItems) { item in
                        LauncherItemView(
                            item: item,
                            state: state,
                            layout: layout,
                            folderNamespace: folderAnimation
                        )
                    }
                }
                .frame(height: layout.gridHeight, alignment: .top)
                .id(state.currentPage)
                .transition(pageTransition(for: state.pageDirection))
            }
            .animation(LaunchConstants.Animation.pageSpring, value: state.currentPage)

            Spacer(minLength: layout.gridToPagerGap)

            LauncherPageIndicator(pageCount: state.pageCount, currentPage: state.currentPage)

            Spacer(minLength: layout.bottomInset)
        }
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: handleBackgroundTap)
        }
    }

    private func handleBackgroundTap() {
        if state.openFolder != nil {
            state.closeFolder()
        } else if state.query.isEmpty {
            state.closeLauncher?()
        } else {
            state.query = ""
        }
    }

    private func pageTransition(for direction: Int) -> AnyTransition {
        let edge: Edge = direction >= 0 ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge == .trailing ? .leading : .trailing).combined(with: .opacity)
        )
    }
}

struct LauncherSearchField: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))

            TextField(LaunchConstants.Launcher.searchPlaceholder, text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: LaunchConstants.Launcher.searchFontSize, weight: .regular))
                .foregroundStyle(.white.opacity(0.92))
        }
        .padding(.horizontal, LaunchConstants.Launcher.searchHorizontalPadding)
        .frame(width: LaunchConstants.Launcher.searchWidth, height: LaunchConstants.Launcher.searchHeight)
        .launchpadSearchChrome()
    }
}

struct LauncherPageIndicator: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        if pageCount > 1 {
            HStack(spacing: LaunchConstants.Launcher.pageDotSpacing) {
                ForEach(0..<pageCount, id: \.self) { page in
                    Circle()
                        .fill(page == currentPage ? .white : .white.opacity(LaunchConstants.Launcher.inactivePageOpacity))
                        .frame(width: LaunchConstants.Launcher.pageDotSize, height: LaunchConstants.Launcher.pageDotSize)
                        .animation(LaunchConstants.Animation.pageSpring, value: currentPage)
                }
            }
            .frame(height: LaunchConstants.Launcher.pageDotHeight)
        } else {
            Color.clear.frame(height: LaunchConstants.Launcher.pageDotHeight)
        }
    }
}

struct LauncherItemView: View {
    let item: LauncherItem
    @ObservedObject var state: AppState
    let layout: LaunchpadLayoutMetrics
    var folderNamespace: Namespace.ID

    var body: some View {
        switch item {
        case .app(let app):
            AppIcon(app: app, state: state, layout: layout)
        case .folder(let folder, let apps):
            FolderIcon(folder: folder, apps: apps, state: state, layout: layout, namespace: folderNamespace)
        }
    }
}

struct AppIcon: View {
    let app: LaunchApp
    @ObservedObject var state: AppState
    @Environment(\.iconCache) private var iconCache
    let layout: LaunchpadLayoutMetrics

    var body: some View {
        Button {
            state.launch(app)
        } label: {
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
            .frame(width: layout.columnWidth)
            .opacity(state.draggedAppID == app.id ? LaunchConstants.Icon.draggedOpacity : 1)
        }
        .buttonStyle(.plain)
        .onDrag {
            state.draggedAppID = app.id
            return NSItemProvider(object: app.id as NSString)
        }
        .onDrop(of: [UTType.text], delegate: AppDropDelegate(targetID: app.id, state: state))
    }
}

struct FolderIcon: View {
    let folder: LaunchFolder
    let apps: [LaunchApp]
    @ObservedObject var state: AppState
    @Environment(\.iconCache) private var iconCache
    let layout: LaunchpadLayoutMetrics
    var namespace: Namespace.ID

    private var miniIconSize: CGFloat {
        layout.iconSize * LaunchConstants.Icon.folderPreviewScale
    }

    var body: some View {
        Button {
            withAnimation(LaunchConstants.Animation.folderSpring) {
                state.openFolder = folder
            }
        } label: {
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
                .modifier(FolderGlassIDModifier(folderID: folder.id, namespace: namespace, isOpen: state.openFolder?.id == folder.id))

                Text(folder.name)
                    .font(.system(size: LaunchConstants.Icon.labelFontSize, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: layout.labelWidth, height: LaunchConstants.Icon.labelHeight, alignment: .top)
                    .launchLabelStyle()
            }
            .frame(width: layout.columnWidth)
        }
        .buttonStyle(.plain)
        .onDrop(of: [UTType.text], delegate: FolderDropDelegate(targetID: folder.id, state: state))
    }
}

private struct FolderGlassIDModifier: ViewModifier {
    let folderID: String
    let namespace: Namespace.ID
    let isOpen: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffectID(isOpen ? "open-\(folderID)" : folderID, in: namespace)
        } else {
            content
        }
    }
}

struct FolderOverlay: View {
    let folder: LaunchFolder
    @ObservedObject var state: AppState
    var namespace: Namespace.ID

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(LaunchConstants.FolderOverlay.gridItemWidth), spacing: LaunchConstants.FolderOverlay.gridSpacing),
            count: LaunchConstants.FolderOverlay.columns
        )
    }

    var body: some View {
        if #available(macOS 26, *) {
            GlassEffectContainer {
                folderContent
                    .launchGlass(in: RoundedRectangle(cornerRadius: LaunchConstants.FolderOverlay.cornerRadius), interactive: false)
                    .glassEffectID("open-\(folder.id)", in: namespace)
            }
        } else {
            folderContent
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LaunchConstants.FolderOverlay.cornerRadius))
        }
    }

    private var folderContent: some View {
        VStack(spacing: LaunchConstants.FolderOverlay.spacing) {
            Text(folder.name)
                .font(.system(size: LaunchConstants.FolderOverlay.titleFontSize, weight: .semibold))
                .launchLabelStyle()

            LazyVGrid(columns: columns, spacing: LaunchConstants.FolderOverlay.spacing) {
                ForEach(state.apps(in: folder)) { app in
                    FolderOverlayAppIcon(app: app, state: state)
                }
            }
            .frame(minHeight: LaunchConstants.FolderOverlay.minGridHeight, alignment: .top)
        }
        .padding(LaunchConstants.FolderOverlay.padding)
        .frame(width: LaunchConstants.FolderOverlay.width)
    }
}

struct FolderOverlayAppIcon: View {
    let app: LaunchApp
    @ObservedObject var state: AppState
    @Environment(\.iconCache) private var iconCache

    var body: some View {
        Button {
            state.launch(app)
        } label: {
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
            .opacity(state.draggedAppID == app.id ? LaunchConstants.Icon.draggedOpacity : 1)
        }
        .buttonStyle(.plain)
        .onDrag {
            state.draggedAppID = app.id
            return NSItemProvider(object: app.id as NSString)
        }
        .onDrop(of: [UTType.text], delegate: AppDropDelegate(targetID: app.id, state: state))
    }
}
