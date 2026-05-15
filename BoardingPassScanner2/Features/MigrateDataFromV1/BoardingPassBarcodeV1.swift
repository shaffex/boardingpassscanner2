//
//  BoardingPassBarcodeV1.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 12/05/2026.
//

import Foundation

final class BoardingPassBarcodeV1: NSObject, NSSecureCoding, Decodable {
    static var supportsSecureCoding: Bool { true }
    var barcodeText: String = ""
    var barcodeType: String = ""
    var barcodeYear: Int = 0
    var barcodeDepartureDate = Date()

    override init() {
        super.init()
    }

    required init(coder decoder: NSCoder) {
        barcodeText = decoder.decodeObject(of: NSString.self, forKey: "barcodeText") as? String ?? ""
        barcodeType = decoder.decodeObject(of: NSString.self, forKey: "barcodeType") as? String ?? ""
        barcodeYear = decoder.decodeInteger(forKey: "barcodeYear")
        barcodeDepartureDate = decoder.decodeObject(of: NSDate.self, forKey: "barcodeDepartureDate") as? Date ?? Date()
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(barcodeText, forKey: "barcodeText")
        coder.encode(barcodeType, forKey: "barcodeType")
        coder.encode(barcodeYear, forKey: "barcodeYear")
        coder.encode(barcodeDepartureDate, forKey: "barcodeDepartureDate")
    }
}
