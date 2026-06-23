enum PermissionState: Equatable {
    case unknown
    case allowed
    case required
    case needsApproval

    var label: String {
        switch self {
        case .unknown: "Unknown"
        case .allowed: "Allowed"
        case .required: "Required"
        case .needsApproval: "Needs approval"
        }
    }
}

enum TrackpadGateState: Equatable {
    case unknown
    case exactFourFinger
    case fallbackPinch

    var label: String {
        switch self {
        case .unknown: "Unknown"
        case .exactFourFinger: "4-finger exact"
        case .fallbackPinch: "Pinch fallback"
        }
    }
}
