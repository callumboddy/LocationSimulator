//
//  BookmarkMenubarItem.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import Foundation
import AppKit
import CoreLocation

let kBookmarkMenuTag: Int = 18

/// Enum to represent the Bookmarks submenu under Navigation.
enum BookmarkMenubarItem: Int, CaseIterable, MenubarItem {
    case separator = -10
    case clearAll = -11

    static public var menu: NSMenu? {
        let navigationMenu = NSApp.menu?.item(withTag: kNavigationMenuTag)?.submenu
        return navigationMenu?.item(withTag: kBookmarkMenuTag)?.submenu
    }

    // MARK: - Setup

    /// Create the Bookmarks submenu and add it to the Navigation menu.
    static func setupMenu() {
        guard let navigationMenu = NSApp.menu?.item(withTag: kNavigationMenuTag)?.submenu else {
            return
        }

        // Create the submenu
        let bookmarksMenu = NSMenu(title: "BOOKMARKS_MENUITEM".localized)

        // Add the separator and Clear All item
        bookmarksMenu.addItem(.separator())
        let clearItem = NSMenuItem(
            title: "CLEAR_BOOKMARKS_MENUITEM".localized,
            action: #selector(MenubarController.clearBookmarks(_:)),
            keyEquivalent: ""
        )
        clearItem.tag = BookmarkMenubarItem.clearAll.rawValue
        bookmarksMenu.addItem(clearItem)

        // Create the parent menu item
        let bookmarksItem = NSMenuItem(
            title: "BOOKMARKS_MENUITEM".localized,
            action: nil,
            keyEquivalent: ""
        )
        bookmarksItem.tag = kBookmarkMenuTag
        bookmarksItem.submenu = bookmarksMenu

        // Insert after Recent Locations (tag 14) in the Navigation menu
        if let recentIndex = navigationMenu.items.firstIndex(
            where: { $0.tag == NavigationMenubarItem.recentLocation.rawValue }
        ) {
            navigationMenu.insertItem(bookmarksItem, at: recentIndex + 1)
        } else {
            navigationMenu.addItem(bookmarksItem)
        }
    }

    // MARK: - Manage bookmark menu items

    /// Rebuild the bookmark menu items from the store.
    static func reloadBookmarks() {
        guard let menu = BookmarkMenubarItem.menu,
              let delegate = NSApp.delegate as? AppDelegate,
              let menubarController = delegate.menubarController else { return }

        // Remove all bookmark entries (keep separator and clear all)
        clearBookmarkMenuItems()

        // Add all bookmarks sorted alphabetically
        let bookmarks = BookmarkStore.shared.allBookmarks
        for (index, bookmark) in bookmarks.enumerated() {
            let insertAt = index * 2

            // Regular click navigates to the bookmark
            let menuItem = NSMenuItem(
                title: bookmark.name,
                action: #selector(menubarController.selectBookmark(_:)),
                keyEquivalent: ""
            )
            menuItem.target = menubarController
            menuItem.tag = index
            menu.insertItem(menuItem, at: insertAt)

            // Option-click alternate: delete the bookmark
            let deleteItem = NSMenuItem(
                title: "DELETE_BOOKMARK_MENUITEM".localized + " \"\(bookmark.name)\"",
                action: #selector(menubarController.deleteBookmark(_:)),
                keyEquivalent: ""
            )
            deleteItem.target = menubarController
            deleteItem.tag = index
            deleteItem.isAlternate = true
            deleteItem.keyEquivalentModifierMask = .option
            menu.insertItem(deleteItem, at: insertAt + 1)
        }

        // Enable/disable Clear All based on whether bookmarks exist
        if bookmarks.isEmpty {
            BookmarkMenubarItem.clearAll.disable()
        } else {
            BookmarkMenubarItem.clearAll.enable()
        }
    }

    /// Remove all bookmark entries from the menu (keeps separator and Clear All).
    static func clearBookmarkMenuItems() {
        guard let menu = BookmarkMenubarItem.menu else { return }
        // Keep only the last 2 items (separator + Clear All)
        while menu.items.count > 2 {
            menu.removeItem(at: 0)
        }
    }
}
