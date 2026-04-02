# PRD: Multi-Device Location Simulation (Watch-Phone Pairs)

## Problem Statement

LocationSimulator currently supports spoofing the location of a single iOS simulator at a time. Developers working on apps that span both iPhone and Apple Watch need both simulators to share the same spoofed location simultaneously — for example, testing a workout app that uses location on both devices. Today, there is no way to do this without manually managing two separate sessions, which is error-prone and tedious.

## Solution

Automatically detect Watch-Phone simulator pairs (as defined by Xcode) and present them as a single selectable entry in the sidebar. When a pair is selected, both simulators receive the same spoofed location in lockstep — driven from a single map view. The Phone acts as the primary device; the Watch mirrors its location. If the Watch fails, the Phone continues with a non-blocking warning.

## User Stories

1. As a developer, I want to see my booted Watch-Phone simulator pairs in the sidebar, so that I can select them as a single unit.
2. As a developer, I want paired simulators to appear under a "Simulator Pairs" group in the sidebar, so that they are visually distinct from solo devices.
3. As a developer, I want paired devices to not also appear individually in the "Simulators" list, so that I am not confused about which entry to select.
4. As a developer, I want pair entries to display as a single row (e.g. "iPhone 16 Pro + Apple Watch Ultra"), so that the sidebar stays clean and scannable.
5. As a developer, I want to select a pair and have location spoofing apply to both devices simultaneously, so that I can test multi-device location features.
6. As a developer, I want both devices in a pair to always share the exact same coordinates, so that my Watch and Phone apps see consistent location data.
7. As a developer, I want the Phone to be the primary spoofer so that location control (movement, navigation, manual placement) works exactly as it does today.
8. As a developer, I want the Watch to mirror the Phone's location updates automatically, so that I don't have to manage the Watch separately.
9. As a developer, I want only pairs where both simulators are booted to appear in the sidebar, so that every visible pair is ready to use immediately.
10. As a developer, I want the pair list to update automatically when simulators boot or shut down, so that I don't need to manually refresh.
11. As a developer, I want a non-blocking warning (e.g. indicator in the sidebar) if the Watch spoofer fails, so that I'm aware of the issue without interrupting my Phone testing.
12. As a developer, I want the Phone spoofer to keep running if the Watch spoofer fails, so that my primary workflow is not disrupted.
13. As a developer, I want selecting a pair to create a map view that works identically to the current single-device map, so that there is no learning curve.
14. As a developer, I want manual location placement on a pair to update both devices, so that both simulators jump to the clicked coordinate.
15. As a developer, I want auto-move mode on a pair to update both devices, so that continuous movement is reflected on both simulators.
16. As a developer, I want navigation mode on a pair to update both devices along the route, so that route-following is consistent across Watch and Phone.
17. As a developer, I want stopping location simulation on a pair to reset both devices, so that neither simulator is left in a stale spoofed state.
18. As a developer, I want disconnecting from a pair (e.g. switching to another device) to cleanly stop both spoofers, so that there are no lingering side effects.
19. As a developer, I want the app to handle one device in a pair shutting down while active, so that the remaining device stops gracefully and the sidebar updates.
20. As a developer, I want solo (unpaired) simulators to continue working exactly as they do today, so that existing single-device workflows are unaffected.
21. As a developer, I want solo physical iOS devices to continue working exactly as they do today, so that USB/network device workflows are unaffected.

## Implementation Decisions

### Modules

- **SimulatorPairDiscovery (New):** Encapsulates calling `xcrun simctl list pairs --json`, parsing the JSON response, cross-referencing with currently booted simulators, and returning a list of active Watch-Phone pairs. Exposes a simple interface: invoke discovery, receive an array of pair structs containing the Phone and Watch device references. Re-invoked on every device connect/disconnect notification.

- **PairedLocationSpoofer (New):** Wraps two `LocationSpoofer` instances — one for the Phone (primary) and one for the Watch (secondary). Presents a unified interface that the MapViewController can drive without knowing about the pairing details. Forwards all location updates from the primary spoofer to the secondary. Handles secondary spoofer failures gracefully: logs the error, surfaces a warning, but does not interrupt the primary. This is the core deep module with complex sync logic behind a simple facade.

- **SidebarDataSource (Modified):** Add a third data group "Simulator Pairs" alongside "iOS Devices" and "Simulators". Devices that belong to an active pair are excluded from the individual "Simulators" group. The pair list is refreshed automatically whenever device notifications fire, using SimulatorPairDiscovery.

- **SidebarViewController (Modified):** Handle selection of pair entries. When a pair is selected, pass both devices through to the MapViewController so it can create a PairedLocationSpoofer.

- **MapViewController (Modified):** Accept either a single Device or a device pair. When given a pair, instantiate a PairedLocationSpoofer instead of a single LocationSpoofer. The rest of the map interaction (click to place, movement, navigation) remains unchanged — PairedLocationSpoofer handles the coordination internally.

### Architecture

- The `LocationSpoofer` external package is **not modified**. Multi-device coordination happens entirely at the app layer.
- Two independent `LocationSpoofer` instances are created — one per device in the pair. The app orchestrates them.
- The Phone is always the primary spoofer. All map interactions (click, move, navigate) drive the Phone spoofer. The PairedLocationSpoofer mirrors each update to the Watch spoofer.
- Device notifications from LocationSpoofer continue to be the trigger for refreshing the sidebar, including pair discovery.

## Testing Decisions

Good tests verify external behavior through the module's public interface, not implementation details. Tests should be resilient to internal refactoring.

### Modules to test

- **SimulatorPairDiscovery:** Test JSON parsing of `xcrun simctl list pairs` output. Verify correct filtering (only active/booted pairs). Verify paired devices are correctly matched. Test edge cases: no pairs, one device not booted, malformed JSON.

- **PairedLocationSpoofer:** Test that location updates are forwarded to both spoofers. Test that primary spoofer failure stops both. Test that secondary spoofer failure surfaces a warning but does not stop the primary. Test clean disconnection of both spoofers.

### Prior art

Look at existing test patterns in the project. If none exist, use Swift Testing framework with `#expect` / `#require` macros. Use protocol-based dependency injection to mock the `LocationSpoofer` instances in PairedLocationSpoofer tests, and mock the `xcrun` shell output in SimulatorPairDiscovery tests.

## Out of Scope

- **Arbitrary multi-device groups:** Pairing two iPhones, iPhone + iPad, or 3+ devices is not covered. This PRD is scoped to Watch-Phone pairs only.
- **Modifications to the LocationSpoofer package:** All changes are at the app layer.
- **Independent device control:** Both devices in a pair always share the same location. There is no per-device location override within a pair.
- **Real (physical) device pairing:** This feature applies to simulators only. Physical iOS device workflows are unchanged.
- **Manual pair configuration:** Pairs are auto-detected from Xcode's simctl. There is no UI to manually link two simulators.

## Further Notes

- `xcrun simctl list pairs --json` is the discovery mechanism. Its output format should be validated during implementation — Apple may change the schema across Xcode versions.
- If no pairs are detected (e.g. user hasn't configured Watch simulators in Xcode), the "Simulator Pairs" group simply doesn't appear in the sidebar. No empty state needed.
- Future work could extend this to support Phone-Phone pairs or arbitrary device groups, but that would require a separate design pass with different UX considerations.
