//
//  BookmarkAnnotation.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import MapKit

/// A map annotation representing a saved bookmark location.
class BookmarkAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D, name: String) {
        self.coordinate = coordinate
        self.title = name
        self.subtitle = String(
            format: "%.4f, %.4f",
            coordinate.latitude,
            coordinate.longitude
        )
    }
}
