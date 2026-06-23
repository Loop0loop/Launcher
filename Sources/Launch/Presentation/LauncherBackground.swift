import SwiftUI

struct LauncherBackgroundView: View {
    var body: some View {
        ZStack {
            VisualEffectView(
                material: LaunchConstants.Launcher.backgroundMaterial,
                blendingMode: .behindWindow
            )
            .ignoresSafeArea()

            Color.black.opacity(LaunchConstants.Launcher.backgroundOpacity)
                .ignoresSafeArea()
        }
    }
}
