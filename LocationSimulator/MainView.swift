//
//  MainView.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI

/// Root view of the application.
struct MainView: View {
    @Environment(DeviceManager.self) private var deviceManager
    @State private var autofocus: Bool = true

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Autofocus
                Button {
                    autofocus.toggle()
                } label: {
                    Image(systemName: autofocus ? "location.fill" : "location")
                }
                .help("Autofocus current location")

                // Zoom to current location
                Button {
                    // TODO: Wire to zoom to current spoofed location
                } label: {
                    Image(systemName: "scope")
                }
                .help("Zoom to current location")
            }
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
            MapDetailView()
        } else {
            ContentUnavailableView(
                "No Device Selected",
                systemImage: "iphone.slash",
                description: Text("Select a device from the sidebar to begin.")
            )
        }
    }
}

/// The map with SwiftUI overlays.
struct MapDetailView: View {
    // TODO: Wire these to SpooferState once the spoofer is connected
    @State private var isSpinning = false
    @State private var showControls = false
    @State private var isAutoMoving = false
    @State private var totalDistanceKM = 0.0
    @State private var playPauseState = StatusOverlay.PlayPauseState.hidden
    @State private var showError = false

    var body: some View {
        ZStack {
            MapViewRepresentable()
                .ignoresSafeArea()

            SpinnerOverlay(isVisible: isSpinning)

            MovementControlsOverlay(
                isVisible: showControls,
                isHighlighted: isAutoMoving,
                onMove: {
                    // TODO: Wire to spoofer.move()
                },
                onToggleAutoMove: {
                    // TODO: Wire to spoofer toggle auto move
                }
            )

            StatusOverlay(
                totalDistanceKM: totalDistanceKM,
                playPauseState: playPauseState,
                showError: showError,
                onErrorTap: {
                    // TODO: Wire to reconnect
                }
            )
        }
    }
}
