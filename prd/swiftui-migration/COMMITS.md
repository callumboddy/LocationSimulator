# Commit Plan: SwiftUI Migration

Delivered as 8 sequential PRs, each leaving the app fully functional. All PRs merge into `feature/swiftui-migration`, which merges into `develop` when complete.

---

## Progress

| PR | Description | Status |
|----|-------------|--------|
| PR1 | SwiftUI App shell | Pending |
| PR2 | Observable models | Pending |
| PR3 | SwiftUI Sidebar | Pending |
| PR4 | Toolbar & menus | Pending |
| PR5 | Map overlay controls | Pending |
| PR6 | Dialogs & sheets | Pending |
| PR7 | Secondary windows | Pending |
| PR8 | Cleanup | Pending |

---

## PR1: SwiftUI App Shell

Replace the entry point, window structure, and storyboard-driven layout with SwiftUI.

### Commits:

1. **Add `LocationSimulatorApp.swift` with `@main`**
   Create the SwiftUI App struct with a single `WindowGroup`. Remove `main.swift` and `@NSApplicationMain`/`AppDelegate` as entry point. Keep `AppDelegate` as an adapter via `@NSApplicationDelegateAdaptor` for device notification setup and AppleScript support.

2. **Add `MainView` with `NavigationSplitView`**
   Create a `MainView` with `NavigationSplitView` containing a placeholder sidebar and detail. This is the new root view inside `WindowGroup`.

3. **Wrap `MapViewController` in `NSViewControllerRepresentable`**
   Create `MapViewControllerRepresentable` that embeds the existing `MapViewController` as the detail view. All existing map functionality works unchanged.

4. **Wrap sidebar in `NSViewControllerRepresentable`**
   Temporarily wrap the existing `SidebarViewController` so the sidebar works during transition. The storyboard sidebar will be replaced in PR3.

5. **Remove Main.storyboard as launch storyboard**
   Remove the storyboard from Info.plist as the main interface. The SwiftUI `WindowGroup` is now the entry point. Keep the storyboard file temporarily for instantiating view controllers.

6. **Verify and fix toolbar/menu integration**
   Ensure the existing toolbar and menu bar still work through the `AppDelegate` adapter. This is a compatibility bridge until PR4 replaces them.

---

## PR2: Observable Models

Extract state from view controllers into `@Observable` models.

### Commits:

1. **Add `DeviceManager` observable**
   Create `@Observable class DeviceManager` owning `realDevices`, `simDevices`, `simulatorPairs`, `selectedDevice`, `selectedPair`. Move device notification registration from `SidebarDataSource`. Inject via SwiftUI `.environment`.

2. **Add `SpooferState` observable**
   Create `@Observable class SpooferState` owning `spoofer`, `pairedSpoofer`, `deviceStatus`, `moveType`, `speed`, `currentLocation`, `moveState`, `isAutoMoving`, `isNavigating`. Wraps `LocationSpoofer` and `PairedLocationSpoofer` lifecycle.

3. **Migrate `BookmarkStore` to `@Observable`**
   Add `@Observable` to `BookmarkStore`. Remove `NotificationCenter` posting — SwiftUI views will react to property changes automatically. Keep the singleton for backward compat during migration.

4. **Add `MapState` observable**
   Create `@Observable class MapState` owning `mapType`, `autofocusEnabled`, `bookmarkAnnotations`. Drives the map representable.

5. **Wire observable models into the SwiftUI environment**
   Create models in `LocationSimulatorApp` and pass via `.environment`. Update `MapViewControllerRepresentable` to read from environment.

---

## PR3: SwiftUI Sidebar

Replace the AppKit sidebar with native SwiftUI.

### Commits:

1. **Add `SidebarView` with device sections**
   Create `SidebarView` using SwiftUI `List` with `Section` for "iOS Devices", "Simulators", and "Simulator Pairs". Read from `DeviceManager` environment object.

2. **Add device row views**
   Create `DeviceRowView` and `SimulatorPairRowView` for list rows with icons and names.

3. **Wire sidebar selection to SpooferState**
   Bind sidebar selection to `DeviceManager.selectedDevice` / `selectedPair`. On selection change, update `SpooferState` to create the appropriate spoofer.

4. **Remove `SidebarViewController` and `SidebarDataSource`**
   Delete the AppKit sidebar code and its `NSViewControllerRepresentable` wrapper. Remove the temporary wrapper from PR1.

5. **Add search field**
   Add `.searchable` modifier to the sidebar for location search, replacing the custom `SearchbarView`.

---

## PR4: Toolbar & Menus

Replace the storyboard toolbar and menu bar controller with SwiftUI.

### Commits:

1. **Add SwiftUI `.commands` for Navigation menu**
   Define `NavigationCommands` with walk/cycle/drive, set location, reset, recent locations, bookmarks, movement controls. Replace `NavigationMenubarItem` and `MenubarController` navigation actions.

