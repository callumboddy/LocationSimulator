//
//  LocationSimulatorApp.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI
import CLogger
import LocationSpoofer

@main
struct LocationSimulatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Init the logger before we start the application.
        FileManager.default.initLogger()

        // Register all the default setting values for this application.
        let defaults = UserDefaults.standard
        defaults.registerInfoDefaultValues()
        defaults.registerGeneralDefaultValues()
        defaults.registerNetworkDefaultValues()
        defaults.registerMapTypeDefaultValue()
        defaults.registerRecentLocationDefaultValues()
        defaults.registerDeveloperDiskImagesDefaultValues()
    }

    var body: some Scene {
        // The main window is still created by the storyboard via NSMainStoryboardFile.
        // This Settings scene is a placeholder — the storyboard preferences will be
        // migrated to SwiftUI in PR7. For now, the existing preferences work via the
        // storyboard menu bar action.
        Settings {
            EmptyView()
        }
    }
}
