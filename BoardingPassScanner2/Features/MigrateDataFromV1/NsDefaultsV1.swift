//
//  NsDefaultsV1.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 13/05/2026.
//

import Foundation

class SettingsV1: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }
    
    var myBoardingPassesArray: Array<BoardingPassBarcodeV1> = []
    
    var isVibrationEnabled = true
    var isIndicatorVisible = true
    var isIndicatorFlashing = false
    var isShowingConfirmation = true
    var isShowingAlreadyScanned = true
    
    var isExpertModeEnabled = false
    var isTutorialEnabled = true
    
    //MARK: NSCoding protocol methods
    func encode(with aCoder: NSCoder){
        aCoder.encode(self.myBoardingPassesArray, forKey: "myBoardingPassesArray")
        aCoder.encode(self.isVibrationEnabled, forKey: "isVibrationEnabled")
        aCoder.encode(self.isIndicatorVisible, forKey: "isIndicatorVisible")
        aCoder.encode(self.isIndicatorFlashing, forKey: "isIndicatorFlashing")
        aCoder.encode(self.isShowingConfirmation, forKey: "isShowingConfirmation")
        aCoder.encode(self.isShowingAlreadyScanned, forKey: "isShowingAlreadyScanned")
        aCoder.encode(self.isExpertModeEnabled, forKey: "isExpertModeEnabled")
        aCoder.encode(self.isTutorialEnabled, forKey: "isTutorialEnabled")
    }
    
    override init() {
        super.init()
    }

    required init(coder decoder: NSCoder) {
        myBoardingPassesArray = decoder.decodeObject(
            of: [NSArray.self, BoardingPassBarcodeV1.self],
            forKey: "myBoardingPassesArray"
        ) as? [BoardingPassBarcodeV1] ?? []
        isVibrationEnabled = decoder.decodeBool(forKey: "isVibrationEnabled")
        isIndicatorVisible = decoder.decodeBool(forKey: "isIndicatorVisible")
        isIndicatorFlashing = decoder.decodeBool(forKey: "isIndicatorFlashing")
        isShowingConfirmation = decoder.decodeBool(forKey: "isShowingConfirmation")
        isShowingAlreadyScanned = decoder.decodeBool(forKey: "isShowingAlreadyScanned")
        isExpertModeEnabled = decoder.decodeBool(forKey: "isExpertModeEnabled")
        isTutorialEnabled = decoder.decodeBool(forKey: "isTutorialEnabled")
        super.init()
    }

}

struct NsDefaultsV1 {
    private let settingsKey = "settings"

    func deleteSettings() {
        UserDefaults.standard.removeObject(forKey: settingsKey)
        print("Removing V1 settings from UserDefaults")
    }
    
    func loadSettings() -> SettingsV1? {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            print("No V1 settings data found in UserDefaults")
            return nil
        }

        do {
            let settings = try unarchiveSettings(from: data)
            print("Loaded V1 boarding passes:", settings.myBoardingPassesArray.count)
            return settings
        } catch {
            print("Error when loading V1 settings: \(error.localizedDescription)")
            return nil
        }
    }

    private func unarchiveSettings(from data: Data) throws -> SettingsV1 {
        NSKeyedUnarchiver.setClass(SettingsV1.self, forClassName: "Boarding_Pass.Settings")
        NSKeyedUnarchiver.setClass(BoardingPassBarcodeV1.self, forClassName: "Boarding_Pass.BoardingPassBarcode")
        
        let allowedClasses: [AnyClass] = [
            SettingsV1.self,
            BoardingPassBarcodeV1.self,
        ]

        guard let loadedSettings = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: data) as? SettingsV1 else {
            throw CocoaError(.coderReadCorrupt)
        }

        return loadedSettings
    }
}
