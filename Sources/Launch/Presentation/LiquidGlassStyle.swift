import SwiftUI

extension View {
    @ViewBuilder
    func launchGlass(
        in shape: some InsettableShape,
        interactive: Bool = false,
        fallbackMaterial: Material = .ultraThinMaterial
    ) -> some View {
        if #available(macOS 26, *) {
            let glass: Glass = interactive ? .regular.interactive() : .regular
            self.glassEffect(glass, in: shape)
        } else {
            self.background(fallbackMaterial, in: shape)
        }
    }

    /// Launcher search pill — VisualEffectView for reliable rendering in borderless windows.
    func launcherSearchChrome() -> some View {
        background {
            ZStack {
                VisualEffectView(
                    material: LaunchConstants.Launcher.chromeMaterial,
                    blendingMode: .withinWindow
                )
                .clipShape(Capsule())

                Capsule()
                    .fill(.black.opacity(LaunchConstants.Launcher.searchFillOpacity))

                Capsule()
                    .strokeBorder(.white.opacity(LaunchConstants.Launcher.searchBorderOpacity), lineWidth: 0.5)
            }
        }
    }

    /// Page nav button — glass circle backed by VisualEffectView.
    func launcherPageNavChrome() -> some View {
        background {
            ZStack {
                VisualEffectView(
                    material: LaunchConstants.Launcher.chromeMaterial,
                    blendingMode: .withinWindow
                )
                .clipShape(Circle())

                Circle()
                    .fill(.black.opacity(0.32))

                Circle()
                    .strokeBorder(.white.opacity(0.28), lineWidth: 0.5)
            }
        }
    }

    /// Page dots track — glass capsule backed by VisualEffectView.
    func launcherPageDotsChrome() -> some View {
        background {
            ZStack {
                VisualEffectView(
                    material: LaunchConstants.Launcher.chromeMaterial,
                    blendingMode: .withinWindow
                )
                .clipShape(Capsule())

                Capsule()
                    .fill(.black.opacity(0.28))

                Capsule()
                    .strokeBorder(.white.opacity(0.22), lineWidth: 0.5)
            }
        }
    }

    /// Tahoe-style search field: light Liquid Glass capsule (Spotlight / Apps inspired).
    func tahoeSearchChrome() -> some View {
        background {
            Capsule()
                .fill(.white.opacity(0.14))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.45), .white.opacity(0.12)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
        }
    }

    /// Glass circle for page navigation chevrons.
    func tahoePageNavChrome() -> some View {
        background {
            Circle()
                .fill(.white.opacity(0.12))
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.28), lineWidth: 0.5)
                }
        }
    }

    /// Glass track behind page dots.
    func tahoePageDotsChrome() -> some View {
        background {
            Capsule()
                .fill(.white.opacity(0.08))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                }
        }
    }

    /// Legacy dark Launchpad search pill (pre-Tahoe).
    func launchpadSearchChrome() -> some View {
        background {
            Capsule()
                .fill(.black.opacity(0.42))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                }
        }
    }

    /// Tahoe-style folder tile: light frosted glass square.
    func launchpadFolderChrome(cornerRadius: CGFloat) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.white.opacity(0.16))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.38), .white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
        }
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
