//
//  MainView.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI

/// Root view of the application. Currently wraps the existing AppKit
/// split view controller from the storyboard. This will be progressively
/// replaced with native SwiftUI views in subsequent PRs.
struct MainView: View {
    var body: some View {
        StoryboardWindowRepresentable()
            .ignoresSafeArea()
    }
}

/// Wraps the existing storyboard-based SplitViewController as the main content.
/// This preserves all existing functionality during the SwiftUI migration.
struct StoryboardWindowRepresentable: NSViewControllerRepresentable {

    func makeNSViewController(context: Context) -> SplitViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let splitVC = storyboard.instantiateController(
            withIdentifier: "SplitViewController"
        ) as? SplitViewController else {
            fatalError("Could not instantiate SplitViewController from storyboard")
        }
        return splitVC
    }

    func updateNSViewController(_ nsViewController: SplitViewController, context: Context) {
    }
}
