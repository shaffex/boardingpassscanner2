//
//  SxView_BarCode.swift
//  SxMagicUi-Beta
//
//  Created by Peter Popovec on 02/09/2023.
//

import SwiftUI

#if canImport(CoreImage.CIFilterBuiltins)
import CoreImage.CIFilterBuiltins

struct SxView_BarCode: View {
    let barCodeType: String
    let barcodeText: String
    let foregroundColor: UIColor
    let backgroundColor: UIColor
    
    private func createBarCodeFilter() -> CIFilter {
        switch barCodeType {
        case "qr": return CIFilter.qrCodeGenerator()
        case "aztec": return CIFilter.aztecCodeGenerator()
        case "pdf417": return CIFilter.pdf417BarcodeGenerator()
        case "code128","ean13", "ean8": return CIFilter.code128BarcodeGenerator()
        default: return CIFilter.qrCodeGenerator()
        }
    }
    
    func generateQrCode(codeString: String) -> UIImage? {
        let data = codeString.data(using: .utf8)
                
        let filter = createBarCodeFilter()
        filter.setValue(data, forKey: "inputMessage")
                
        guard let colorFilter = CIFilter(name: "CIFalseColor") else { return nil }
        colorFilter.setValue(filter.outputImage, forKey: "inputImage")
        colorFilter.setValue(CIColor(cgColor: backgroundColor.cgColor), forKey: "inputColor1") // Background white
        colorFilter.setValue(CIColor(cgColor: foregroundColor.cgColor), forKey: "inputColor0") // Foreground or the barcode RED
        
        if let qrCodeCIImage = colorFilter.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(qrCodeCIImage, from: qrCodeCIImage.extent) {
                #if os(macOS)
                let uiImage = UIImage(cgImage: cgImage, size: .zero) // test this!!!!
                #else
                let uiImage = UIImage(cgImage: cgImage)
                #endif
                return uiImage
            }
        }
        
        return nil
    }
    
    var body: some View {
        #if os(macOS)
        Image(nsImage: generateQrCode(codeString: node.getText() ?? "") ?? UIImage())
            .interpolation(.none)
            .resizable()
            .scaledToFit()
        #else
        Image(uiImage: generateQrCode(codeString: barcodeText) ?? UIImage())
            .interpolation(.none)
            .resizable()
            .scaledToFit()
        #endif
    }
}

#else
struct SxView_BarCode: SxViewProtocol {
    @DynamicNode var node: MagicNode
    
    var body: some View {
        Text("N/A for Apple Watch")
    }
}
#endif