2. **Add SwiftUI `.commands` for View menu**
   Define `ViewCommands` with map type, zoom, sidebar toggle. Replace `ViewMenubarItem`.

3. **Add SwiftUI `.commands` for File menu**
   Define `FileCommands` with GPX file open. Replace `FileMenubarItem`.

4. **Add SwiftUI `.toolbar` to `MainView`**
   Define toolbar items: move type picker, speed control, autofocus toggle, autoreverse toggle. Replace `ToolbarController`.

5. **Remove `MenubarController`, `ToolbarController`, `TouchbarController`**
   Delete the AppKit responder-based menu and toolbar controllers. Remove all `MenubarItem` enum files.

---

## PR5: Map Overlay Controls

Replace HUD NSView subclasses with SwiftUI overlays.

### Commits:

1. **Add `MovementControlsOverlay`**
   SwiftUI view with movement direction indicator and movement button, positioned as an overlay on the map. Reads from `SpooferState`.

2. **Add `SpinnerOverlay`**
   SwiftUI `ProgressView` overlay shown during location changes.

3. **Add `StatusOverlay`**
   SwiftUI overlay for error indicator, play/pause indicator, and distance label.

4. **Integrate overlays into `MainView`**
   Layer the SwiftUI overlays on top of the `MapViewControllerRepresentable` using `.overlay`.

5. **Remove HUD NSView subclasses**
   Delete `HUDView`, `MovementButtonHUDView`, `MovementDirectionHUDView`, `SpinnerHUDView`, and `ContentView` (the NSView, not SwiftUI).

---

## PR6: Dialogs & Sheets

Replace NSAlert-based dialogs with SwiftUI sheets.

### Commits:

1. **Add `CoordinateInputSheet`**
   SwiftUI sheet for entering lat/lon with steppers. Replaces `CoordinateSelectionAlert` and `CoordinateSelectionView.xib`.

2. **Add `SpeedInputSheet`**
   SwiftUI sheet for speed selection. Replaces `SpeedSelectionAlert` and `SpeedSelectionView.xib`.

3. **Add `BookmarkNameSheet`**
   SwiftUI sheet for naming bookmarks with reverse-geocoded placeholder. Replaces the `NSAlert` in `MapViewController`.

4. **Add `GPXSelectionSheet`**
   SwiftUI sheet for GPX file browser. Replaces `GPXSelectionAlert` and `GPXSelectionView.xib`.

5. **Add `TeleportNavigateSheet`**
   SwiftUI confirmation for teleport vs navigate action. Replaces the current NSAlert.

6. **Remove XIB files and NSAlert subclasses**
   Delete all 5 XIB files and their backing AppKit classes.

---

## PR7: Secondary Windows

Replace auxiliary window controllers with SwiftUI Window scenes.

### Commits:

1. **Add Preferences as SwiftUI `Window`**
   Create `SettingsView` with `TabView` for General, Network, Developer Disk Images, License, Info. Use SwiftUI `Settings` scene. Remove `PreferenceWindowController` and all preference view controllers.

2. **Add Log Viewer as SwiftUI `Window`**
   Create `LogView` with table display. Use `Window("Log", ...)` scene. Remove `LogWindowController` and `LogViewController`.

3. **Add Donate as SwiftUI `Window`**
   Create `DonateView` with split layout. Use `Window("Donate", ...)` scene. Remove `DonateWindowController` and related view controllers.

4. **Add Onboarding as SwiftUI sheet**
   Create `OnboardingView` with paged layout. Show on first launch. Remove all onboarding view controllers.

---

## PR8: Cleanup

Remove all dead AppKit code.

### Commits:

1. **Remove Main.storyboard**
   Delete the storyboard file and all storyboard references from the project.

2. **Remove dead AppKit view controllers**
   Delete `MapViewController`, `NoDeviceViewController`, `SplitViewController`, and any remaining NSViewController subclasses whose logic has been moved.

3. **Remove dead AppKit views**
   Delete custom NSView subclasses that have been replaced by SwiftUI: `ContentView` (NSView), `SearchbarView`, `ArrowView`, `PageControl`, `ProgressBar`, `ValueTrackingSlider`, `DragAndDropBox`, `SeparatorLine`, etc.

4. **Remove dead window controllers**
   Delete `WindowController`, `Window.swift`, and any remaining NSWindowController subclasses.

5. **Remove unused extensions and utilities**
   Clean up AppKit-specific extensions (NSView, NSMenuItem, NSResponder) that are no longer referenced. Remove `SidebarStyle`, `SidebarItem` protocol, and header structs.

6. **Final audit**
   Grep for remaining AppKit imports. Verify all tests pass. Verify no storyboard/XIB references remain. Tag the migration as complete.
