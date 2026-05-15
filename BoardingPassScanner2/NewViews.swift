//
//  NewModifiers.swift
//  Barcoder
//
//  Created by Peter Popovec on 15/05/2025.
//

import MagicUiFramework
import SwiftUI

struct SxView_RectangleWithSystemBackground: SxViewProtocol {
    @DynamicNode var node: MagicNode
    
    var body: some View {
        Rectangle()
            .fill(Color(UIColor.systemBackground))
    }
}

struct SxView_BarcodeIcon: SxViewProtocol {
    @DynamicNode var node: MagicNode
    
    // Helper to generate a color from a string
    func colorForName(_ name: String) -> Color {
        let hash = abs(name.hashValue)
        let hue = Double(hash % 360) / 360.0 // Use 360 for more color variety
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
    
    var name: String {
        node.getAttribute("name") ?? ""
    }
    
    var size: Double {
        node.getAttribute("size")?.convertToDouble() ?? 48
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(colorForName(name))
                .frame(width: size, height: size)
            Text(name.prefix(1).uppercased())
                .font(.system(size: size / 2))
                .foregroundColor(.white)
                .bold()
        }
    }
}

//#Preview {
//    let node = MagicNode()
//    
//    SxView_BarcodeIcon(node: )
//}
