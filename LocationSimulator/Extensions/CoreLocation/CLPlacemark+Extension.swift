//
//  CLPlacemark+Extension.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import CoreLocation

extension CLPlacemark {
    /// A simple formatted address string from the placemark's components.
    var formattedAddress: String? {
        let components = [name, locality, administrativeArea, country]
        let filtered = components.compactMap { $0 }
        return filtered.isEmpty ? nil : filtered.joined(separator: ", ")
    }
}
