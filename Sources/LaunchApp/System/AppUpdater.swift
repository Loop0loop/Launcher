import AppKit
import Sparkle

@MainActor
final class AppUpdater {
    private let updaterController: SPUStandardUpdaterController?

    init() {
        guard Self.isConfigured else {
            updaterController = nil
            return
        }
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        guard let updaterController else {
            NSAlert(error: AppUpdaterError.notConfigured).runModal()
            return
        }
        updaterController.checkForUpdates(nil)
    }

    private static var isConfigured: Bool {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
              key != "REPLACE_WITH_SPARKLE_PUBLIC_ED_KEY",
              !key.isEmpty,
              let feed = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
              URL(string: feed) != nil else {
            return false
        }
        return true
    }
}

private enum AppUpdaterError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        "Sparkle update feed is not configured."
    }
}
