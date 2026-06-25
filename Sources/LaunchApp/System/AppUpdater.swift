import AppKit
import LaunchpadCore
import Sparkle

@MainActor
final class AppUpdater {
    private let updaterController: SPUStandardUpdaterController?

    init() {
        guard Self.configuration.isConfigured else {
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

    private static var configuration: UpdateConfiguration {
        UpdateConfiguration(
            feedURL: Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
            publicKey: Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        )
    }
}

private enum AppUpdaterError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        LaunchConstants.Updates.notConfigured
    }
}
