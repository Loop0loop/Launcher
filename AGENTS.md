# Agent Instructions

## Product Goal

Build a native-feeling macOS Launchpad replacement. The bar is Apple's
Launchpad-level interaction quality: smooth gestures, reliable drag and drop,
clean folder behavior, no stale visual state, and predictable keyboard/mouse
escape paths.

Current priority bugs:

- Gestures do not feel native-grade.
- Folder drag/folder construction is unreliable.
- Dragged or clicked app icons can remain faded, leaving a visual ghost state.
- Folder overlay should close by clicking empty/dimmed space, not only by ESC.

## Architecture Rules

- Keep `LaunchCore` pure. It should import `Foundation` only.
- Put pure layout/search/folder/gesture rules in `LaunchCore` and cover
  meaningful branches with `LaunchCheck` assertions.
- Keep AppKit, SwiftUI, persistence, permissions, and system APIs in
  `LaunchApp`.
- `AppState` is the single observable UI model. Prefer domain extensions over
  growing one large file.
- `AppDelegate` owns process-level AppKit wiring. SwiftUI views should call
  `AppState`; AppKit side effects should go through `LauncherActions`.

## Interaction Rules

- Treat app drag, folder drag, folder creation, folder add/remove, page drag,
  and click launch as separate interaction states. Do not let one gesture path
  leave stale state for another.
- Clear transient drag state on cancel, failed drop, successful drop, launcher
  hide, and any new non-drag mouse down.
- Do not re-render or page-offset the grid during icon drag if it can cancel
  SwiftUI drop delivery.
- Folder overlay dismissal must work from the dimmed empty space and must not
  be stolen by underlying folder icons or title field commits.
- Prefer private in-process drag types for internal app movement so external
  apps cannot hijack drag payloads.

## Verification

Run these before claiming a fix:

```sh
swift build
swift run LaunchCheck
```

`swift test` currently reports no tests because this package has no test target.
Use `LaunchCheck` for executable rule checks until a real test target exists.

For UI/gesture changes, also run the app bundle when practical:

```sh
Scripts/build-app.sh
open .build/Launch.app
```

Manual checks for this project:

- Click empty/dimmed space closes an open folder.
- ESC still closes folder/search/launcher in order.
- Drag app onto app creates a folder.
- Drag app onto folder adds it to the folder.
- Failed or canceled drag restores icon opacity.
- Page swipe/trackpad navigation does not fight icon drag.

## Existing Context

There is also a `CLAUDE.md` with code-review-graph guidance. If the graph MCP
tools are available, use them before broad file scans. If they are not
available, fall back to `rg` and focused file reads.
