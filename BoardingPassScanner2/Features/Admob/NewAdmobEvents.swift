//
//  NewActions.swift
//  PluginAdmob
//
//  Created by Peter Popovec on 01/03/2026.
//

import MagicUiFramework

struct NewEvents {
    enum EventType: String {
        case onAdLoaded
        case onAdLoadFailed
        case onAdRewardGranted
    }
    
    static let shared = NewEvents()
    
    func fireEvent(type: EventType, adUnitId: String, extraString: String? = nil) {
        if extraString != nil {
            SxMagicVariables.shared.setValue(extraString, forKey: "rewardedAdReward")
        }
        
        SxEventManager.shared.fireEvent(eventType: type.rawValue, observedVariable: adUnitId, extraInfo: extraString)
    }
}
