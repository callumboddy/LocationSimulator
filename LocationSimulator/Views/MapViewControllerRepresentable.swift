//
//  MapViewControllerRepresentable.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI
import MapKit
import LocationSpoofer

/// Shared object for toolbar actions to communicate with the map.
@Observable
class MapActions {
    var mapViewController: MapViewController?

    func zoomToCurrentLocation() {
        guard let coord = mapViewController?.spoofer?.currentLocation else { return }
        mapViewController?.mapView?.zoomToLocation(coord, animated: true)
    }
}

/// Wraps the custom MapView and uses MapViewController as a non-visual coordinator
/// to manage spoofer lifecycle, device pairing, and location spoofing.
struct MapViewRepresentable: NSViewRepresentable {
    @Environment(DeviceManager.self) private var deviceManager
    @Environment(SpooferState.self) private var spooferState
    var mapActions: MapActions

    class Coordinator: NSObject {
        var mapViewController: MapViewController?
        var currentDeviceUDID: String?
        var currentPairName: String?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)
        mapView.mapType = UserDefaults.standard.mapType
        mapView.showsZoomControls = false
        mapView.showsCompass = false
        mapView.reloadBookmarkAnnotations()

        // Create a MapViewController from storyboard to use as the controller
        // We only use it for its logic, not its view hierarchy
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let mapVC = storyboard.instantiateController(
            withIdentifier: "MapViewController"
        ) as? MapViewController {
            // Replace the storyboard mapView with ours
            // Force load the VC's view first so IBOutlets are connected
            _ = mapVC.view

            // Now swap in our mapView
            mapVC.mapView = mapView

            // Re-register the map actions on our mapView
            mapView.longPressAction = { [weak mapVC] src, dst in
                mapVC?.requestTeleportOrNavigation(toCoordinate: dst)
            }
            mapView.markerDragAction = { [weak mapVC] src, dst in
                mapVC?.requestTeleportOrNavigation(toCoordinate: dst)
            }
            mapView.bookmarkAction = { [weak mapVC] coordinate in
                mapVC?.showBookmarkDialog(for: coordinate)
            }

            context.coordinator.mapViewController = mapVC
            mapActions.mapViewController = mapVC
        }

        // Listen for bookmark changes
        NotificationCenter.default.addObserver(
            forName: .BookmarksChanged, object: nil, queue: .main
        ) { _ in
            mapView.reloadBookmarkAnnotations()
        }

        return mapView
    }

    func updateNSView(_ mapView: MapView, context: Context) {
        guard let mapVC = context.coordinator.mapViewController else { return }
        let coord = context.coordinator

        // Handle pair selection
        if let pair = deviceManager.selectedPair {
            if coord.currentPairName != pair.name {
                coord.currentPairName = pair.name
                coord.currentDeviceUDID = nil
                mapVC.simulatorPair = pair
                mapVC.connectDevice()
            }
        }
        // Handle solo device selection
        else if let device = deviceManager.selectedDevice {
            if coord.currentDeviceUDID != device.udid {
                coord.currentDeviceUDID = device.udid
                coord.currentPairName = nil
                mapVC.device = device
                mapVC.connectDevice()
            }
        }
    }
}
