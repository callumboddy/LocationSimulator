//
//  MapViewControllerRepresentable.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI
import MapKit
import LocationSpoofer

/// Wraps the custom MapView (MKMapView subclass) for SwiftUI.
/// The MapView handles annotations, overlays, gestures, and bookmarks.
struct MapViewRepresentable: NSViewRepresentable {
    @Environment(DeviceManager.self) private var deviceManager
    @Environment(SpooferState.self) private var spooferState

    /// Coordinator holds the MapViewController to manage spoofer lifecycle.
    class Coordinator {
        var mapViewController: MapViewController?
        var currentDeviceUDID: String?
        var currentPairName: String?

        func setupMapVC(mapView: MapView) {
            let mapVC = MapViewController()
            mapVC.mapView = mapView
            self.mapViewController = mapVC
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)
        mapView.mapType = UserDefaults.standard.mapType
        mapView.showsCompass = true
        mapView.showsZoomControls = true
        mapView.showsScale = true
        mapView.reloadBookmarkAnnotations()

        // Listen for bookmark changes
        NotificationCenter.default.addObserver(
            forName: .BookmarksChanged, object: nil, queue: .main
        ) { _ in
            mapView.reloadBookmarkAnnotations()
        }

        return mapView
    }

    func updateNSView(_ mapView: MapView, context: Context) {
        // Device selection changes are handled by the overlays and spoofer state
        // The map itself just needs to exist — spoofer interactions happen through
        // the MapViewController which will be wired up in a future commit
    }
}
