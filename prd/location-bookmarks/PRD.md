# PRD: Location Bookmarks

## Problem Statement

When a simulator is selected in LocationSimulator, the map starts zoomed all the way out. Developers who frequently test at specific locations (their office, a client site, a test route start point) must manually zoom and pan to find the same place every time. This is slow and repetitive. The existing "Recent Locations" feature auto-saves the last 10 visited locations, but entries are ephemeral and unnamed — they get pushed out as new locations are visited.

## Solution

Allow developers to save named bookmark locations that persist indefinitely. Bookmarks appear as pins on the map for one-click access and in a menu bar dropdown for keyboard-driven workflows. Creating a bookmark is as simple as right-clicking the map and typing a name.

## User Stories

1. As a developer, I want to right-click any point on the map and choose "Bookmark this location", so that I can save locations I visit frequently.
2. As a developer, I want to name my bookmark when creating it, so that I can identify it quickly later.
3. As a developer, I want the name dialog to suggest a reverse-geocoded address as a placeholder, so that I can accept a sensible default or type my own name.
4. As a developer, I want my bookmarks to appear as pins on the map with a distinct icon and name label, so that I can visually find and click them.
5. As a developer, I want bookmark pins to always be visible on the map, so that I have fast access to saved locations without navigating menus.
6. As a developer, I want bookmark pins to look different from the current location marker, so that I don't confuse bookmarks with my spoofed position.
7. As a developer, I want to click a bookmark pin on the map and see the teleport/navigate dialog, so that interacting with bookmarks works the same as clicking any other map location.
8. As a developer, I want my bookmarks to appear in a "Bookmarks" submenu under Navigation in the menu bar, so that I can access them via keyboard or menu.
9. As a developer, I want bookmarks in the menu sorted alphabetically, so that I can scan and find them quickly.
10. As a developer, I want to click a bookmark in the menu and see the teleport/navigate dialog, so that menu-driven access works the same as map-driven access.
11. As a developer, I want to right-click a bookmark in the menu to rename it, so that I can update names as my workflow changes.
12. As a developer, I want to right-click a bookmark in the menu to delete it, so that I can remove locations I no longer need.
13. As a developer, I want a "Clear All Bookmarks" option in the menu, so that I can start fresh if needed.
14. As a developer, I want my bookmarks to persist across app launches, so that I don't have to re-create them every session.
15. As a developer, I want there to be no limit on the number of bookmarks, so that I can save as many locations as I need.
16. As a developer, I want bookmarks to be completely separate from Recent Locations, so that bookmarking doesn't affect my recent history and vice versa.
17. As a developer, I want bookmark pins to appear on the map regardless of which simulator device is selected, so that my saved locations are always available.
18. As a developer, I want to be able to create bookmarks even before connecting to a device, so that I can set up my locations in advance.

## Implementation Decisions

### Modules

- **BookmarkStore (New):** Manages persistence of bookmarks in UserDefaults. Reuses the existing `Location` Codable model (name, latitude, longitude). Provides CRUD operations: add, rename, delete, clear all. Returns bookmarks sorted alphabetically by name. Posts a notification when bookmarks change so the map and menu stay in sync.

- **BookmarkMenubarItem (New):** A menu bar item under the Navigation menu, sibling to Recent Locations. Displays all bookmarks alphabetically. Clicking an entry triggers the teleport/navigate dialog at that coordinate. Right-click context menu on each entry provides Rename and Delete. A "Clear All Bookmarks" separator item at the bottom. Follows the same pattern as `RecentLocationMenubarItem`.

- **MapView (Modified):** Add bookmark annotation support. Display bookmark pins using a distinct annotation view (star/bookmark icon) with the bookmark name as a label. Pins are always visible. Clicking a bookmark pin triggers the same action as clicking any point on the map (teleport/navigate dialog). Annotations refresh when BookmarkStore posts a change notification.

- **MapViewController (Modified):** Handle right-click context menu on the map. Add a "Bookmark this location" option that captures the clicked coordinate, reverse-geocodes it for a placeholder name, shows a name dialog, and saves to BookmarkStore. Wire bookmark pin clicks to the existing teleport/navigate flow.

- **MenubarController (Modified):** Register the new BookmarkMenubarItem in the Navigation menu alongside the existing Recent Locations item.

### Architecture

- Bookmarks use the same `Location` model as Recent Locations — no new data types needed.
- BookmarkStore is a simple singleton wrapping UserDefaults with a distinct key from Recent Locations.
- Bookmark pins are `MKAnnotation` objects added to the map view, using a custom annotation view to distinguish them from the current location marker.
- The reverse-geocoding for the name placeholder uses `CLGeocoder`, which is already available in the project.
- The name dialog uses `NSAlert` with an accessory `NSTextField`.

### Storage

- UserDefaults key: `com.schlaubischlump.locationsimulator.bookmarks`
- Encoded/decoded with `PropertyListEncoder`/`PropertyListDecoder`, matching the existing Recent Locations pattern.
- No item limit.

## Testing Decisions

Good tests verify external behavior through the module's public interface, not implementation details. Tests should be resilient to internal refactoring.

### Modules to test

- **BookmarkStore:** Test add, rename, delete, clear all operations. Verify alphabetical ordering. Verify persistence round-trip (encode/decode). Test edge cases: duplicate names, empty name, special characters. Test that change notifications are posted on mutations.

### Prior art

Follow the test patterns established in the multi-device feature: Swift Testing framework with `#expect`/`#require` macros in the existing `LocationSimulatorTests` target.

## Out of Scope

- **Toolbar button for bookmarks** — deferred to SwiftUI migration.
- **SwiftUI migration** — tracked as a separate future task.
- **Import/export bookmarks** — could be added later but not needed now.
- **Bookmark folders or categories** — flat list is sufficient for now.
- **Bookmark ordering customization** — alphabetical only.
- **Syncing bookmarks across machines** — local UserDefaults only.

## Further Notes

- The right-click context menu on the map may need to coexist with the existing long-press/click behavior. Ensure existing click-to-teleport and long-press-to-navigate flows are not disrupted.
- Reverse geocoding requires network access — the app already has the `com.apple.security.network.client` entitlement.
- If reverse geocoding fails (offline, rate limited), the placeholder should fall back to the coordinate string (e.g. "37.7749, -122.4194").
