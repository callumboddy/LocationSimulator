//
//  MainView.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI
import LocationSpoofer

/// Root view of the application.
struct MainView: View {
    @Environment(DeviceManager.self) private var deviceManager
    @State private var autofocus: Bool = true
    @State private var mapActions = MapActions()

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView(mapActions: mapActions)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                @Bindable var mapActions = mapActions
                Picker("Speed", selection: $mapActions.moveType) {
                    Image(systemName: "figure.walk").tag(MoveType.walk)
                        .help("Walk (5 km/h)")
                    Image(systemName: "bicycle").tag(MoveType.cycle)
                        .help("Cycle (15 km/h)")
                    Image(systemName: "car.fill").tag(MoveType.drive)
                        .help("Drive (40 km/h)")
                }
                .pickerStyle(.segmented)
                .help("Movement speed")
            }

            ToolbarItemGroup(placement: .automatic) {
                // Zoom out
                Button {
                    mapActions.mapViewController?.mapView?.zoomMapOut()
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .help("Zoom out")

                // Zoom in
                Button {
                    mapActions.mapViewController?.mapView?.zoomMapIn()
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .help("Zoom in")

                // Autofocus
                Button {
                    autofocus.toggle()
                    mapActions.mapViewController?.autofocusCurrentLocation = autofocus
                } label: {
                    Image(systemName: autofocus ? "location.fill" : "location")
                }
                .help("Autofocus current location")

                // Zoom to current location
                Button {
                    mapActions.zoomToCurrentLocation()
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
    var mapActions: MapActions

    var body: some View {
        if deviceManager.selectedDevice != nil || deviceManager.selectedPair != nil {
            MapDetailView(mapActions: mapActions)
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
    var mapActions: MapActions

    @State private var isSpinning = false
    @State private var showControls = false
    @State private var isAutoMoving = false
    @State private var totalDistanceKM = 0.0
    @State private var playPauseState = StatusOverlay.PlayPauseState.hidden
    @State private var showError = false

    var body: some View {
        ZStack {
            MapViewRepresentable(mapActions: mapActions)
                .ignoresSafeArea()

            SpinnerOverlay(isVisible: isSpinning)

            MovementControlsOverlay(
                isVisible: showControls,
                isHighlighted: isAutoMoving,
                onMove: {},
                onToggleAutoMove: {}
            )

            StatusOverlay(
                totalDistanceKM: totalDistanceKM,
                playPauseState: playPauseState,
                showError: showError,
                onErrorTap: {}
            )
        }
    }
}
