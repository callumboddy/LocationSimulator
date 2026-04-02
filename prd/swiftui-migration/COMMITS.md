# Commit Plan: SwiftUI Migration

Delivered as 8 sequential PRs, each leaving the app fully functional. All PRs merge into `feature/swiftui-migration`, which merges into `develop` when complete.

---

## Progress

| PR | Description | Status |
|----|-------------|--------|
| PR1 | SwiftUI App shell | Done |
| PR2 | Observable models | Done |
| PR3 | SwiftUI Sidebar + Map detail | Done |
| PR4 | Toolbar & menus | Pending |
| PR5 | Map overlay controls | Partially done (placeholder overlays in place) |
| PR6 | Dialogs & sheets | Pending |
| PR7 | Secondary windows | Pending |
| PR8 | Cleanup | Pending |

---

## Commit Log

| SHA | Description | PR |
|-----|-------------|-----|
| `0b3aa82` | Add PRD and commit plan for SwiftUI migration | - |
| `bef571e` | Replace main.swift with @main SwiftUI App lifecycle | PR1 |
| `17534b4` | Switch main window to SwiftUI WindowGroup | PR1 |
| `8dfc399` | Add Observable models and wire into SwiftUI environment | PR2 |
| `a30a29f` | Add SwiftUI sidebar with NavigationSplitView | PR3 |
| `f46d86f` | Add SwiftUI map detail with overlays | PR3/PR5 |
| `582e691` | Use ipod.and.applewatch icon for simulator pairs | PR3 |
| `a465338` | Wire MapViewController as non-visual coordinator for spoofing | PR3 |

---

## PR1: SwiftUI App Shell — DONE

Replaced the app entry point and window structure with SwiftUI.

### What was done:

1. **`bef571e` — Replace main.swift with @main SwiftUI App lifecycle**
   - Created `LocationSimulatorApp.swift` with `@main` attribute
   - Deleted `main.swift` (and the `--no-ui` headless mode, not needed)
   - Used `@NSApplicationDelegateAdaptor(AppDelegate.self)` to keep AppDelegate for menu bar setup and AppleScript
   - Moved UserDefaults registration and logger init from `main.swift` to `LocationSimulatorApp.init()`
   - Changed `NSPrincipalClass` in Info.plist from `LSApplication` to `NSApplication` (custom NSApplication subclass was causing sandbox crash with @main)
   - Updated deployment target to macOS 26.0 across all build configurations
   - Changed `AppDelegate.menubarController` from `@IBOutlet` to direct instantiation since the AppDelegate is no longer loaded from the storyboard nib

2. **`17534b4` — Switch main window to SwiftUI WindowGroup**
   - Changed `LocationSimulatorApp.body` from an empty `Settings` scene to a `WindowGroup` containing `MainView`
   - `MainView` initially wrapped the storyboard `SplitViewController` via `NSViewControllerRepresentable`
   - Removed manual window creation from `AppDelegate.applicationDidFinishLaunching`
   - Added `storyboardIdentifier="SplitViewController"` to the storyboard scene
   - **Note:** Toolbar was lost at this point since it was owned by the storyboard's `WindowController` which is no longer used. Will be restored as SwiftUI `.toolbar` in PR4.

### Key decisions:
- The storyboard is kept on disk for instantiating view controllers (MapViewController, etc.) but is no longer the app's main interface
- `NSMainStoryboardFile` remains in Info.plist — with `@NSApplicationDelegateAdaptor` the storyboard is still loaded for menu bar items

---

## PR2: Observable Models — DONE

Extracted state management into `@Observable` models.

### What was done:

1. **`8dfc399` — Add Observable models and wire into SwiftUI environment**
   - Created `DeviceManager` (`@Observable`) in `Models/DeviceManager.swift`:
     - Owns `realDevices: [IOSDevice]`, `simDevices: [SimulatorDevice]`, `simulatorPairs: [SimulatorPair]`
     - Owns `selectedDevice: Device?` and `selectedPair: SimulatorPair?`
     - `startDiscovery()` starts device notifications and a delayed pair refresh
     - `stopDiscovery()` stops device notifications
     - Listens for `.DeviceConnected`, `.DeviceChanged`, `.DevicePaired`, `.DeviceDisconnected` notifications
     - `refreshPairs()` calls `SimulatorPairDiscovery`
     - `select(device:)`, `select(pair:)`, `clearSelection()` for selection management
     - Computed `unpairedSimDevices` and `hasPairs` properties
   - Created `SpooferState` (`@Observable`) in `Models/SpooferState.swift`:
     - Owns `spoofer: LocationSpoofer?`, `pairedSpoofer: PairedLocationSpoofer?`
     - Owns `deviceStatus`, `isConnected`, `moveType`, `speed`
     - `setupDevice(_:)` creates a solo spoofer
     - `setupPair(_:)` creates a paired spoofer
     - `tearDown()` cleans up both spoofers
   - Migrated `BookmarkStore` to `@Observable` (added `import Observation` and `@Observable` attribute)
   - Wired all three into SwiftUI environment from `LocationSimulatorApp`:
     ```swift
     .environment(deviceManager)
     .environment(spooferState)
     .environment(BookmarkStore.shared)
     ```

