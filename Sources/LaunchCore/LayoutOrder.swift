public enum LayoutOrder {
    public static func apply(_ order: [String], to apps: [LaunchApp]) -> [LaunchApp] {
        let byID = Dictionary(uniqueKeysWithValues: apps.map { ($0.id, $0) })
        let ordered = order.compactMap { byID[$0] }
        let orderedIDs = Set(ordered.map(\.id))
        return ordered + apps.filter { !orderedIDs.contains($0.id) }
    }

    public static func move(_ id: String, before targetID: String, in order: [String]) -> [String] {
        guard id != targetID, order.contains(id), let target = order.firstIndex(of: targetID) else {
            return order
        }

        var next = order.filter { $0 != id }
        next.insert(id, at: min(target, next.count))
        return next
    }
}

