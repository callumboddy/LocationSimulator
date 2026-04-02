//
//  SidebarDataSource.swift
//  LocationSimulator
//
//  Created by David Klopp on 23.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import LocationSpoofer

/// This class is responsible for managing the devices.
class SidebarDataSource: NSObject {
    public weak var sidebarView: NSOutlineView?

    /// List with all currently detected iOS devices.
    public var realDevices: [IOSDevice] = []

    /// List with all currently detected simulator devices.
    public var simDevices: [SimulatorDevice] = []

    /// List of detected Watch-Phone simulator pairs (both booted).
    public var simulatorPairs: [SimulatorPair] = []

    /// UDIDs of devices that belong to an active pair (excluded from solo simulator list).
    private var pairedDeviceUDIDs: Set<String> {
        var udids = Set<String>()
        for pair in simulatorPairs {
            udids.insert(pair.phone.udid)
            udids.insert(pair.watch.udid)
        }
        return udids
    }

    /// Solo simulators — excludes devices that are part of an active pair.
    var unpairedSimDevices: [SimulatorDevice] {
        let paired = pairedDeviceUDIDs
        return simDevices.filter { !paired.contains($0.udid) }
    }

    /// Whether the "Simulator Pairs" section should be shown (at least one pair exists).
    var showPairsSection: Bool {
        return !simulatorPairs.isEmpty
    }

    /// Total number of rows: iOS header + iOS devices + Sim header + solo sims + (optional) Pairs header + pairs
    private var totalRowCount: Int {
        var count = 1 + realDevices.count + 1 + unpairedSimDevices.count
        if showPairsSection {
            count += 1 + simulatorPairs.count
        }
        return count
    }

    /// Row index where the Simulator Pairs header starts (if shown).
    private var pairsSectionStartRow: Int {
        return 1 + realDevices.count + 1 + unpairedSimDevices.count
    }

    /// The currently selected device or pair.
    /// Returns a Device for solo devices, or a SimulatorPair for paired entries.
    public var selectedItem: Any? {
        get {
            let row = self.sidebarView?.selectedRow ?? -1
            guard row >= 0 else { return nil }
            return item(forRow: row)
        }
    }

    /// The currently selected device (nil if a pair is selected).
    public var selectedDevice: Device? {
        get {
            return selectedItem as? Device
        }
        set {
            if let iosDevice = newValue as? IOSDevice,
                let iosDeviceIndex = self.realDevices.firstIndex(of: iosDevice) {
                self.sidebarView?.selectRowIndexes(IndexSet(integer: 1 + iosDeviceIndex),
                                                   byExtendingSelection: false)
            } else if let simDevice = newValue as? SimulatorDevice,
                        let simDeviceIndex = self.unpairedSimDevices.firstIndex(of: simDevice) {
                let row = 1 + realDevices.count + 1 + simDeviceIndex
                self.sidebarView?.selectRowIndexes(IndexSet(integer: row),
                                                   byExtendingSelection: false)
            } else {
                self.sidebarView?.deselectAll(nil)
            }
        }
    }

    /// The currently selected simulator pair (nil if a solo device is selected).
    public var selectedPair: SimulatorPair? {
        return selectedItem as? SimulatorPair
    }

    // MARK: - Constructor

    init(sidebarView: NSOutlineView) {
        self.sidebarView = sidebarView
        super.init()

        // Register ourself to setup the sidebar
        self.sidebarView?.dataSource = self
        self.sidebarView?.delegate = self
    }

    // MARK: - Row/Item mapping

    /// Returns the item (header, device, or pair) for a given row index.
    func item(forRow row: Int) -> Any? {
        let numIOS = realDevices.count
        let unpaired = unpairedSimDevices

        // iOS Devices header
        if row == 0 { return IOSDeviceHeader() }
        // iOS Devices
        if row <= numIOS { return realDevices[row - 1] }
        // Simulators header
        if row == numIOS + 1 { return SimDeviceHeader() }
        // Solo simulators
        let simStartRow = numIOS + 2
        if row < simStartRow + unpaired.count { return unpaired[row - simStartRow] }

        // Simulator Pairs section
        if showPairsSection {
            let pairsHeaderRow = pairsSectionStartRow
            if row == pairsHeaderRow { return SimPairHeader() }
            let pairIndex = row - pairsHeaderRow - 1
            if pairIndex >= 0 && pairIndex < simulatorPairs.count {
                return simulatorPairs[pairIndex]
            }
        }

        return nil
    }

    // MARK: - Public functions

    /// Update the text and image for the cell at the specific index.
    func updateCell(atIndex index: Int) {
        guard let cell = self.sidebarView?.view(atColumn: 0, row: index, makeIfNecessary: false) as? NSTableCellView,
              index < self.realDevices.count+1, index > 0 else { return }

        let device = self.realDevices[index-1]
        cell.textField?.stringValue = device.name
        cell.imageView?.image = device.image
    }

    /// Refresh the simulator pairs list from simctl and reload the sidebar.
    func refreshPairs() {
        let oldPairs = simulatorPairs
        simulatorPairs = SimulatorPairDiscovery.discoverPairs(knownSimulators: simDevices)

        if oldPairs != simulatorPairs {
            sidebarView?.reloadData()
        }
    }
}

// MARK: - NSOutlineViewDataSource

extension SidebarDataSource: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return self.item(forRow: index) ?? NSNull()
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return totalRowCount
    }
}

// MARK: - NSOutlineViewDelegate

extension SidebarDataSource: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor viewForTableColumn: NSTableColumn?, item: Any) -> NSView? {
        // Weird swift bug:
        // https://stackoverflow.com/questions/42033735/failing-cast-in-swift-from-any-to-protocol
        guard let item = (item as AnyObject) as? SidebarItem else { return nil }
        // Create the NSTableView cell for the outline view.
        let cell = self.sidebarView?.makeView(withIdentifier: item.identifier, owner: self) as? NSTableCellView
        cell?.textField?.stringValue = item.name
        cell?.toolTip = item.name
        cell?.imageView?.image = item.image

        return cell
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        // Do not allow selecting a header cell.
        if (item as AnyObject) as? IOSDeviceHeader != nil ||
           (item as AnyObject) as? SimDeviceHeader != nil ||
           (item as AnyObject) as? SimPairHeader != nil {
            return false
        }

        // Allow selecting a device, if it is not already selected.
        if let device = (item as AnyObject) as? IOSDevice {
            return ((self.selectedDevice as? IOSDevice) != device)
        }

        if let simDevice = (item as AnyObject) as? SimulatorDevice {
            return ((self.selectedDevice as? SimulatorDevice) != simDevice)
        }

        // Allow selecting a pair, if it is not already selected.
        if let pair = (item as AnyObject) as? SimulatorPair {
            return self.selectedPair != pair
        }

        // Default, should never be the case.
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        // The header cell is a group cell
        guard let item = (item as AnyObject) as? SidebarItem else { return false }
        return item.isGroupItem
    }

    // func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    //     return 28
    // }
}
