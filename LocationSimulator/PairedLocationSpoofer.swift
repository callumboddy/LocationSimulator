//
//  PairedLocationSpoofer.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import Foundation
import CoreLocation
import LocationSpoofer
import CLogger

/// Notification posted when the secondary (Watch) spoofer encounters an error.
extension Notification.Name {
    static let SecondarySpooferError = Notification.Name("SecondarySpooferError")
    static let SecondarySpooferRecovered = Notification.Name("SecondarySpooferRecovered")
}

/// Wraps two LocationSpoofer instances (Phone primary, Watch secondary) and keeps them in sync.
/// The primary spoofer drives all interactions; the secondary mirrors location updates.
/// Conforms to LocationSpooferDelegate to intercept primary spoofer callbacks and forward
/// locations to the secondary before passing events up to the real delegate.
class PairedLocationSpoofer: NSObject, LocationSpooferDelegate {

    /// The primary (Phone) spoofer — all map interactions drive this one.
    let primary: LocationSpoofer

    /// The secondary (Watch) spoofer — mirrors the primary's location.
    let secondary: LocationSpoofer

    /// The upstream delegate (MapViewController) that receives callbacks from the primary.
    weak var delegate: LocationSpooferDelegate?

    /// Whether the secondary spoofer is currently in an error state.
    private(set) var secondaryHasError: Bool = false

    /// Handles delegate callbacks from the secondary spoofer to detect errors.
    private var secondaryDelegate: SecondarySpooferDelegate?

    init(phonePrimary: LocationSpoofer, watchSecondary: LocationSpoofer) {
        self.primary = phonePrimary
        self.secondary = watchSecondary
        super.init()

        // We intercept the primary's delegate callbacks to sync the secondary.
        self.primary.delegate = self

        // Set up a delegate on the secondary to catch its errors.
        self.secondaryDelegate = SecondarySpooferDelegate(owner: self)
        self.secondary.delegate = self.secondaryDelegate
    }

    // MARK: - LocationSpooferDelegate (intercepting primary callbacks)

    func willChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        delegate?.willChangeLocation(spoofer: spoofer, toCoordinate: toCoordinate)
    }

    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // Mirror the location change to the secondary
        if let coord = toCoordinate {
            syncSecondaryLocation(coord)
        } else {
            // Location was reset — reset the secondary too
            secondary.resetLocation()
        }

        // Forward to upstream delegate
        delegate?.didChangeLocation(spoofer: spoofer, toCoordinate: toCoordinate)
    }

    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // Primary failed — forward the error upstream
        delegate?.errorChangingLocation(spoofer: spoofer, toCoordinate: toCoordinate)
    }

    func didChangeMoveState(spoofer: LocationSpoofer, fromMoveState: MoveState) {
        delegate?.didChangeMoveState(spoofer: spoofer, fromMoveState: fromMoveState)
    }

    func didChangeAutoUpdate(spoofer: LocationSpoofer, fromValue: Bool) {
        delegate?.didChangeAutoUpdate(spoofer: spoofer, fromValue: fromValue)
    }

    // MARK: - Secondary sync

    /// Push the current location to the secondary spoofer.
    private func syncSecondaryLocation(_ coordinate: CLLocationCoordinate2D) {
        secondary.setLocation(coordinate)
    }

    /// Called by SecondarySpooferDelegate when the Watch location was set successfully.
    func secondaryDidChangeLocation(_ coordinate: CLLocationCoordinate2D?) {
        if secondaryHasError {
            logInfo("PairedLocationSpoofer: Secondary (Watch) spoofer recovered.")
            secondaryHasError = false
            NotificationCenter.default.post(name: .SecondarySpooferRecovered, object: self)
        }
    }

    /// Called by SecondarySpooferDelegate when the Watch spoofer fails.
    func secondaryDidFail(toCoordinate: CLLocationCoordinate2D?) {
        if !secondaryHasError {
            logError("PairedLocationSpoofer: Secondary (Watch) spoofer failed to update location.")
            secondaryHasError = true
            NotificationCenter.default.post(name: .SecondarySpooferError, object: self)
        }
    }

    /// Stop both spoofers and clean up.
    func stopAll() {
        primary.stopAutoUpdate()
        primary.resetLocation()
        secondary.stopAutoUpdate()
        secondary.resetLocation()
    }
}

// MARK: - SecondarySpooferDelegate

/// Lightweight delegate that catches callbacks from the secondary (Watch) spoofer
/// and reports errors/recovery back to the PairedLocationSpoofer.
/// Ignores all other callbacks — the secondary is entirely driven by the primary.
private class SecondarySpooferDelegate: NSObject, LocationSpooferDelegate {

    weak var owner: PairedLocationSpoofer?

    init(owner: PairedLocationSpoofer) {
        self.owner = owner
    }

    func willChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // No-op — secondary is passively mirroring
    }

    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        owner?.secondaryDidChangeLocation(toCoordinate)
    }

    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // Secondary failed — non-blocking, primary keeps going
        owner?.secondaryDidFail(toCoordinate: toCoordinate)
    }

    func didChangeMoveState(spoofer: LocationSpoofer, fromMoveState: MoveState) {
        // No-op
    }

    func didChangeAutoUpdate(spoofer: LocationSpoofer, fromValue: Bool) {
        // No-op
    }
}
