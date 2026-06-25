public enum GridGeometry {
    /// Cell index under a point given in a grid's own coordinate space (origin at the
    /// top-left of the first cell). Clamped to `0..<count`. Used to map a folder-internal
    /// drop location to a reorder target slot.
    public static func cellIndex(
        x: Double,
        y: Double,
        columns: Int,
        colPitch: Double,
        rowPitch: Double,
        count: Int
    ) -> Int {
        guard columns > 0, colPitch > 0, rowPitch > 0, count > 0 else { return 0 }
        let col = min(max(Int(x / colPitch), 0), columns - 1)
        let row = max(Int(y / rowPitch), 0)
        let index = row * columns + col
        return min(max(index, 0), count - 1)
    }
}
