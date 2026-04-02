//
//  MapViewController+MapViewDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import MapKit

let kAnnotationViewCurrentLocationIdentifier = "AnnotationViewCurrentLocationIdentifier"
let kAnnotationViewBookmarkIdentifier = "AnnotationViewBookmarkIdentifier"

/// This delegate is responsible for providing a polyline when navigation is active.
/// Additionally it handles the track gesture of the current location marker and informs observer about the action.
extension MapView: MKMapViewDelegate {

    // MARK: - Navigation overlay

    /// Create the renderer for the navigation overlay.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let navigationOverlay = overlay as? NavigationOverlay {
            if let renderer = self.navigationRenderer {
                return renderer
            }

            let renderer = NavigationRenderer(overlay: navigationOverlay, activeFill: .overlayBlue)
            renderer.inactiveFill = .darkOverlayBlue
            renderer.borderColor = .blue

            self.navigationRenderer = renderer

            return renderer
        }
        // This should never be the case. If apple sometime in the future decides to add some overlays we should
        // provide a default and not crash.
        return MKOverlayRenderer(overlay: overlay)
    }

    // MARK: - Current location marker

    /// Create the view for the current location marker or bookmark annotations.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Current location marker
        if let pointAnnotation = annotation as? MKPointAnnotation, pointAnnotation == self.currentLocationMarker {
            var annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: kAnnotationViewCurrentLocationIdentifier)

            if annotationView == nil {
                annotationView = UserLocationView(annotation: annotation,
                                                  reuseIdentifier: kAnnotationViewCurrentLocationIdentifier)

            }

            annotationView?.annotation = pointAnnotation

            return annotationView
        }

        // Bookmark annotation
        if let bookmarkAnnotation = annotation as? BookmarkAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: kAnnotationViewBookmarkIdentifier
            ) as? MKPinAnnotationView

            if annotationView == nil {
                annotationView = MKPinAnnotationView(
                    annotation: bookmarkAnnotation,
                    reuseIdentifier: kAnnotationViewBookmarkIdentifier
                )
                annotationView?.canShowCallout = true
                annotationView?.pinTintColor = .systemOrange
            } else {
                annotationView?.annotation = bookmarkAnnotation
            }

            return annotationView
        }

        return nil
    }

    /// Handle selection of bookmark annotations to trigger teleport/navigate.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let bookmark = view.annotation as? BookmarkAnnotation {
            mapView.deselectAnnotation(view.annotation, animated: true)
            self.longPressAction?(self.currentLocationMarker?.coordinate, bookmark.coordinate)
        }
    }

    /// Current location marker was dragged.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        if newState == .ending, let annotation = view.annotation {
            self.markerDragAction?(self.currentLocationMarker?.coordinate, annotation.coordinate)
        }
    }

    // MARK: - User interaction
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.isUserMovingTheMap = true
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.isUserMovingTheMap = false
    }
}
