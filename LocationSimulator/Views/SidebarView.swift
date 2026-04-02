//
//  SidebarView.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI
import LocationSpoofer

/// Native SwiftUI sidebar replacing the AppKit NSOutlineView.
/// Displays iOS devices, simulators, and simulator pairs in sections.
struct SidebarView: View {
    @Environment(DeviceManager.self) private var deviceManager

    var body: some View {
        List(selection: Binding(get: {
            selectedID
        }, set: { newValue in
            handleSelection(newValue)
        })) {
            Section("DEVICE_HEADER".localized) {
                ForEach(deviceManager.realDevices, id: \.udid) { device in
                    DeviceRow(name: device.name, imageName: "wifi")
                        .tag(SidebarItemID.device(device.udid))
                }
            }

            Section("SIMULATOR_HEADER".localized) {
                ForEach(deviceManager.unpairedSimDevices, id: \.udid) { device in
                    let isWatch = device.name.lowercased().contains("watch")
                    DeviceRow(
                        name: device.name,
                        imageName: isWatch ? "applewatch" : "iphone"
                    )
                    .tag(SidebarItemID.device(device.udid))
                }
            }

            if deviceManager.hasPairs {
                Section("SIMULATOR_PAIR_HEADER".localized) {
                    ForEach(deviceManager.simulatorPairs, id: \.name) { pair in
                        DeviceRow(
                            name: "\(pair.phone.name) + \(pair.watch.name)",
                            imageName: "iphone.and.applewatch"
                        )
                        .tag(SidebarItemID.pair(pair.name))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }

    // MARK: - Selection

    private var selectedID: SidebarItemID? {
        if let device = deviceManager.selectedDevice {
            return .device(device.udid)
        }
        if let pair = deviceManager.selectedPair {
            return .pair(pair.name)
        }
        return nil
    }

    private func handleSelection(_ id: SidebarItemID?) {
        guard let id else {
            deviceManager.clearSelection()
            return
        }

        switch id {
        case .device(let udid):
            if let device = deviceManager.realDevices.first(where: { $0.udid == udid }) {
                deviceManager.select(device: device)
            } else if let device = deviceManager.unpairedSimDevices.first(
                where: { $0.udid == udid }
            ) {
                deviceManager.select(device: device)
            }
        case .pair(let name):
            if let pair = deviceManager.simulatorPairs.first(where: { $0.name == name }) {
                deviceManager.select(pair: pair)
            }
        }
    }
}

/// Identifies a sidebar item for List selection binding.
enum SidebarItemID: Hashable {
    case device(String)  // UDID
    case pair(String)    // pair name
}

/// A single row in the sidebar showing a device or pair.
struct DeviceRow: View {
    let name: String
    let imageName: String

    var body: some View {
        Label(name, systemImage: imageName)
    }
}
