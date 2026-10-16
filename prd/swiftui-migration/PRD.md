# PRD: SwiftUI Migration

## Problem Statement

LocationSimulator is built entirely in AppKit with storyboards, MVC, and legacy patterns (KVO, NotificationCenter, delegates). The UI code is tightly coupled, hard to test, and painful to modify — adding a simple toolbar button requires storyboard edits, IBOutlet wiring, and multiple files. The codebase has 144 Swift files, 30+ NSView subclasses, a Main.storyboard, 5 XIBs, and zero SwiftUI. State is scattered across WindowController, MapViewController, SidebarDataSource, MenubarController, and UserDefaults with notification-based communication.

## Solution

Incrementally migrate the entire UI layer to SwiftUI with an `@Observable` architecture, targeting macOS 26.0 exclusively. Use an outside-in strategy: replace the app shell and window structure first (where the biggest wins are), embed existing AppKit views via `NSViewRepresentable`/`NSViewControllerRepresentable`, then progressively replace inner views with native SwiftUI. The migration is delivered as 8 sequential PRs, each leaving the app functional.

## User Stories

1. As a developer of LocationSimulator, I want the app to use SwiftUI's `@main App` lifecycle, so that I can define windows, menus, and scenes declaratively.
2. As a developer, I want the sidebar and detail view to use `NavigationSplitView`, so that sidebar selection, device grouping, and split behavior are managed by SwiftUI.
3. As a developer, I want app state managed by `@Observable` models, so that views update automatically without manual notification/KVO wiring.
4. As a developer, I want the toolbar and menu bar defined in SwiftUI's `.toolbar` and `.commands`, so that adding/modifying toolbar items doesn't require storyboard changes.
5. As a developer, I want dialogs (coordinate input, speed, bookmarks) as SwiftUI sheets, so that they're easier to build and test.
6. As a developer, I want HUD controls (movement buttons, direction wheel, spinner) as SwiftUI overlays, so that map overlay layout is declarative.
7. As a developer, I want secondary windows (Preferences, Donate, Log) as SwiftUI `Window` scenes, so that all window management is unified.
8. As a developer, I want all storyboard and XIB files removed, so that the project has a single UI paradigm.
9. As a user, I want the app to look and behave identically before and after migration, so that no functionality is lost.
10. As a user, I want the app to feel faster and more responsive, taking advantage of macOS 26 native SwiftUI performance.

## Implementation Decisions

### Architecture

- **macOS 26.0 minimum** — use latest Swift and SwiftUI APIs including `@Observable`, `NavigationSplitView`, `.inspector`, `@Environment`.
- **Outside-in migration** — shell first, leaves last. AppKit views are wrapped in `NSViewRepresentable` during transition.
- **SwiftUI `@main App`** — replaces `AppDelegate` + storyboard as entry point. AppDelegate logic moves to `@Observable` AppState and SwiftUI `.commands`.
- **`MKMapView` stays as `NSViewRepresentable`** — custom overlays, gesture handlers, and annotation logic are too complex to port to SwiftUI `Map`. Can revisit later.

### Observable Models

- **DeviceManager** (`@Observable`) — owns `realDevices: [IOSDevice]`, `simDevices: [SimulatorDevice]`, `simulatorPairs: [SimulatorPair]`. Starts/stops device notifications. Replaces `SidebarDataSource` device management.
- **SpooferState** (`@Observable`) — owns the active `LocationSpoofer` or `PairedLocationSpoofer`, current location, move state, move type, speed, device status. Replaces state scattered across `MapViewController` and `WindowController`.
- **MapState** (`@Observable`) — map type, autofocus, region, bookmark annotations. Drives the `NSViewRepresentable` map wrapper.
- **BookmarkStore** (`@Observable`) — already exists, just needs `@Observable` conformance instead of NotificationCenter.

### What Stays AppKit

- `MKMapView` and all its delegate extensions — wrapped in `NSViewRepresentable`.
- `LocationSpoofer` framework — external dependency, no changes.
- AppleScript support — `NSApplication` extension, minimal UI coupling.

### What Gets Deleted

- `Main.storyboard` and all 5 XIB files.
- All `NSViewController` subclasses (MapViewController logic moves to the representable coordinator).
- All `NSWindowController` subclasses.
- `SidebarDataSource`, `MenubarController`, `ToolbarController`, `TouchbarController`.
- All HUD `NSView` subclasses (replaced by SwiftUI overlays).
- All `NSAlert`-based dialog classes.

## Testing Decisions

- Existing `BookmarkStore` and `SimulatorPairDiscovery` tests remain unchanged.
- `PairedLocationSpoofer` tests remain unchanged (no UI dependency).
- New tests for observable models: `DeviceManager`, `SpooferState` state transitions.
- Manual testing after each PR to verify visual parity and functionality.

## Out of Scope

- Migrating `MKMapView` to SwiftUI `Map`.
- Redesigning the app's visual appearance (this is a like-for-like migration).
- Adding new features during migration.
- Modifying the `LocationSpoofer` external package.
- Cross-platform (iOS/iPadOS) support.

## Further Notes

- Each PR must leave the app fully functional — no broken intermediate states.
- The migration branch (`feature/swiftui-migration`) stays alive across all 8 PRs.
- PRs merge into the migration branch, which merges into `develop` when complete.
- Expect the most complexity in PR1 (app shell) and PR2 (observable models) as these restructure the foundation. Later PRs are progressively simpler.
- The `main.swift` entry point will need to be replaced by the `@main` attribute on the App struct.
