//
//  BookmarkStoreTests.swift
//  LocationSimulatorTests
//
//  Created by Callum Boddy on 02.04.26.
//

import Testing
import Foundation
import CoreLocation
@testable import LocationSimulator

struct BookmarkStoreTests {

    private func makeStore() -> BookmarkStore {
        let suite = UserDefaults(suiteName: "BookmarkStoreTests.\(UUID().uuidString)")!
        return BookmarkStore(defaults: suite)
    }

    // MARK: - Add

    @Test func startsEmpty() {
        let store = makeStore()
        #expect(store.allBookmarks.isEmpty)
        #expect(store.count == 0)
    }

    @Test func addBookmark() {
        let store = makeStore()
        store.add(name: "Office", coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1))

        #expect(store.count == 1)
        #expect(store.allBookmarks.first?.name == "Office")
        #expect(store.allBookmarks.first?.lat == 51.5)
        #expect(store.allBookmarks.first?.long == -0.1)
    }

    @Test func addMultipleBookmarks() {
        let store = makeStore()
        store.add(name: "Office", coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1))
        store.add(name: "Home", coordinate: CLLocationCoordinate2D(latitude: 52.0, longitude: -1.0))

        #expect(store.count == 2)
    }

    // MARK: - Alphabetical ordering

    @Test func bookmarksAreSortedAlphabetically() {
        let store = makeStore()
        store.add(name: "Zoo", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))
        store.add(name: "Airport", coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2))
        store.add(name: "Museum", coordinate: CLLocationCoordinate2D(latitude: 3, longitude: 3))

        let names = store.allBookmarks.map(\.name)
        #expect(names == ["Airport", "Museum", "Zoo"])
    }

    @Test func sortingIsCaseInsensitive() {
        let store = makeStore()
        store.add(name: "beta", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))
        store.add(name: "Alpha", coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2))

        let names = store.allBookmarks.map(\.name)
        #expect(names == ["Alpha", "beta"])
    }

    // MARK: - Rename

    @Test func renameBookmark() {
        let store = makeStore()
        store.add(name: "Old Name", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))

        store.rename(at: 0, to: "New Name")

        #expect(store.allBookmarks.first?.name == "New Name")
    }

    @Test func renameOutOfBoundsDoesNothing() {
        let store = makeStore()
        store.add(name: "Test", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))

        store.rename(at: 5, to: "Crash?")

        #expect(store.count == 1)
        #expect(store.allBookmarks.first?.name == "Test")
    }

    // MARK: - Delete

    @Test func deleteBookmark() {
        let store = makeStore()
        store.add(name: "Keep", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))
        store.add(name: "Remove", coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2))

        // Sorted: Keep, Remove — delete index 1
        store.delete(at: 1)

        #expect(store.count == 1)
        #expect(store.allBookmarks.first?.name == "Keep")
    }

    @Test func deleteOutOfBoundsDoesNothing() {
        let store = makeStore()
        store.add(name: "Test", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))

        store.delete(at: 5)

        #expect(store.count == 1)
    }

    // MARK: - Clear all

    @Test func clearAll() {
        let store = makeStore()
        store.add(name: "A", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))
        store.add(name: "B", coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2))

        store.clearAll()

        #expect(store.allBookmarks.isEmpty)
        #expect(store.count == 0)
    }

    // MARK: - Notifications

    @Test func addPostsNotification() {
        let store = makeStore()
        var received = false

        let observer = NotificationCenter.default.addObserver(
            forName: .BookmarksChanged, object: store, queue: .main
        ) { _ in received = true }

        store.add(name: "Test", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))

        NotificationCenter.default.removeObserver(observer)
        #expect(received == true)
    }

    @Test func deletePostsNotification() {
        let store = makeStore()
        store.add(name: "Test", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))

        var received = false
        let observer = NotificationCenter.default.addObserver(
            forName: .BookmarksChanged, object: store, queue: .main
        ) { _ in received = true }

        store.delete(at: 0)

        NotificationCenter.default.removeObserver(observer)
        #expect(received == true)
    }

    @Test func clearAllPostsNotification() {
        let store = makeStore()
        var received = false

        let observer = NotificationCenter.default.addObserver(
            forName: .BookmarksChanged, object: store, queue: .main
        ) { _ in received = true }

        store.clearAll()

        NotificationCenter.default.removeObserver(observer)
        #expect(received == true)
    }

    // MARK: - Persistence

    @Test func bookmarksPersistAcrossInstances() {
        let suiteName = "BookmarkStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = BookmarkStore(defaults: defaults)
        store1.add(name: "Persisted", coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0))

        let store2 = BookmarkStore(defaults: defaults)
        #expect(store2.count == 1)
        #expect(store2.allBookmarks.first?.name == "Persisted")
    }
}
