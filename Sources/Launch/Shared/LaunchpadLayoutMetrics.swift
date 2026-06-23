import CoreGraphics

/// Screen-relative layout tuned to match native macOS Launchpad proportions.
struct LaunchpadLayoutMetrics {
    let size: CGSize

    let columns = LaunchConstants.Launcher.columns
    let rows = LaunchConstants.Launcher.rows

    var horizontalPadding: CGFloat {
        max(LaunchConstants.Launcher.minHorizontalPadding, size.width * LaunchConstants.Launcher.horizontalPaddingRatio)
    }

    var topInset: CGFloat {
        max(LaunchConstants.Launcher.minTopInset, size.height * LaunchConstants.Launcher.topInsetRatio)
    }

    var bottomInset: CGFloat {
        LaunchConstants.Launcher.dockReserve
    }

    var searchToGridGap: CGFloat {
        LaunchConstants.Launcher.searchToGridGap
    }

    var gridToPagerGap: CGFloat {
        LaunchConstants.Launcher.gridToPagerGap
    }

    var gridWidth: CGFloat {
        size.width - horizontalPadding * 2
    }

    var columnWidth: CGFloat {
        gridWidth / CGFloat(columns)
    }

    var gridHeight: CGFloat {
        let reserved = topInset + searchToGridGap + LaunchConstants.Launcher.searchHeight
            + gridToPagerGap + LaunchConstants.Launcher.pageDotHeight + bottomInset
        return max(size.height - reserved, LaunchConstants.Launcher.minGridHeight)
    }

    var rowHeight: CGFloat {
        gridHeight / CGFloat(rows)
    }

    var iconSize: CGFloat {
        let fromColumn = columnWidth * LaunchConstants.Launcher.iconColumnScale
        let fromRow = rowHeight * LaunchConstants.Launcher.iconRowScale
        return min(max(min(fromColumn, fromRow), LaunchConstants.Launcher.minIconSize), LaunchConstants.Launcher.maxIconSize)
    }

    var gridColumnSpacing: CGFloat {
        LaunchConstants.Launcher.gridSpacing
    }

    var gridRowSpacing: CGFloat {
        max(LaunchConstants.Launcher.minGridRowSpacing, rowHeight - iconSize - LaunchConstants.Icon.labelHeight - LaunchConstants.Icon.spacing)
    }

    var labelWidth: CGFloat {
        min(columnWidth - 4, LaunchConstants.Icon.maxLabelWidth)
    }
}
