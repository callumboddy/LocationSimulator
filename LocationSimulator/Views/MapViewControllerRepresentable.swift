//
//  MapViewControllerRepresentable.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI
import MapKit
import LocationSpoofer

/// Temporary simple map view while MapViewController migration is in progress.
/// TODO: Replace with full MapViewController once storyboard dependency is removed.
struct MapViewControllerRepresentable: NSViewRepresentable {
    @Environment(DeviceManager.self) private var deviceManager

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MapView()
        mapView.mapType = UserDefaults.standard.mapType
        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
    }
}
