//
//  SxView_ViewFinderCorners.swift
//  Barcoder
//
//  Created by noobie on 13/08/2025.
//

import MagicUiFramework
import SwiftUI

struct SxView_ViewFinderCorners: SxViewProtocol {
    @DynamicNode var node: MagicNode
    
    init(node: MagicNode) {
        self.node = node
    }
    
    var color: Color {
        let colorString = node.getAttribute("color") ?? "clear"
        return Color(hex: colorString)
    }
    
    var boxSize: CGFloat {
        node.getAttribute("boxSize")?.convertToCGFloat() ?? 0.5
    }
    
    
    
        var lineWidth: CGFloat = 5
        /// how far the straight “arms” extend from each corner (0…1 of box size)
        var armRatio: CGFloat = 0.16
        /// the inside corner radius
        var cornerRadiusRatio: CGFloat = 0.10
        //@State private var pulse = false

        var body: some View {
            GeometryReader { geo in
                let box    = geo.size.width * boxSize            // 75% of screen width
                let arm    = box * armRatio
                let radius = box * cornerRadiusRatio

                let x0 = (geo.size.width  - box) / 2
                let y0 = (geo.size.height - box) / 2
                let x1 = x0 + box
                let y1 = y0 + box

                Path { p in
                    // ┌ Top‑Left
                    p.move(to: CGPoint(x: x0 + radius + arm, y: y0))          // ← straight
                    p.addLine(to: CGPoint(x: x0 + radius, y: y0))
                    p.addArc(center: CGPoint(x: x0 + radius, y: y0 + radius),  // ↺ arc
                             radius: radius,
                             startAngle: .degrees(-90),
                             endAngle: .degrees(-180),
                             clockwise: true)
                    p.addLine(to: CGPoint(x: x0, y: y0 + radius + arm))        // ↓ straight

                    // ┐ Top‑Right
                    p.move(to: CGPoint(x: x1 - radius - arm, y: y0))
                    p.addLine(to: CGPoint(x: x1 - radius, y: y0))
                    p.addArc(center: CGPoint(x: x1 - radius, y: y0 + radius),
                             radius: radius,
                             startAngle: .degrees(-90),
                             endAngle: .degrees(0),
                             clockwise: false)
                    p.addLine(to: CGPoint(x: x1, y: y0 + radius + arm))

                    // └ Bottom‑Left
                    p.move(to: CGPoint(x: x0, y: y1 - radius - arm))
                    p.addLine(to: CGPoint(x: x0, y: y1 - radius))
                    p.addArc(center: CGPoint(x: x0 + radius, y: y1 - radius),
                             radius: radius,
                             startAngle: .degrees(180),
                             endAngle: .degrees(90),
                             clockwise: true)
                    p.addLine(to: CGPoint(x: x0 + radius + arm, y: y1))

                    // ┘ Bottom‑Right
                    p.move(to: CGPoint(x: x1, y: y1 - radius - arm))
                    p.addLine(to: CGPoint(x: x1, y: y1 - radius))
                    p.addArc(center: CGPoint(x: x1 - radius, y: y1 - radius),
                             radius: radius,
                             startAngle: .degrees(0),
                             endAngle: .degrees(90),
                             clockwise: false)
                    p.addLine(to: CGPoint(x: x1 - radius - arm, y: y1))
                }
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
//                .animation(.linear(duration: 0.85).repeatForever(autoreverses: true), value: pulse)
//                .onAppear { pulse = true }
                .allowsHitTesting(false)
            }
            //.ignoresSafeArea()
        }
}

extension Color {
    private static func getColorFromString(_ string: String) -> Color {
        switch string {
        case "black": return .black
        case "white": return .white
        case "gray": return .gray
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "brown": return .brown
        case "mint": return .mint
        case "teal": return .teal
        case "pink": return .pink
        case "indigo": return .indigo
            
        case "primary": return .primary
        case "secondary": return .secondary
        case "accentColor": return .accentColor
            
        case "random": return randomColor()
            
        default:
            return .clear // This color will be returned if all attempts fail
        }
    }
    
    static func randomColor() -> Color {
        let red = Double.random(in: 0..<1)
        let green = Double.random(in: 0..<1)
        let blue = Double.random(in: 0..<1)
        return Color(red: red, green: green, blue: blue)
    }
    
    init(hex: String) {
        var formattedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                
        var alpha: Double = 1.0
        
        if formattedHex.count == 8 {
            let alphaHex = formattedHex.suffix(2)
            formattedHex = String(formattedHex.dropLast(2))
            
            if let alphaValue = Double("0x\(alphaHex)") {
                alpha = alphaValue / 255.0
            }
        }
        
        guard formattedHex.count == 6, let rgbValue = Int(formattedHex, radix: 16) else {
            //self.init(.displayP3, red: 0, green: 0, blue: 0, opacity: 0)
            self.init(UIColor(Color.getColorFromString(hex)))
            return
        }
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        //self.init(.displayP3, red: red, green: green, blue: blue, opacity: alpha)
        self.init(.displayP3, red: red, green: green, blue: blue, opacity: alpha)
    }
}


