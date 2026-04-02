//
//  SidebarDataSource+DeviceNotifications.swift
//  LocationSimulator
//
//  Created by David Klopp on 23.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import CLogger
import LocationSpoofer

extension SidebarDataSource {

    /// Register all notification handler.
    public func registerDeviceNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceConnected),
                                               name: .DeviceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceChanged),
                                               name: .DeviceChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.devicePaired),
                                               name: .DevicePaired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDisconnected),
                                               name: .DeviceDisconnected, object: nil)
    }

    /// Callback when a device gets connected.
    /// - Parameter notification: notification with device information (UDID and name)
    @objc func deviceConnected(_ notification: Notification) {
        if var device: IOSDevice = notification.userInfo?["device"] as? IOSDevice {
            // This should never be the case, but let's make sure that a device is unique.
            if self.realDevices.contains(device) { return }
            logInfo("Device \"\(device.udid)\" - \(device.name): Connected.")
            // The internal `preferNetworkConnection` might not be updated for the cached device
            device.preferNetworkConnection = UserDefaults.standard.preferNetworkDevices
            // Insert the device alphabetically at the correct index.
            let index = self.realDevices.insertionIndexOf(device) { $0.name < $1.name }
            // Add the new device to the internal list and update the UI
            self.realDevices.insert(device, at: index)
            // Reload to recalculate all row indices
            self.sidebarView?.reloadData()
        } else if let device: SimulatorDevice = notification.userInfo?["device"] as? SimulatorDevice {
            // This should never be the case, but let's make sure that a device is unique.
            if self.simDevices.contains(device) { return }
            logInfo("SimulatorDevice \"\(device.udid)\" - \(device.name): Connected.")
            // Insert the device alphabetically at the correct index.
            let index = self.simDevices.insertionIndexOf(device) { $0.name < $1.name }
            // Add the new device to the internal list and update the UI
            self.simDevices.insert(device, at: index)
            // Refresh pairs since a newly booted sim might complete a pair
            self.refreshPairs()
            // Reload to recalculate all row indices
            self.sidebarView?.reloadData()
        }
    }

    /// Callback when a device gets paired for the first time with this computer.
    /// - Parameter notification: notification with device information (UDID and name)
    @objc func devicePaired(_ notification: Notification) {
        guard let device: Device = notification.userInfo?["device"] as? Device else { return }
        logInfo("Device \"\(device.udid)\" - \(device.name): Paired.")

        // Reupload the Developerdiskimage by reapplying the selection if the unpaired device is already selected.
        guard device.udid == self.selectedDevice?.udid else { return }
        NotificationCenter.default.post(name: NSOutlineView.selectionDidChangeNotification, object: self.sidebarView)
    }

    /// Callback when a device changes. This might happen if a network device is additionally connected over USB.
    /// - Parameter notification: notification with device information (UDID and name)
    @objc func deviceChanged(_ notification: Notification) {
        guard var device: IOSDevice = notification.userInfo?["device"] as? IOSDevice else { return }

        // the internal `preferNetworkConnection` might not be updated for the cached device
        device.preferNetworkConnection = UserDefaults.standard.preferNetworkDevices

        // Device is a struct. We therefore need to update the existing struct to write the changes.
        if let index: Int = self.realDevices.firstIndex(of: device) {
            self.realDevices[index] = device

            logInfo("Device \"\(device.udid)\" - \(device.name): Updated.")

            // Update the image and the text. index+1 for the HeaderCell
            self.updateCell(atIndex: index+1)
        }
    }

    /// Callback when a device gets disconnected.
    /// - Parameter notification: notification with device information (UDID)
    @objc func deviceDisconnected(_ notification: Notification) {
        if let device: IOSDevice = notification.userInfo?["device"] as? IOSDevice {
            // remove the device from the list and the list popup
            if let index: Int = self.realDevices.firstIndex(of: device) {
                logInfo("Device \"\(device.udid)\" - \(device.name): Disconnected.")

                // True if the currently selected device was removed.
                let removeCurrent = (self.selectedDevice as? IOSDevice == self.realDevices.remove(at: index))

                // If the current device was removed, we need to change the status to disconnect.
                if removeCurrent {
                    let windowController = self.sidebarView?.window?.windowController as? WindowController
                    windowController?.mapViewController?.device = nil
                }

                self.sidebarView?.reloadData()
            }
        } else if let device: SimulatorDevice = notification.userInfo?["device"] as? SimulatorDevice {
            if let index: Int = self.simDevices.firstIndex(of: device) {
                logInfo("SimulatorDevice \"\(device.udid)\" - \(device.name): Disconnected.")

                // Check if this device was part of the selected pair
                if let selectedPair = self.selectedPair,
                   device.udid == selectedPair.phone.udid || device.udid == selectedPair.watch.udid {
                    let windowController = self.sidebarView?.window?.windowController as? WindowController
                    windowController?.mapViewController?.device = nil
                }

                // True if the currently selected device was removed.
                let removeCurrent = (self.selectedDevice as? SimulatorDevice == self.simDevices.remove(at: index))

                // If the current device was removed, we need to change the status to disconnect.
                if removeCurrent {
                    let windowController = self.sidebarView?.window?.windowController as? WindowController
                    windowController?.mapViewController?.device = nil
                }

                // Refresh pairs since a disconnected sim may break a pair
                self.refreshPairs()
                self.sidebarView?.reloadData()
            }
        }
    }
}