### Key decisions:
- `MapState` was dropped from the plan — not needed since the `MapView` is driven directly
- `SpooferState` is not yet driving the UI — the existing `MapViewController` still manages the spoofer internally. `SpooferState` will take over when the `MapViewController` is fully replaced.
- `BookmarkStore` keeps its `NotificationCenter` posting for now since the storyboard-based `BookmarkMenubarItem` still listens for changes

---

## PR3: SwiftUI Sidebar + Map Detail — DONE

Replaced the AppKit sidebar and connected the map detail view.

### What was done:

1. **`a30a29f` — Add SwiftUI sidebar with NavigationSplitView**
   - Created `SidebarView` in `Views/SidebarView.swift`:
     - SwiftUI `List` with three `Section`s: "iOS Devices", "Simulators", "Simulator Pairs"
     - Reads from `DeviceManager` environment
     - `SidebarItemID` enum (`.device(udid)`, `.pair(name)`) for selection binding
     - `DeviceRow` view using SF Symbols: `wifi` for real devices, `iphone` for phone sims, `applewatch` for watch sims, `ipod.and.applewatch` for pairs
     - Watch detection via `device.name.lowercased().contains("watch")`
     - Pair names displayed as "iPhone Air + Apple Watch Series 11 (42mm)"
     - Selection drives `DeviceManager.select(device:)` / `select(pair:)` / `clearSelection()`
   - Updated `MainView` to use `NavigationSplitView`:
     - Sidebar: `SidebarView()`
     - Detail: `DetailView()` which shows `MapDetailView` when a device is selected, or `ContentUnavailableView` when nothing is selected
     - Calls `deviceManager.startDiscovery()` on appear
   - Created placeholder `MapViewRepresentable` with a basic `MKMapView`

2. **`f46d86f` — Add SwiftUI map detail with overlays**
   - Created `MapOverlays.swift` with SwiftUI overlay views:
     - `SpinnerOverlay` — `ProgressView` in top-right with material background
     - `MovementControlsOverlay` — location button in bottom-left with long-press for auto-move
     - `StatusOverlay` — compact pill in bottom-left showing distance, play/pause state, error indicator
   - Created `MapDetailView` composing `MapViewRepresentable` with all overlays in a `ZStack`
   - Overlays are placeholder-wired with `@State` vars and TODOs — not yet connected to `SpooferState`

3. **`582e691` — Use ipod.and.applewatch icon for simulator pairs**

4. **`a465338` — Wire MapViewController as non-visual coordinator for spoofing**
   - **Key insight:** Embedding the storyboard `MapViewController` via `NSViewControllerRepresentable` didn't work — the `ContentView` (NSView) with all its IBOutlets wouldn't render. The storyboard view hierarchy depends on being inside its original window controller context.
   - **Solution:** Use the `MapViewController` as a non-visual coordinator:
     - Instantiate it from storyboard (so all IBOutlets connect to its own view)
     - Swap `mapVC.mapView` to point at our SwiftUI-hosted `MapView` instance
     - Wire `longPressAction`, `markerDragAction`, `bookmarkAction` closures on our `MapView` to call `MapViewController` methods
     - The `MapViewController`'s own view is never displayed — only our `MapView` is
   - `MapViewRepresentable` uses a `Coordinator` class to hold a strong reference to the `MapViewController`
   - On device selection change in `updateNSView`, sets `mapVC.device` or `mapVC.simulatorPair` and calls `connectDevice()`
   - Added `activeWindow` computed property to `MapViewController` — returns `mapView?.window ?? self.view.window` so that alerts and sheets can find the window when the VC's own view isn't in the hierarchy
   - Replaced all `self.view.window` references in `MapViewController.swift` with `self.activeWindow`
   - Fixed force-unwrap crash in `MapViewController+LocationSpooferDelegate.swift` where `self.view.window!` was used
   - Made `showBookmarkDialog(for:)` internal (was private) so the representable can call it

### Key decisions:
- The storyboard `SplitViewController` and `SidebarViewController` are no longer used for the main window, but remain in the project for now
- `MapViewController` is kept alive as a controller object — it manages the full spoofer lifecycle including device pairing, teleport/navigate dialogs, location spoofer delegate callbacks, navigation route calculation, and GPX routing. Rewriting all of this in SwiftUI is a large separate effort.
- The storyboard is still needed to instantiate `MapViewController` (for its IBOutlet connections to its own `ContentView`), even though that view is never displayed

---

## Remaining Work

