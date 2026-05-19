//
//  EventAddNewBarcode.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 17/05/2026.
//

import MagicUiFramework

struct EventAddNewBarcode {
    static func fireNewBarcodeEvent(barcodeText: String, barcodeType: String) {
        SxMagicVariables.shared.setValue(barcodeText, forKey: "barcodeObject.text")
        SxMagicVariables.shared.setValue(barcodeType, forKey: "barcodeObject.type")
        SxEventManager.shared.fireEvent(eventType: SxEventManager.EventType.onBarcodeDetected.rawValue)
    }
    
    
}
