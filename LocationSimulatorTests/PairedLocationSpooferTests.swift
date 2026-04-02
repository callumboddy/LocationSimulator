//
//  PairedLocationSpooferTests.swift
//  LocationSimulatorTests
//
//  Created by Callum Boddy on 02.04.26.
//

import Testing
import Foundation
import CoreLocation
@testable import LocationSimulator
@testable import LocationSpoofer

// MARK: - Mock Device

/// A mock Device that records calls and can be configured to succeed or fail.
class MockDevice: Device {
    let udid: String
    let name: String
    var version: String? = "17.0"
    var productName: String? = "iPhone OS"
    var connectionType: ConnectionType = .unknown

    var simulateLocationShouldSucceed = true
    var simulateLocationCallCount = 0
    var lastSimulatedLocation: CLLocationCoordinate2D?

    var disableSimulationCallCount = 0

    init(udid: String = "mock-udid", name: String = "Mock Device") {
        self.udid = udid
        self.name = name
    }

    static var availableDevices: [Device] = []
    static var isGeneratingDeviceNotifications: Bool = false
    static func startGeneratingDeviceNotifications() -> Bool { return true }
    static func stopGeneratingDeviceNotifications() -> Bool { return true }

    func simulateLocation(_ location: CLLocationCoordinate2D) -> Bool {
        simulateLocationCallCount += 1
        lastSimulatedLocation = location
        return simulateLocationShouldSucceed
    }

    func disableSimulation() -> Bool {
        disableSimulationCallCount += 1
        return true
    }
}

// MARK: - Mock Delegate

/// Records delegate calls from PairedLocationSpoofer to verify forwarding.
class MockSpooferDelegate: LocationSpooferDelegate {
    var willChangeLocationCalls: [(CLLocationCoordinate2D?)] = []
    var didChangeLocationCalls: [(CLLocationCoordinate2D?)] = []
    var errorChangingLocationCalls: [(CLLocationCoordinate2D?)] = []
    var didChangeMoveStateCalls: [MoveState] = []
    var didChangeAutoUpdateCalls: [Bool] = []

    func willChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        willChangeLocationCalls.append(toCoordinate)
    }

    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        didChangeLocationCalls.append(toCoordinate)
    }

    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        errorChangingLocationCalls.append(toCoordinate)
    }

    func didChangeMoveState(spoofer: LocationSpoofer, fromMoveState: MoveState) {
        didChangeMoveStateCalls.append(fromMoveState)
    }

    func didChangeAutoUpdate(spoofer: LocationSpoofer, fromValue: Bool) {
        didChangeAutoUpdateCalls.append(fromValue)
    }
}

// MARK: - Tests

struct PairedLocationSpooferTests {

    private func makePair() -> (paired: PairedLocationSpoofer, phoneMock: MockDevice, watchMock: MockDevice, delegate: MockSpooferDelegate) {
        let phoneMock = MockDevice(udid: "phone-udid", name: "iPhone")
        let watchMock = MockDevice(udid: "watch-udid", name: "Apple Watch")
        let primary = LocationSpoofer(phoneMock)
        let secondary = LocationSpoofer(watchMock)
        let paired = PairedLocationSpoofer(phonePrimary: primary, watchSecondary: secondary)
        let mockDelegate = MockSpooferDelegate()
        paired.delegate = mockDelegate
        return (paired, phoneMock, watchMock, mockDelegate)
    }

    // MARK: - Delegate forwarding

    @Test func forwardsWillChangeLocationToDelegate() {
        let (paired, _, _, delegate) = makePair()
        let coord = CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0)

        paired.willChangeLocation(spoofer: paired.primary, toCoordinate: coord)