### What's working now:
- SwiftUI app lifecycle with `@main`
- SwiftUI `WindowGroup` owns the main window
- Native SwiftUI sidebar with device/simulator/pair sections and icons
- `@Observable` models (`DeviceManager`, `SpooferState`, `BookmarkStore`) in the environment
- Map rendering via `NSViewRepresentable` wrapping the custom `MapView`
- Device pairing and location spoofing (teleport + navigate)
- Bookmark creation via right-click context menu
- Bookmark pins on the map
- Paired device simulation (phone + watch)
- SwiftUI overlay placeholders (spinner, movement controls, status bar)

### What's not working / missing:
- **Toolbar** — lost when we bypassed the storyboard `WindowController`. Needs SwiftUI `.toolbar` (PR4)
- **Menu bar** — partially working via `AppDelegate` adapter. The storyboard menu bar items still function but aren't SwiftUI-native yet (PR4)
- **Overlay wiring** — the SwiftUI overlays (spinner, movement controls, status) are placeholder-wired with `@State` but not connected to `SpooferState`. The actual HUD behavior still runs through the old `ContentView` (which exists in the MapViewController's storyboard view but is never displayed). Need to connect overlays to real state (PR5)
- **Dialogs** — still using AppKit `NSAlert` and custom alert subclasses. Work fine through `activeWindow`. Migration to SwiftUI sheets is cosmetic (PR6)
- **Secondary windows** — Preferences, Donate, Log Viewer still use storyboard/AppKit window controllers (PR7)
- **Dead code cleanup** — `SplitViewController`, `SidebarViewController`, `SidebarDataSource`, `WindowController`, `NoDeviceViewController`, HUD NSView subclasses, and their storyboard scenes are still in the project (PR8)

### Suggested next steps (in priority order):
1. **PR4: SwiftUI toolbar** — most visible missing piece, restores move type/speed/autofocus controls
2. **PR5: Wire overlays to SpooferState** — connect the SwiftUI overlays to real spoofer state so spinner/controls/status actually reflect what's happening
3. **PR6-8** — lower priority, can be done incrementally

---

## PR4: Toolbar & Menus — PENDING

Replace the storyboard toolbar and menu bar controller with SwiftUI.

### Planned commits:

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

## PR5: Map Overlay Controls — PARTIALLY DONE

Replace HUD NSView subclasses with SwiftUI overlays.

### Done:
- Placeholder SwiftUI overlays created (`SpinnerOverlay`, `MovementControlsOverlay`, `StatusOverlay`)
- Overlays positioned correctly in `MapDetailView` ZStack

### Remaining:
1. **Wire overlays to SpooferState** — connect `isSpinning`, `showControls`, `isAutoMoving`, `totalDistanceKM`, `playPauseState`, `showError` to real spoofer callbacks
2. **Remove HUD NSView subclasses** — once overlays are fully wired

---

## PR6: Dialogs & Sheets — PENDING

Replace NSAlert-based dialogs with SwiftUI sheets.

### Planned commits:

1. **Add `CoordinateInputSheet`** — replaces `CoordinateSelectionAlert` and `CoordinateSelectionView.xib`
2. **Add `SpeedInputSheet`** — replaces `SpeedSelectionAlert` and `SpeedSelectionView.xib`
3. **Add `BookmarkNameSheet`** — replaces the `NSAlert` in `MapViewController`
4. **Add `GPXSelectionSheet`** — replaces `GPXSelectionAlert` and `GPXSelectionView.xib`
5. **Add `TeleportNavigateSheet`** — replaces the current NSAlert
6. **Remove XIB files and NSAlert subclasses**

---

## PR7: Secondary Windows — PENDING

Replace auxiliary window controllers with SwiftUI Window scenes.

### Planned commits:

1. **Add Preferences as SwiftUI `Settings`** — replaces `PreferenceWindowController` and all preference VCs
2. **Add Log Viewer as SwiftUI `Window`** — replaces `LogWindowController` and `LogViewController`
3. **Add Donate as SwiftUI `Window`** — replaces `DonateWindowController` and related VCs
4. **Add Onboarding as SwiftUI sheet** — replaces all onboarding VCs

---

## PR8: Cleanup — PENDING

Remove all dead AppKit code.

### Planned commits:

1. **Remove Main.storyboard** — delete storyboard file and all references
2. **Remove dead AppKit view controllers** — `MapViewController` (once fully replaced), `NoDeviceViewController`, `SplitViewController`, etc.
3. **Remove dead AppKit views** — `ContentView` (NSView), `SearchbarView`, `ArrowView`, `PageControl`, HUD views, etc.
4. **Remove dead window controllers** — `WindowController`, `Window.swift`, etc.
5. **Remove unused extensions** — AppKit-specific extensions no longer referenced
6. **Final audit** — grep for remaining AppKit imports, verify all tests pass
