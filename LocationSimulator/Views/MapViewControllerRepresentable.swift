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
    /// The SwiftUI window's map actions, used by the menu bar when there is no AppKit `WindowController`.
    @ObservationIgnored static weak var current: MapActions?

    var mapViewController: MapViewController?

    /// The selected move type. Changing it also resets the speed to the move type's default.
    var moveType: MoveType = .walk {
        didSet { applyMoveType() }
    }

    func applyMoveType() {
        mapViewController?.moveType = moveType
        mapViewController?.speed = moveType.speed
        NavigationMenubarItem.selectMoveItem(forMoveType: moveType)
    }

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
        /// Queued waypoints for "Simulate Move to Here"
        var waypoints: [CLLocationCoordinate2D] = []
        /// Local monitor for arrow key movement. The SwiftUI app has no storyboard menu, so the arrow key
        /// equivalents from the Navigation menu do not exist.
        var keyMonitor: Any?

        deinit {
            if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        }
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
            let coordinator = context.coordinator
            mapView.simulateMoveAction = { [weak mapVC] destination in
                guard let spoofer = mapVC?.spoofer else { return }

                // Add to waypoint queue (max 20)
                if coordinator.waypoints.count < 20 {
                    coordinator.waypoints.append(destination)
                }

                // Build full route: current location + all queued waypoints
                guard let current = spoofer.currentLocation else { return }
                let fullRoute = [current] + coordinator.waypoints

                spoofer.switchToNavigationState(fullRoute)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    spoofer.startAutoUpdate()
                }
            }

            context.coordinator.mapViewController = mapVC
            mapActions.mapViewController = mapVC
            MapActions.current = mapActions

            coordinator.keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
                [weak mapView, weak mapVC] event in
                guard let mapVC, let window = mapView?.window, event.window == window,
                      // Leave arrow keys alone while typing, e.g. in the search field
                      !(window.firstResponder is NSText),
                      event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty
                else { return event }

                let direction: WindowController.MoveDirection
                switch event.keyCode {
                case 123: direction = .left
                case 124: direction = .right
                case 125: direction = .down
                case 126: direction = .up
                default: return event
                }
                return mapVC.handleArrowKey(direction) ? nil : event
            }
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
                mapActions.applyMoveType()
                mapVC.connectDevice()
            }
        }
        // Handle solo device selection
        else if let device = deviceManager.selectedDevice {
            if coord.currentDeviceUDID != device.udid {
                coord.currentDeviceUDID = device.udid
                coord.currentPairName = nil
                mapVC.device = device
                mapActions.applyMoveType()
                mapVC.connectDevice()
            }
        }
    }
}
