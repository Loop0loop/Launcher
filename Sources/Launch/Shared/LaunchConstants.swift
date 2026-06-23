import AppKit
import SwiftUI

enum LaunchConstants {
    enum App {
        static let menuBarTitle = "L"
        static let settingsTitle = "Launch Settings"
        static let fallbackWindowFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
    }

    enum Menu {
        static let toggle = "Toggle Launch"
        static let settings = "Settings"
        static let refreshApps = "Refresh Apps"
        static let quit = "Quit"

        static let toggleKey = "l"
        static let settingsKey = ","
        static let refreshKey = "r"
        static let quitKey = "q"
    }

    enum Settings {
        static let launchAtLogin = "Launch at Login"
        static let accessibility = "Accessibility"
        static let trackpad = "Trackpad"
        static let requestAccessibility = "Request Accessibility Permission"

        static let width: CGFloat = 360
        static let height: CGFloat = 180
        static let padding: CGFloat = 24
    }

    enum Storage {
        static let layoutOrderKey = "layoutOrder"
        static let foldersKey = "folders"
    }

    enum Launcher {
        static let searchPlaceholder = "Search"
        static let pageSize = 35
        static let columns = 7
        static let rows = 5

        static let minHorizontalPadding: CGFloat = 60
        static let horizontalPaddingRatio: CGFloat = 0.08
        static let minTopInset: CGFloat = 48
        static let topInsetRatio: CGFloat = 1.0 / 12.0
        static let dockReserve: CGFloat = 120
        static let searchToGridGap: CGFloat = 44
        static let gridToPagerGap: CGFloat = 16
        static let minGridHeight: CGFloat = 520

        static let gridSpacing: CGFloat = 24
        static let minGridRowSpacing: CGFloat = 16
        static let iconColumnScale: CGFloat = 0.78
        static let iconRowScale: CGFloat = 0.58
        static let minIconSize: CGFloat = 80
        static let maxIconSize: CGFloat = 112

        static let searchWidth: CGFloat = 300
        static let searchHeight: CGFloat = 36
        static let searchHorizontalPadding: CGFloat = 12
        static let searchFontSize: CGFloat = 16
        static let searchFillOpacity = 0.22

        static let backgroundMaterial: NSVisualEffectView.Material = .fullScreenUI
        static let backgroundOpacity = 0.06
        static let overlayOpacity = 0.28

        static let pageDotSize: CGFloat = 8
        static let pageDotSpacing: CGFloat = 8
        static let pageDotHeight: CGFloat = 8
        static let inactivePageOpacity = 0.3

        static let contentHiddenScale = 0.9
        static let contentShowOvershootScale = 1.06
        static let dragMinimumDistance: CGFloat = 40
        static let pageDragThreshold: CGFloat = 60
    }

    enum Animation {
        static let showSpring = SwiftUI.Animation.spring(response: 0.34, dampingFraction: 0.82)
        static let hideSpring = SwiftUI.Animation.spring(response: 0.26, dampingFraction: 0.92)
        static let pageSpring = SwiftUI.Animation.spring(response: 0.36, dampingFraction: 0.86)
        static let folderSpring = SwiftUI.Animation.spring(response: 0.32, dampingFraction: 0.84)
    }

    enum Icon {
        static let maxLabelWidth: CGFloat = 120
        static let labelHeight: CGFloat = 34
        static let labelFontSize: CGFloat = 13
        static let spacing: CGFloat = 8
        static let draggedOpacity = 0.35
        static let folderCornerRadius: CGFloat = 18
        static let folderFillOpacity = 0.14
        static let folderPreviewColumns = 2
        static let folderPreviewLimit = 4
        static let folderPreviewScale: CGFloat = 0.28
    }

    enum FolderOverlay {
        static let columns = 4
        static let gridItemWidth: CGFloat = 112
        static let gridSpacing: CGFloat = 18
        static let spacing: CGFloat = 22
        static let titleFontSize: CGFloat = 24
        static let minGridHeight: CGFloat = 150
        static let padding: CGFloat = 30
        static let width: CGFloat = 560
        static let cornerRadius: CGFloat = 24
        static let maxIconSize: CGFloat = 88
        static let labelWidth: CGFloat = 104
    }

    enum Lifecycle {
        static let showDuration = 0.34
        static let hideDuration = 0.26
    }

    enum Multitouch {
        static let frameworkPath = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"
        static let createListSymbol = "MTDeviceCreateList"
        static let registerContactFrameCallbackSymbol = "MTRegisterContactFrameCallback"
        static let deviceStartSymbol = "MTDeviceStart"
        static let gestureFingerCount = 5
        static let pinchInRatio = 0.9
        static let pinchOutRatio = 1.1
        static let triggerCooldown: Double = 0.25
    }
}
