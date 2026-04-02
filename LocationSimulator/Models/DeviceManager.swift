//
//  DeviceManager.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import Foundation
import AppKit
import LocationSpoofer
import CLogger
import Observation

/// Manages device discovery and selection. Replaces the device management
/// aspects of SidebarDataSource with an @Observable model that SwiftUI
/// views can react to directly.
@Observable
class DeviceManager {

    /// All currently detected iOS devices.
    var realDevices: [IOSDevice] = []

    /// All currently detected simulator devices.
    var simDevices: [SimulatorDevice] = []

    /// Detected Watch-Phone simulator pairs (both devices booted).
    var simulatorPairs: [SimulatorPair] = []

    /// The currently selected device (nil if a pair is selected or nothing selected).
    var selectedDevice: Device?

    /// The currently selected simulator pair (nil if a solo device is selected).
    var selectedPair: SimulatorPair?

    /// UDIDs of devices that belong to an active pair.
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

    /// Whether any simulator pairs exist.
    var hasPairs: Bool {
        return !simulatorPairs.isEmpty
    }

    // MARK: - Lifecycle

    /// Start listening for device connect/disconnect notifications.
    func startDiscovery() {
        IOSDevice.detectNetworkDevices = UserDefaults.standard.detectNetworkDevices
        IOSDevice.startGeneratingDeviceNotifications()
        SimulatorDevice.startGeneratingDeviceNotifications()
        registerNotifications()

        // Delayed pair refresh for already-booted simulators
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.refreshPairs()
        }
    }

    /// Stop listening for device notifications.
    func stopDiscovery() {
        IOSDevice.stopGeneratingDeviceNotifications()
        SimulatorDevice.stopGeneratingDeviceNotifications()
    }

    // MARK: - Notifications

    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(deviceConnected(_:)),
            name: .DeviceConnected, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(deviceChanged(_:)),
            name: .DeviceChanged, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(devicePaired(_:)),
            name: .DevicePaired, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(deviceDisconnected(_:)),
            name: .DeviceDisconnected, object: nil
        )
    }

    @objc private func deviceConnected(_ notification: Notification) {
        if var device = notification.userInfo?["device"] as? IOSDevice {
            if realDevices.contains(device) { return }
            logInfo("Device \"\(device.udid)\" - \(device.name): Connected.")
            device.preferNetworkConnection = UserDefaults.standard.preferNetworkDevices
            let index = realDevices.insertionIndexOf(device) { $0.name < $1.name }
            realDevices.insert(device, at: index)
        } else if let device = notification.userInfo?["device"] as? SimulatorDevice {
            if simDevices.contains(device) { return }
            logInfo("SimulatorDevice \"\(device.udid)\" - \(device.name): Connected.")
            let index = simDevices.insertionIndexOf(device) { $0.name < $1.name }
            simDevices.insert(device, at: index)
            refreshPairs()
        }
    }

    @objc private func deviceChanged(_ notification: Notification) {
        guard var device = notification.userInfo?["device"] as? IOSDevice else { return }
        device.preferNetworkConnection = UserDefaults.standard.preferNetworkDevices
        if let index = realDevices.firstIndex(of: device) {
            realDevices[index] = device
            logInfo("Device \"\(device.udid)\" - \(device.name): Updated.")
        }
    }

    @objc private func devicePaired(_ notification: Notification) {
        guard let device = notification.userInfo?["device"] as? Device else { return }
        logInfo("Device \"\(device.udid)\" - \(device.name): Paired.")
    }

    @objc private func deviceDisconnected(_ notification: Notification) {
        if let device = notification.userInfo?["device"] as? IOSDevice {
            if let index = realDevices.firstIndex(of: device) {
                logInfo("Device \"\(device.udid)\" - \(device.name): Disconnected.")
                let removed = realDevices.remove(at: index)
                if (selectedDevice as? IOSDevice) == removed {
                    selectedDevice = nil
                }
            }
        } else if let device = notification.userInfo?["device"] as? SimulatorDevice {
            if let index = simDevices.firstIndex(of: device) {
                logInfo("SimulatorDevice \"\(device.udid)\" - \(device.name): Disconnected.")

                // Check if this was part of the selected pair
                if let pair = selectedPair,
                   device.udid == pair.phone.udid || device.udid == pair.watch.udid {
                    selectedPair = nil
                }

                let removed = simDevices.remove(at: index)
                if (selectedDevice as? SimulatorDevice) == removed {
                    selectedDevice = nil
                }
                refreshPairs()
            }
        }
    }

    // MARK: - Pair Discovery

    /// Refresh simulator pairs from CoreSimulator.
    func refreshPairs() {
        let oldPairs = simulatorPairs
        simulatorPairs = SimulatorPairDiscovery.discoverPairs(knownSimulators: simDevices)
        if oldPairs != simulatorPairs {
            // If the selected pair is no longer valid, deselect
            if let pair = selectedPair, !simulatorPairs.contains(pair) {
                selectedPair = nil
            }
        }
    }

    // MARK: - Selection

    /// Select a solo device. Clears any pair selection.
    func select(device: Device) {
        selectedPair = nil
        selectedDevice = device
    }

    /// Select a simulator pair. Clears any solo device selection.
    func select(pair: SimulatorPair) {
        selectedDevice = nil
        selectedPair = pair
    }

    /// Clear the current selection.
    func clearSelection() {
        selectedDevice = nil
        selectedPair = nil
    }
}
