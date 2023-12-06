//
//  ColorHandling.swift
//  PureKFD
//
//  Created by Lrdsnow on 11/4/23.
//

import Foundation
import UIKit
import SwiftUI

extension UIColor {
    public func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
            
        getRed(&r, green: &g, blue: &b, alpha: &a)
            
        let redComponent = Int(r * 255)
        let greenComponent = Int(g * 255)
        let blueComponent = Int(b * 255)
        let alphaComponent = Int(a * 255)
            
        let hexString = String(format: "#%02X%02X%02X%02X", redComponent, greenComponent, blueComponent, alphaComponent)
        
        return hexString
    }
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 || hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    if hexColor.count == 6 {
                        r = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                        g = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                        b = CGFloat(hexNumber & 0x000000ff) / 255
                        a = 1.0
                    } else {
                        r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                        g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                        b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                        a = CGFloat(hexNumber & 0x000000ff) / 255
                    }

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    func toHex(includeAlpha: Bool = true) -> String {
        guard let components = cgColor?.components, let numberOfComponents = cgColor?.numberOfComponents else {
            return ""
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1.0

        if numberOfComponents >= 3 {
            red = components[0]
            green = components[1]
            blue = components[2]
        }

        if numberOfComponents >= 4 {
            alpha = components[3]
        }

        let redValue = Int(red * 255)
        let greenValue = Int(green * 255)
        let blueValue = Int(blue * 255)
        let alphaValue = Int(alpha * 255)

        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", redValue, greenValue, blueValue, alphaValue)
        } else {
            return String(format: "#%02X%02X%02X", redValue, greenValue, blueValue)
        }
    }
}

extension String {
    func toColor(alpha: Double = 1.0) -> Color? {
        if self.contains("#") {
            var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
            hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
            
            var rgb: UInt64 = 0
            Scanner(string: hexSanitized).scanHexInt64(&rgb)
            
            let red = Double((rgb & 0xFF0000) >> 16) / 255.0
            let green = Double((rgb & 0x00FF00) >> 8) / 255.0
            let blue = Double(rgb & 0x0000FF) / 255.0
            
            return Color(red: red, green: green, blue: blue, opacity: alpha)
        } else {
            return nil
        }
    }
}
