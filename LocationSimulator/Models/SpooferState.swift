//
//  SpooferState.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import Foundation
import CoreLocation
import LocationSpoofer
import Observation

/// Observable model managing the active location spoofer state.
/// Wraps LocationSpoofer and PairedLocationSpoofer lifecycle.
@Observable
class SpooferState {

    /// The active spoofer (primary device, or phone in a pair).
    private(set) var spoofer: LocationSpoofer?

    /// The paired spoofer wrapper (nil for solo devices).
    private(set) var pairedSpoofer: PairedLocationSpoofer?

    /// Current device status.
    var deviceStatus: DeviceStatus = .disconnected

    /// Whether the device is connected and paired.
    var isConnected: Bool = false

    /// Current move type.
    var moveType: MoveType = .walk

    /// Current speed.
    var speed: CLLocationSpeed = MoveType.walk.speed

    // MARK: - Device Setup

    /// Set up a solo device spoofer.
    func setupDevice(_ device: Device) {
        tearDown()
        let newSpoofer = LocationSpoofer(device)
        if UserDefaults.standard.varyMovementSpeed {
            newSpoofer.movementSpeedVariance = kDefaultMovementSpeedVariance
        }
        newSpoofer.moveType = moveType
        newSpoofer.speed = speed
        spoofer = newSpoofer
        pairedSpoofer = nil
        isConnected = false
    }

    /// Set up a paired device spoofer (phone + watch).
    func setupPair(_ pair: SimulatorPair) {
        tearDown()
        let primary = LocationSpoofer(pair.phone)
        let secondary = LocationSpoofer(pair.watch)
        let paired = PairedLocationSpoofer(phonePrimary: primary, watchSecondary: secondary)
        if UserDefaults.standard.varyMovementSpeed {
            primary.movementSpeedVariance = kDefaultMovementSpeedVariance
        }
        primary.moveType = moveType
        primary.speed = speed
        spoofer = primary
        pairedSpoofer = paired
        isConnected = false
    }

    /// Tear down the current spoofer(s).
    func tearDown() {
        pairedSpoofer?.stopAll()
        spoofer?.resetLocation()
        spoofer = nil
        pairedSpoofer = nil
        isConnected = false
        deviceStatus = .disconnected
    }
}
