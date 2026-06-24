import SwiftUI

extension View {
    @ViewBuilder
    func launchGlass(
        in shape: some InsettableShape,
        interactive: Bool = false,
        clear: Bool = false,
        fallbackMaterial: Material = .ultraThinMaterial
    ) -> some View {
        if #available(macOS 26, *) {
            // .clear = high-transparency variant (Liquid Glass). Use it for large
            // surfaces (folder panel/tile) so wallpaper reads through. Do NOT layer
            // materials/tints over glassEffect — that turns it into a milky card.
            let base: Glass = clear ? .clear : .regular
            let glass: Glass = interactive ? base.interactive() : base
            self.glassEffect(glass, in: shape)
        } else {
            self.background(fallbackMaterial, in: shape)
        }
    }

    /// 닫힌 폴더 타일: macOS 26 `.clear` real glass (구버전 material 폴백). 엣지/틴트 없음 —
    /// 시스템 글래스가 굴절·스페큘러를 그린다. 위에 덧칠하면 우윳빛 카드가 된다.
    func launchpadFolderChrome(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return launchGlass(in: shape, interactive: false, clear: true)
    }

    /// 열린 폴더 패널 크롬: 소프트 섀도만. 글래스·엣지·스페큘러는 상위 launchGlass가
    /// 단일 표면으로 처리한다. (cornerRadius는 launchGlass shape이 이미 담당.)
    func tahoeFolderPanelChrome() -> some View {
        shadow(
            color: .black.opacity(LaunchConstants.Glass.panelShadowOpacity),
            radius: LaunchConstants.Glass.panelShadowRadius,
            y: 18
        )
    }

    /// Settings panel card: frosted glass with subtle edge highlight.
    func settingsGlassCard(cornerRadius: CGFloat = LaunchConstants.Settings.cardCornerRadius) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.white.opacity(0.08))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                }
        }
    }
}

struct LaunchLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.35), radius: 0.5, y: 0.5)
    }
}

extension View {
    func launchLabelStyle() -> some View {
        modifier(LaunchLabelStyle())
    }
}
