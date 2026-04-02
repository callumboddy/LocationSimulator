# Commit Plan: Location Bookmarks

Ordered sequence of commits to implement the PRD. Each commit is small, self-contained, and leaves the project in a buildable state.

---

## Commit Log

| # | Commit | SHA | Status |
|---|--------|-----|--------|
| 1 | Add BookmarkStore | `d4520ab` | Done |
| 2 | Add tests for BookmarkStore | `8b74e15` | Done |
| 3-4 | Add BookmarkMenubarItem + wire into Navigation | `5f834e5` | Done (merged 3-4) |
| 5-6 | Right-click menu + bookmark dialog with geocoding | `70c67af` | Done (merged 5-6) |
| 7-8 | Bookmark map pins with click-to-navigate | `ed243f5` | Done (merged 7-8) |
| 9-10 | Rename, delete and clear all bookmarks | `2e8125d` | Done (merged 9-10) |

---

## Phase 1: Storage

### Commit 1: Add BookmarkStore
Create a `BookmarkStore` singleton that wraps UserDefaults for bookmark persistence. Reuses the existing `Location` model. Provides `add`, `rename`, `delete`, `clearAll`, and `allBookmarks` (sorted alphabetically). Posts `Notification.Name.BookmarksChanged` on mutations.

### Commit 2: Add tests for BookmarkStore
Test CRUD operations, alphabetical ordering, persistence round-trip, duplicate name handling, and notification posting. Use a custom UserDefaults suite to isolate tests.

---

## Phase 2: Menu Bar

### Commit 3: Add BookmarkMenubarItem
Create `BookmarkMenubarItem` following the same pattern as `RecentLocationMenubarItem`. Displays bookmarks alphabetically as menu items. Clicking an entry calls `requestLocationChange` to trigger the teleport/navigate dialog.

### Commit 4: Wire BookmarkMenubarItem into Navigation menu
Register the new item in `MenubarController` so it appears under Navigation alongside Recent Locations. Add the `BOOKMARKS_MENUITEM` localization string.

---

## Phase 3: Map Creation

### Commit 5: Add right-click context menu to map
Add an `NSMenu` to the MapView that appears on right-click. Include a "Bookmark this location" item that captures the clicked coordinate.

### Commit 6: Add bookmark name dialog with reverse geocoding
When "Bookmark this location" is selected, reverse-geocode the coordinate for a placeholder name, show an `NSAlert` with a text field, and save to `BookmarkStore` on confirm. Fall back to coordinate string if geocoding fails.

---

## Phase 4: Map Pins

### Commit 7: Add bookmark annotations to MapView
Create a `BookmarkAnnotation` class conforming to `MKAnnotation`. Add all bookmarks as annotations on the map with a distinct icon (star/bookmark) and name label. Listen for `BookmarksChanged` notification to refresh pins.

### Commit 8: Wire bookmark pin clicks to teleport/navigate
When a bookmark annotation is tapped, trigger the same teleport/navigate dialog as clicking any other point on the map.

---

## Phase 5: Management

### Commit 9: Add rename and delete via menu right-click
Add right-click context menu to bookmark menu items with "Rename" (shows name dialog) and "Delete" options. Update BookmarkStore and refresh the menu and map pins.

### Commit 10: Add "Clear All Bookmarks" menu item
Add a separator and "Clear All Bookmarks" item at the bottom of the bookmarks menu. Clears BookmarkStore and removes all bookmark annotations from the map.
