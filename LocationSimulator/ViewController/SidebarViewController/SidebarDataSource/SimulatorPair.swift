//
//  SimulatorPair.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import AppKit
import LocationSpoofer

/// A Watch-Phone simulator pair detected from Xcode's simctl.
/// The phone is the primary device; the watch mirrors its location.
struct SimulatorPair: Equatable {
    /// The phone simulator (primary device).
    let phone: SimulatorDevice
    /// The watch simulator (secondary device).
    let watch: SimulatorDevice

    /// Display name combining both device names.
    var name: String {
        return "\(phone.name) + \(watch.name)"
    }

    static func == (lhs: SimulatorPair, rhs: SimulatorPair) -> Bool {
        return lhs.phone == rhs.phone && lhs.watch == rhs.watch
    }
}

/// Sidebar header for the "Simulator Pairs" group.
struct SimPairHeader: SidebarItem {
    var name: String {
        return "SIMULATOR_PAIR_HEADER".localized
    }

    var image: NSImage? {
        return nil
    }

    var isGroupItem: Bool {
        return true
    }

    var identifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
    }
}

/// Support SimulatorPair as a sidebar item.
extension SimulatorPair: SidebarItem {
    var image: NSImage? {
        return NSImage(named: "Simulator")
    }

    var isGroupItem: Bool {
        return false
    }

    var identifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(rawValue: "DeviceCell")
    }
}
