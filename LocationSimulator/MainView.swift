//
//  MainView.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI

/// Root view of the application. Uses NavigationSplitView with a native
/// SwiftUI sidebar and the existing MapViewController as the detail view.
struct MainView: View {
    @Environment(DeviceManager.self) private var deviceManager

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .onAppear {
            deviceManager.startDiscovery()
        }
    }
}

/// Shows the map when a device is selected, or a placeholder otherwise.
struct DetailView: View {
    @Environment(DeviceManager.self) private var deviceManager

    var body: some View {
        if deviceManager.selectedDevice != nil || deviceManager.selectedPair != nil {
            MapViewControllerRepresentable()
                .ignoresSafeArea()
        } else {
            ContentUnavailableView(
                "No Device Selected",
                systemImage: "iphone.slash",
                description: Text("Select a device from the sidebar to begin.")
            )
        }
    }
}
