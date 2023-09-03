//
//  extensions.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/2/23.
//

import Foundation
import SwiftUI
import UIKit

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

extension Text {
    func settingButtonStyle() -> some View {
        self
            .foregroundColor(.purple)
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.purple, lineWidth: 2)
            )
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

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
    
    func toNormHex() -> String {
        #if canImport(UIKit)
        let components = UIColor(self).cgColor.components ?? []
        #else
        let components = NSColor(self).cgColor.components ?? []
        #endif
        
        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    func toHex(includeAlpha: Bool = true) -> String {
        let uiColor = UIColor(self)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

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
    var hexadecimalData: Data? {
        var hex = self
        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }
        
        var data = Data(capacity: hex.count / 2)
        
        var index = hex.startIndex
        while index < hex.endIndex {
            let byteRange = index..<hex.index(index, offsetBy: 2)
            if let byte = UInt8(hex[byteRange], radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            
            index = hex.index(index, offsetBy: 2)
        }
        
        return data
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

extension URL {
    static var documents: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// Alert++
// credit: sourcelocation & TrollTools
var currentUIAlertController: UIAlertController?


fileprivate let errorString = NSLocalizedString("Error", comment: "")
fileprivate let okString = NSLocalizedString("OK", comment: "")
fileprivate let cancelString = NSLocalizedString("Cancel", comment: "")

extension UIApplication {
    
    func dismissAlert(animated: Bool) {
        DispatchQueue.main.async {
            currentUIAlertController?.dismiss(animated: animated)
        }
    }
    func alert(title: String = errorString, body: String, animated: Bool = true, withButton: Bool = true) {
        DispatchQueue.main.async {
            var body = body
            
            if title == errorString {
                // append debug info
                let device = UIDevice.current
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
                let systemVersion = device.systemVersion
                body += "\n\(device.systemName) \(systemVersion), version \(appVersion) build \(appBuild) escaped=\(FileManager.default.isReadableFile(atPath: "/var/mobile"))"
            }
            
            currentUIAlertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            if withButton { currentUIAlertController?.addAction(.init(title: okString, style: .cancel)) }
            self.present(alert: currentUIAlertController!)
        }
    }
    func confirmAlert(title: String = errorString, body: String, confirmTitle: String = okString, onOK: @escaping () -> (), noCancel: Bool) {
        DispatchQueue.main.async {
            currentUIAlertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            if !noCancel {
                currentUIAlertController?.addAction(.init(title: cancelString, style: .cancel))
            }
            currentUIAlertController?.addAction(.init(title: confirmTitle, style: noCancel ? .cancel : .default, handler: { _ in
                onOK()
            }))
            self.present(alert: currentUIAlertController!)
        }
    }
    func change(title: String = errorString, body: String) {
        DispatchQueue.main.async {
            currentUIAlertController?.title = title
            currentUIAlertController?.message = body
        }
    }
    
    func present(alert: UIAlertController) {
        if var topController = self.windows[0].rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(alert, animated: true)
            // topController should now be your topmost view controller
        }
    }
}

// Images
let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit, compressionQuality quality: CGFloat = 0.4, completion: @escaping (UIImage?) -> Void) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data),
                let compressedData = image.jpegData(compressionQuality: quality),
                let compressedImage = UIImage(data: compressedData)
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.image = compressedImage
                completion(compressedImage)
            }
        }.resume()
    }

    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit, compressionQuality quality: CGFloat = 0.4, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: link) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        if let pathExtension = URL(string: url.pathExtension.lowercased())?.absoluteString, pathExtension == "gif" {
            contentMode = mode
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data, error == nil,
                    let animatedImage = UIImage(data: data)
                else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    self?.image = animatedImage
                    completion(animatedImage)
                }
            }.resume()
        } else {
            downloaded(from: url, contentMode: mode, compressionQuality: quality, completion: completion)
        }
    }
}