        #expect(delegate.willChangeLocationCalls.count == 1)
    }

    @Test func forwardsDidChangeLocationToDelegate() {
        let (paired, _, _, delegate) = makePair()
        let coord = CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0)

        paired.didChangeLocation(spoofer: paired.primary, toCoordinate: coord)

        #expect(delegate.didChangeLocationCalls.count == 1)
    }

    @Test func forwardsErrorChangingLocationToDelegate() {
        let (paired, _, _, delegate) = makePair()
        let coord = CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0)

        paired.errorChangingLocation(spoofer: paired.primary, toCoordinate: coord)

        #expect(delegate.errorChangingLocationCalls.count == 1)
    }

    @Test func forwardsDidChangeMoveStateToDelegate() {
        let (paired, _, _, delegate) = makePair()

        paired.didChangeMoveState(spoofer: paired.primary, fromMoveState: .manual)

        #expect(delegate.didChangeMoveStateCalls.count == 1)
    }

    @Test func forwardsDidChangeAutoUpdateToDelegate() {
        let (paired, _, _, delegate) = makePair()

        paired.didChangeAutoUpdate(spoofer: paired.primary, fromValue: false)

        #expect(delegate.didChangeAutoUpdateCalls.count == 1)
    }

    // MARK: - Secondary sync

    @Test func syncsLocationToSecondaryOnDidChangeLocation() async {
        let (paired, _, watchMock, _) = makePair()
        let coord = CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0)

        paired.didChangeLocation(spoofer: paired.primary, toCoordinate: coord)

        // LocationSpoofer dispatches to a background queue — wait for it
        try? await Task.sleep(nanoseconds: 200_000_000)

        #expect(watchMock.simulateLocationCallCount == 1)
    }

    @Test func resetsSecondaryOnLocationReset() async {
        let (paired, _, watchMock, _) = makePair()

        paired.didChangeLocation(spoofer: paired.primary, toCoordinate: nil)

        // resetLocation dispatches async
        try? await Task.sleep(nanoseconds: 200_000_000)

        #expect(watchMock.disableSimulationCallCount == 1)
    }

    // MARK: - Secondary error state

    @Test func secondaryHasErrorInitiallyFalse() {
        let (paired, _, _, _) = makePair()

        #expect(paired.secondaryHasError == false)
    }

    @Test func secondaryDidFailSetsErrorState() {
        let (paired, _, _, _) = makePair()

        paired.secondaryDidFail(toCoordinate: nil)

        #expect(paired.secondaryHasError == true)
    }

    @Test func secondaryDidFailPostsNotification() {
        let (paired, _, _, _) = makePair()
        var notificationReceived = false

        let observer = NotificationCenter.default.addObserver(
            forName: .SecondarySpooferError, object: paired, queue: .main
        ) { _ in notificationReceived = true }

        paired.secondaryDidFail(toCoordinate: nil)

        NotificationCenter.default.removeObserver(observer)
        #expect(notificationReceived == true)
    }

    @Test func secondaryRecoveryResetsErrorState() {
        let (paired, _, _, _) = makePair()

        paired.secondaryDidFail(toCoordinate: nil)
        #expect(paired.secondaryHasError == true)

        paired.secondaryDidChangeLocation(CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0))
        #expect(paired.secondaryHasError == false)
    }

    @Test func secondaryRecoveryPostsNotification() {
        let (paired, _, _, _) = makePair()
        var notificationReceived = false

        paired.secondaryDidFail(toCoordinate: nil)

        let observer = NotificationCenter.default.addObserver(
            forName: .SecondarySpooferRecovered, object: paired, queue: .main
        ) { _ in notificationReceived = true }

        paired.secondaryDidChangeLocation(CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0))

        NotificationCenter.default.removeObserver(observer)
        #expect(notificationReceived == true)
    }

    @Test func secondaryDidFailDoesNotPostDuplicateNotifications() {
        let (paired, _, _, _) = makePair()
        var notificationCount = 0

        let observer = NotificationCenter.default.addObserver(
            forName: .SecondarySpooferError, object: paired, queue: .main
        ) { _ in notificationCount += 1 }

        paired.secondaryDidFail(toCoordinate: nil)
        paired.secondaryDidFail(toCoordinate: nil)

        NotificationCenter.default.removeObserver(observer)
        #expect(notificationCount == 1)
    }

    // MARK: - StopAll

    @Test func stopAllResetsAndStopsBothDevices() async {
        let (paired, phoneMock, watchMock, _) = makePair()

        paired.stopAll()

        // resetLocation dispatches async on both spoofers
        try? await Task.sleep(nanoseconds: 500_000_000)

        #expect(phoneMock.disableSimulationCallCount >= 1)
        #expect(watchMock.disableSimulationCallCount >= 1)
    }
}
