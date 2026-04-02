//
//  SimulatorPairDiscovery.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import Foundation
import LocationSpoofer

/// Discovers Watch-Phone simulator pairs by reading CoreSimulator's device_set.plist
/// and cross-referencing with currently known booted simulators.
class SimulatorPairDiscovery {

    /// A parsed booted pair containing just UDIDs (no framework dependencies).
    struct BootedPairInfo: Equatable {
        let phoneUDID: String
        let phoneName: String
        let watchUDID: String
        let watchName: String
    }

    /// JSON structure matching `xcrun simctl list pairs --json` output.
    struct SimctlPairsResponse: Decodable {
        let pairs: [String: SimctlPair]
    }

    struct SimctlPair: Decodable {
        let watch: SimctlDevice
        let phone: SimctlDevice
        let state: String
    }

    struct SimctlDevice: Decodable {
        let name: String
        let udid: String
        let state: String
    }

    /// Plist structure for a pair entry in device_set.plist
    private struct PlistPairEntry {
        let companionUDID: String  // phone
        let gizmoUDID: String      // watch
        let isActive: Bool
    }

    /// Discover all Watch-Phone simulator pairs where both devices are currently booted.
    /// - Parameter knownSimulators: the list of currently known simulator devices from the sidebar
    /// - Returns: an array of `SimulatorPair` for pairs where both devices are booted and recognized
    static func discoverPairs(knownSimulators: [SimulatorDevice]) -> [SimulatorPair] {
        let pairEntries = readPairsFromPlist()
        let simulatorsByUDID = Dictionary(
            knownSimulators.map { ($0.udid, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return pairEntries.compactMap { entry in
            guard entry.isActive else { return nil }
            guard let phone = simulatorsByUDID[entry.companionUDID],
                  let watch = simulatorsByUDID[entry.gizmoUDID] else { return nil }
            return SimulatorPair(phone: phone, watch: watch)
        }
    }

    /// Read pair data from CoreSimulator's device_set.plist.
    /// This avoids shelling out to `xcrun simctl` which fails in sandboxed apps.
    private static func readPairsFromPlist() -> [PlistPairEntry] {
        // In a sandboxed app, NSHomeDirectory() returns the container path.
        // We need the real user home to find CoreSimulator data.
        let realHome: String
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            realHome = String(cString: dir)
        } else {
            realHome = NSHomeDirectory()
        }

        let path = realHome
            + "/Library/Developer/CoreSimulator/Devices/device_set.plist"

        if let entries = parsePlistAt(path: path) {
            return entries
        }

        return []
    }

    private static func parsePlistAt(path: String) -> [PlistPairEntry]? {
        guard let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(
                from: data, options: [], format: nil
              ) as? [String: Any],
              let devicePairs = plist["DevicePairs"] as? [String: [String: Any]]
        else {
            return nil
        }

        return devicePairs.values.compactMap { entry in
            guard let companion = entry["companion"] as? String,
                  let gizmo = entry["gizmo"] as? String else { return nil }
            let isActive = entry["active"] as? Bool ?? false
            return PlistPairEntry(
                companionUDID: companion,
                gizmoUDID: gizmo,
                isActive: isActive
            )
        }
    }

    /// Parse the simctl JSON and return info for pairs where both devices are booted.
    /// This method has no framework dependencies and is fully testable.
    /// - Parameter data: raw JSON from `xcrun simctl list pairs --json`
    /// - Returns: array of `BootedPairInfo` for pairs where both devices report as booted
    static func parseBootedPairInfos(from data: Data) -> [BootedPairInfo] {
        guard let response = try? JSONDecoder().decode(
            SimctlPairsResponse.self, from: data
        ) else {
            return []
        }

        return response.pairs.values.compactMap { pair in
            guard pair.watch.state == "Booted",
                  pair.phone.state == "Booted" else { return nil }
            return BootedPairInfo(
                phoneUDID: pair.phone.udid,
                phoneName: pair.phone.name,
                watchUDID: pair.watch.udid,
                watchName: pair.watch.name
            )
        }
    }

    /// Parse the simctl JSON and match against known booted simulators.
    /// - Parameter data: raw JSON from `xcrun simctl list pairs --json`
    /// - Parameter knownSimulators: currently known simulator devices
    /// - Returns: array of `SimulatorPair` where both devices are booted
    static func parsePairs(
        from data: Data,
        knownSimulators: [SimulatorDevice]
    ) -> [SimulatorPair] {
        let bootedPairs = parseBootedPairInfos(from: data)
        let simulatorsByUDID = Dictionary(
            knownSimulators.map { ($0.udid, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return bootedPairs.compactMap { info in
            guard let phone = simulatorsByUDID[info.phoneUDID],
                  let watch = simulatorsByUDID[info.watchUDID]
            else { return nil }
            return SimulatorPair(phone: phone, watch: watch)
        }
    }
}
