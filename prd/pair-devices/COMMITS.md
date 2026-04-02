# Commit Plan: Multi-Device Location Simulation

Ordered sequence of commits to implement the PRD. Each commit is small, self-contained, and leaves the project in a buildable state. Earlier commits lay foundations; later commits wire everything together.

---

## Commit Log

| # | Commit | SHA | Status |
|---|--------|-----|--------|
| 1 | Add SimulatorPair model | `24d936a` | Done |
| - | Remove LocationSimulatorHelp target dependency | `5a89db3` | Done (housekeeping) |
| 2 | Add SimulatorPairDiscovery | `1dbafbf` | Done |
| 3 | Add tests for SimulatorPairDiscovery | `a830a42` | Done |
| 4 | Add PairedLocationSpoofer | `3bb0ce8` | Done |
| 5 | Add error handling for secondary spoofer | `bdab935` | Done |
| 6 | Add tests for PairedLocationSpoofer | `1eefb9c` | Done |
| 7 | Add "Simulator Pairs" group to SidebarDataSource | `68da91c` | Done |
| 8-10 | Sidebar selection + MapViewController pair support | `40dccaa` | Done (merged 8-10) |
| - | Fix pair discovery for sandboxed app | `f43704d` | Done (bugfix) |
| 11 | Surface Watch spoofer warnings in the UI | | Pending |
| 12 | Handle pair lifecycle edge cases | | Pending |
| 13 | Hide "Simulator Pairs" group when empty | | Pending |

---

## Phase 1: Pair Discovery

### Commit 1: Add SimulatorPair model ✅ `24d936a`
Define the `SimulatorPair` struct that holds references to a Phone `SimulatorDevice` and a Watch `SimulatorDevice`, plus a computed display name (e.g. "iPhone 16 Pro + Apple Watch Ultra").

### Commit 2: Add SimulatorPairDiscovery ✅ `1dbafbf`
Implement the discovery module that shells out to `xcrun simctl list pairs --json`, parses the JSON, cross-references with currently booted simulators, and returns `[SimulatorPair]`. Expose a single static/class method for the rest of the app to call.

### Commit 3: Add tests for SimulatorPairDiscovery ✅ `a830a42`
Test JSON parsing with sample `simctl` output. Cover: valid pairs with both booted, one device not booted (filtered out), no pairs, malformed JSON. Use protocol-based injection to mock the shell command.

---

## Phase 2: Paired Spoofer

### Commit 4: Add PairedLocationSpoofer ✅ `3bb0ce8`
Create `PairedLocationSpoofer` wrapping two `LocationSpoofer` instances (Phone primary, Watch secondary). Implement the core sync logic: forward location updates from primary to secondary. Expose a delegate protocol matching the patterns MapViewController already uses.

### Commit 5: Add error handling for secondary spoofer ✅ `bdab935`
Handle Watch spoofer failures: log the error, post a notification for the UI to show a warning, but keep the Phone spoofer running. Handle clean shutdown of both spoofers on disconnect.

### Commit 6: Add tests for PairedLocationSpoofer ✅ `1eefb9c`
Test location forwarding to both spoofers. Test primary failure stops both. Test secondary failure is non-blocking. Test clean disconnection tears down both. Use protocol-based mocks for the `LocationSpoofer` instances.

---

## Phase 3: Sidebar Integration

### Commit 7: Add "Simulator Pairs" group to SidebarDataSource ✅ `68da91c`
Add a `simulatorPairs: [SimulatorPair]` property alongside existing `realDevices` and `simDevices`. Add the "Simulator Pairs" header to the outline view data source. Filter paired devices out of the individual "Simulators" list.

### Commit 8: Wire pair discovery into device notifications
Call `SimulatorPairDiscovery` whenever a device connect/disconnect notification fires. Update the `simulatorPairs` array and reload the sidebar. If a pair was active and one device shuts down, deselect and clean up.

### Commit 9: Handle pair selection in SidebarViewController
When the user selects a pair row, pass both devices (as a `SimulatorPair`) through to the detail view controller, rather than a single `Device`.

---

## Phase 4: MapViewController Integration

### Commit 10: Accept SimulatorPair in MapViewController
Add a `simulatorPair: SimulatorPair?` property alongside the existing `device: Device?`. When a pair is set, create a `PairedLocationSpoofer` instead of a single `LocationSpoofer`. All existing map interactions (click, move, navigate) drive the paired spoofer transparently.

### Commit 11: Surface Watch spoofer warnings in the UI
Listen for the warning notification from `PairedLocationSpoofer`. Display a non-blocking indicator (e.g. small icon or status text) when the Watch spoofer has failed. Clear it if the Watch recovers or the pair is deselected.

---

## Phase 5: Cleanup & Polish

### Commit 12: Handle pair lifecycle edge cases
Ensure clean behavior when: switching from a pair to a solo device, switching between pairs, the app quits with an active pair (both devices reset), and re-selecting a pair after a Watch failure.

### Commit 13: Hide "Simulator Pairs" group when empty
If no booted pairs are detected, don't show the "Simulator Pairs" header at all. Show it only when at least one pair is available.
