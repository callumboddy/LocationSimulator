//
//  BookmarkStore.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import Foundation
import CoreLocation

let kBookmarkLocationKey: String = "com.schlaubischlump.locationsimulator.bookmarks"

extension Notification.Name {
    static let BookmarksChanged = Notification.Name("BookmarksChanged")
}

/// Manages persistence of bookmark locations in UserDefaults.
/// Bookmarks are stored as an array of Location objects, sorted alphabetically by name.
class BookmarkStore {

    static let shared = BookmarkStore()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// All bookmarks, sorted alphabetically by name.
    var allBookmarks: [Location] {
        guard let stored = defaults.array(forKey: kBookmarkLocationKey) as? [Data] else {
            return []
        }
        let decoder = PropertyListDecoder()
        return stored
            .compactMap { try? decoder.decode(Location.self, from: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Add a new bookmark.
    func add(name: String, coordinate: CLLocationCoordinate2D) {
        var bookmarks = allBookmarksUnsorted
        bookmarks.append(Location(name: name, lat: coordinate.latitude, long: coordinate.longitude))
        save(bookmarks)
        NotificationCenter.default.post(name: .BookmarksChanged, object: self)
    }

    /// Rename a bookmark at the given index (based on the sorted list).
    func rename(at index: Int, to newName: String) {
        var bookmarks = allBookmarks
        guard index >= 0 && index < bookmarks.count else { return }
        bookmarks[index].name = newName
        save(bookmarks)
        NotificationCenter.default.post(name: .BookmarksChanged, object: self)
    }

    /// Delete a bookmark at the given index (based on the sorted list).
    func delete(at index: Int) {
        var bookmarks = allBookmarks
        guard index >= 0 && index < bookmarks.count else { return }
        bookmarks.remove(at: index)
        save(bookmarks)
        NotificationCenter.default.post(name: .BookmarksChanged, object: self)
    }

    /// Remove all bookmarks.
    func clearAll() {
        save([])
        NotificationCenter.default.post(name: .BookmarksChanged, object: self)
    }

    /// Number of bookmarks.
    var count: Int {
        return allBookmarks.count
    }

    // MARK: - Private

    /// Raw unsorted bookmarks from UserDefaults.
    private var allBookmarksUnsorted: [Location] {
        guard let stored = defaults.array(forKey: kBookmarkLocationKey) as? [Data] else {
            return []
        }
        let decoder = PropertyListDecoder()
        return stored.compactMap { try? decoder.decode(Location.self, from: $0) }
    }

    /// Encode and save bookmarks to UserDefaults.
    private func save(_ bookmarks: [Location]) {
        let encoder = PropertyListEncoder()
        let encoded = bookmarks.compactMap { try? encoder.encode($0) }
        defaults.setValue(encoded, forKey: kBookmarkLocationKey)
    }
}
