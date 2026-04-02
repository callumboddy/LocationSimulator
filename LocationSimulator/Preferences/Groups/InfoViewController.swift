//
//  ChangeLogViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

let kLastAppVersion: String = "com.schlaubischlump.locationsimulator.lastappversion"
let kFirstLaunch: String = "com.schlaubischlump.locationsimulator.firstlaunch"

// Extend the UserDefaults with all keys relevant for this tab.
extension UserDefaults {
    @objc dynamic var firstLaunch: Bool {
        get { return self.bool(forKey: kFirstLaunch) }
        set { self.setValue(newValue, forKey: kFirstLaunch) }
    }

    @objc dynamic var lastAppVersion: String? {
        get { return self.string(forKey: kLastAppVersion) }
        set { self.setValue(newValue, forKey: kLastAppVersion) }
    }

    /// Register the default NSUserDefault values.
    func registerInfoDefaultValues() {
        // Nothing to do here yet, since nil is a valid lastAppVersion value
        UserDefaults.standard.register(defaults: [
            kFirstLaunch: true
        ])
    }
}

class InfoViewController: PreferenceViewControllerBase {
    override func loadView() {
        let padX = 15.0
        let padY = 10.0

        let infoField = NSTextField(frame: .zero)
        infoField.isEditable = false
        infoField.isEnabled = false
        infoField.drawsBackground = false
        infoField.textColor = .secondaryLabelColor
        infoField.font = .labelFont(ofSize: NSFont.systemFontSize)
        infoField.alignment = .center
        infoField.isBezeled = false
        infoField.preferredMaxLayoutWidth = kMaxPreferenceViewWidth - padX * 2
        infoField.stringValue = "WELCOME_TEXT".localized
        infoField.frame.size = infoField.fittingSize
        infoField.frame.origin.x = padX
        infoField.frame.origin.y = padY

        let container = NSView()
        container.addSubview(infoField)
        container.frame.size.width = infoField.frame.width + padX * 2
        container.frame.size.height = infoField.frame.maxY + padY * 2

        self.view = container
    }
}
