//
//  SimulatorPairDiscoveryTests.swift
//  LocationSimulatorTests
//
//  Created by Callum Boddy on 02.04.26.
//

import Testing
import Foundation
@testable import LocationSimulator

struct SimulatorPairDiscoveryTests {

    // MARK: - Sample JSON fixtures

    private static let validPairsJSON = """
    {
      "pairs": {
        "C97EC171-D31A-4D7B-B26F-3F30F44C47BF": {
          "watch": {
            "name": "Apple Watch Series 11 (42mm)",
            "udid": "E25E6CEF-C834-4693-9426-E68FC7D4C9F9",
            "state": "Booted"
          },
          "phone": {
            "name": "iPhone Air",
            "udid": "F8931DF0-C3BD-4D78-B6C6-00029B320317",
            "state": "Booted"
          },
          "state": "(active, connected)"
        },
        "12572D28-9D64-4E4E-B6FA-58F719F35E5F": {
          "watch": {
            "name": "Apple Watch Ultra 3 (49mm)",
            "udid": "8B32C5E1-CE63-4678-8BA2-8C259E17286F",
            "state": "Shutdown"
          },
          "phone": {
            "name": "iPhone 17",
            "udid": "6CB56E63-DEBC-40D5-9B33-46B52C9969E1",
            "state": "Shutdown"
          },
          "state": "(active, disconnected)"
        }
      }
    }
    """.data(using: .utf8)!

    private static let allShutdownJSON = """
    {
      "pairs": {
        "12572D28-9D64-4E4E-B6FA-58F719F35E5F": {
          "watch": {
            "name": "Apple Watch Ultra 3 (49mm)",
            "udid": "8B32C5E1-CE63-4678-8BA2-8C259E17286F",
            "state": "Shutdown"
          },
          "phone": {
            "name": "iPhone 17",
            "udid": "6CB56E63-DEBC-40D5-9B33-46B52C9969E1",
            "state": "Shutdown"
          },
          "state": "(active, disconnected)"
        }
      }
    }
    """.data(using: .utf8)!

    private static let noPairsJSON = """
    {
      "pairs": {}
    }
    """.data(using: .utf8)!

    private static let watchOnlyBootedJSON = """
    {
      "pairs": {
        "C97EC171-D31A-4D7B-B26F-3F30F44C47BF": {
          "watch": {
            "name": "Apple Watch Series 11 (42mm)",
            "udid": "E25E6CEF-C834-4693-9426-E68FC7D4C9F9",
            "state": "Booted"
          },
          "phone": {
            "name": "iPhone Air",
            "udid": "F8931DF0-C3BD-4D78-B6C6-00029B320317",
            "state": "Shutdown"
          },
          "state": "(active, disconnected)"
        }
      }
    }
    """.data(using: .utf8)!

    private static let multipleBothBootedJSON = """
    {
      "pairs": {
        "AAA": {
          "watch": { "name": "Watch A", "udid": "W1", "state": "Booted" },
          "phone": { "name": "Phone A", "udid": "P1", "state": "Booted" },
          "state": "(active, connected)"
        },
        "BBB": {
          "watch": { "name": "Watch B", "udid": "W2", "state": "Booted" },
          "phone": { "name": "Phone B", "udid": "P2", "state": "Booted" },
          "state": "(active, connected)"
        }
      }
    }
    """.data(using: .utf8)!

    private static let malformedJSON = "{ not valid json".data(using: .utf8)!

    // MARK: - Tests

    @Test func parsesBootedPairCorrectly() {
        let pairs = SimulatorPairDiscovery.parseBootedPairInfos(from: Self.validPairsJSON)

        #expect(pairs.count == 1)
        #expect(pairs.first?.phoneUDID == "F8931DF0-C3BD-4D78-B6C6-00029B320317")
        #expect(pairs.first?.phoneName == "iPhone Air")
        #expect(pairs.first?.watchUDID == "E25E6CEF-C834-4693-9426-E68FC7D4C9F9")
        #expect(pairs.first?.watchName == "Apple Watch Series 11 (42mm)")
    }

    @Test func filtersOutShutdownPairs() {
        let pairs = SimulatorPairDiscovery.parseBootedPairInfos(from: Self.allShutdownJSON)

        #expect(pairs.isEmpty)
    }

    @Test func returnsEmptyForNoPairs() {
        let pairs = SimulatorPairDiscovery.parseBootedPairInfos(from: Self.noPairsJSON)

        #expect(pairs.isEmpty)
    }

    @Test func filtersOutWhenOnlyOneDeviceBooted() {
        let pairs = SimulatorPairDiscovery.parseBootedPairInfos(from: Self.watchOnlyBootedJSON)

        #expect(pairs.isEmpty)
    }

    @Test func returnsEmptyForMalformedJSON() {
        let pairs = SimulatorPairDiscovery.parseBootedPairInfos(from: Self.malformedJSON)

        #expect(pairs.isEmpty)
    }

    @Test func parsesMultipleBootedPairs() {
        let pairs = SimulatorPairDiscovery.parseBootedPairInfos(from: Self.multipleBothBootedJSON)

        #expect(pairs.count == 2)
        let udids = Set(pairs.map(\.phoneUDID))
        #expect(udids.contains("P1"))
        #expect(udids.contains("P2"))
    }
}
