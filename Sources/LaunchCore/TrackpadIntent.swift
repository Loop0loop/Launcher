public enum TrackpadIntent: Equatable {
    case open
    case close
    case previousPage
    case nextPage

    public static func pinch(magnification: Double, threshold: Double = 0.08) -> TrackpadIntent? {
        if magnification <= -threshold { return .open }
        if magnification >= threshold { return .close }
        return nil
    }

    public static func horizontalSwipe(deltaX: Double, threshold: Double = 0.5) -> TrackpadIntent? {
        if deltaX <= -threshold { return .nextPage }
        if deltaX >= threshold { return .previousPage }
        return nil
    }
}

