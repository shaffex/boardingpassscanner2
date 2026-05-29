//
//  SxPassKit.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 08/05/2026.
//

internal import PassKit
import MagicUiFramework

struct SxPassKit {
    let pass: PKPass
    
    static var testPass: PKPass? {
        return SxPassKit.getPassFromFile(fileURL: SxFile.documentsDir("newPass.pkpass"))
    }
    
    static func getPassFromFile(fileURL :URL) -> PKPass? {
        if let data:Data = SxFile.readFile(fileURL: fileURL) {
            do {
                let pass = try PKPass(data: data)
                print("Pass read")
                return pass
            }
            catch {
                print("Error: \(error.localizedDescription)")
            }
        }
        return nil
    }
}
