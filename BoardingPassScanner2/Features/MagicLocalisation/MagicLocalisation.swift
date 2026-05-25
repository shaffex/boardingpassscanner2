//
//  MagicLocalisation.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 25/05/2026.
//

import MagicUiFramework

struct MagicLocalisation {
    static func exportKeys() {
        
        // Bottom Tabs
        addKey("TEXT_HOME")
        addKey("TEXT_MYPASSES")
        addKey("TEXT_MISC")
        addKey("TEXT_SETTINGS")
        
        
        addKey("TEXT_SCAN_BOARDING_PASS")
        addKey("TEXT_SCAN_BOARDING_DESCRIPTION")
        addKey("TEXT_IMPORT_BOARDING_PASS")
        addKey("TEXT_IMPORT_BOARDING_PASS_DESCRIPTION")
        addKey("TEXT_PASTE_BOARDING_PASS")
        addKey("TEXT_PASTE_BOARDING_PASS_DESCRIPTION")
    }
    
    private static func addKey(_ key: String) {
        SxEnvironmentObject.shared.setValue(String(localized: String.LocalizationValue(key)), forKey: key)
    }
}
