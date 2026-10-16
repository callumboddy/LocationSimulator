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

    @State private var deviceManager = DeviceManager()
    @State private var spooferState = SpooferState()

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
        WindowGroup {
            MainView()
                .environment(deviceManager)
                .environment(spooferState)
                .environment(BookmarkStore.shared)
        }
    }
}
