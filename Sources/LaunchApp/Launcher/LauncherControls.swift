import SwiftUI

struct LauncherDismissLayer: View {
    let action: () -> Void

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
}

struct LauncherSearchField: View {
    @Binding var query: String
    @ObservedObject var state: AppState

    var body: some View {
        LauncherSearchBarRepresentable(text: $query) { bar in
            state.registerSearchBar(bar)
            if state.searchFocus.shouldFocusOnShow {
                DispatchQueue.main.async {
                    state.focusSearchField()
                }
            }
        }
        .frame(width: LaunchConstants.Launcher.searchWidth, height: LaunchConstants.Launcher.searchHeight)
        .frame(maxWidth: .infinity)
    }
}

struct LauncherPageControl: View {
    @ObservedObject var state: AppState
    let selectPage: (Int) -> Void

    var body: some View {
        HStack(spacing: LaunchConstants.Launcher.pageDotSpacing) {
            ForEach(0..<state.pageCount, id: \.self) { page in
                Circle()
                    .fill(page == state.currentPage ? .white : .white.opacity(LaunchConstants.Launcher.inactivePageOpacity))
                    .frame(
                        width: LaunchConstants.Launcher.pageDotSize,
                        height: LaunchConstants.Launcher.pageDotSize
                    )
                    .scaleEffect(page == state.currentPage ? LaunchConstants.Launcher.pageIndicatorActiveScale : 1)
                    .padding(6)
                    .contentShape(Rectangle())
                    .animation(LaunchConstants.Animation.fade, value: state.currentPage)
                    .onTapGesture {
                        LaunchLog.line("page dot tapped page=\(page)")
                        withAnimation(LaunchConstants.Animation.spring) {
                            selectPage(page)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

