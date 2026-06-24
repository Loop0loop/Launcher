import Foundation
import ServiceManagement

enum LoginItemAdapter {
    enum LoginItemError: LocalizedError {
        case unsupported
        case requiresApproval
        case notEnabled

        var errorDescription: String? {
            switch self {
            case .unsupported:
                "Requires macOS 13 or newer."
            case .requiresApproval:
                "Enable Launch in System Settings > General > Login Items."
            case .notEnabled:
                "Could not enable Launch at Login."
            }
        }
    }

    static var isEnabled: Bool {
        guard #available(macOS 13.0, *) else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard #available(macOS 13.0, *) else { throw LoginItemError.unsupported }
        if enabled {
            try SMAppService.mainApp.register()
            switch SMAppService.mainApp.status {
            case .enabled:
                break
            case .requiresApproval:
                throw LoginItemError.requiresApproval
            default:
                throw LoginItemError.notEnabled
            }
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
