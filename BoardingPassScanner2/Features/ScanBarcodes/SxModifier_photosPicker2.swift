//
//  SxModifier_photosPicker2.swift
//  Barcoder
//
//  Created by Peter Popovec on 13/08/2025.
//

import MagicUiFramework
import SwiftUI
import PhotosUI

struct SxModifier_photosPicker2: SxModifierProtocol {
    
    @DynamicNode var node: MagicNode
        
    @State private var photosPickerItem: PhotosPickerItem?
    //@State var selection: PhotosPickerItem?
    
    init(node: MagicNode) {
        self.node = node
    }
    
    func body(content: Content) -> some View {
        content
            .photosPicker(isPresented: SxEnvironmentObject.shared.bindingDialogIsPresented(forKey: node.modifierValue),
                              selection: $photosPickerItem,
                              matching: .images)
        
        .onChange(of: photosPickerItem) {
            Task {
                if let data = try? await photosPickerItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    DetectFromImage().detectBarcode(in: uiImage) { result, error in
                        if let (barcodeText, barcodeType) = result {
                            print("Barcode: \(barcodeText)")
                            print("Type: \(barcodeType)")

                            EventAddNewBarcode.fireNewBarcodeEvent(barcodeText: barcodeText, barcodeType: barcodeType)
                        } else {
                            print("Error: No barcode detected")
                            PluginActions.shared.runAction("presentAlert:myAlertCannotDetectBarcode")
                        }

                        // Reset picker for future selection
                        photosPickerItem = nil
                    }
                }
            }
        }
    }
}

extension SxEnvironmentObject {
    func bindingDialogIsPresented(forKey: String?) -> Binding<Bool> {
        if let key = forKey {
            return Binding<Bool>(
                get: {
                    //return self.internalValues[key] as? Bool ?? false
                    return SxMagicVariables.shared.value(forKey: key) as? Bool ?? false
                },
                set: { newValue in
//                    self.setInternalValue(newValue, forKey: key)
                    DispatchQueue.main.async {
                        SxMagicVariables.shared.setValue(newValue, forKey: key)
                    }
                    
                }
            )
        }
        
        // if key is not set bind to constamt
        return .constant(false)
    }
}
