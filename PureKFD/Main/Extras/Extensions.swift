//
//  Extensions.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import Foundation
import UIKit
import SwiftUI
import CoreGraphics
import CoreImage

func overwriteFile(at filePath: String, with newData: Data) async throws {
    if FileManager.default.fileExists(atPath: URL.documents.appendingPathComponent("TempOverwriteFile").path) {
        try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("TempOverwriteFile"))
    }
    try newData.write(to: URL.documents.appendingPathComponent("TempOverwriteFile"))
    try await overwriteWithFileImpl(replacementURL: URL.documents.appendingPathComponent("TempOverwriteFile"), pathToTargetFile: filePath)
}

extension String {
    func removingFileExtensions(_ count: Int) -> String {
        var components = self.components(separatedBy: ".")
        if components.count > count {
            let lastIndex = components.index(components.endIndex, offsetBy: -count)
            let pathWithoutExtensions = components[..<lastIndex]
            return pathWithoutExtensions.joined(separator: ".")
        }
        return self
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
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

func cleanTemp() {
    do {
        let contents = try FileManager.default.contentsOfDirectory(at: FileManager.default.temporaryDirectory, includingPropertiesForKeys: nil, options: [])
        for fileURL in contents {
            try FileManager.default.removeItem(at: fileURL)
        }
    } catch {
        // Handle any errors that occur during the deletion process.
        print("Error clearing temporary directory: \(error)")
    }
}

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

func getContentsOfFolder(folderURL: URL) -> [URL]? {
    do {
        let fileManager = FileManager.default
        let folderContents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        return folderContents
    } catch {
        print("Error: \(error)")
        return nil
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
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
    func toJSON() -> [String: Any]? {
        let lines = self.components(separatedBy: "\n")
        var jsonObject: [String: Any] = [:]

        for line in lines {
            let components = line.components(separatedBy: ": ")
            if components.count == 2 {
                let key = components[0]
                let value = components[1]
                jsonObject[key] = value
            } else if components.count > 2 {
                let key = components[0]
                let value = components[1..<components.count].joined(separator: ": ")
                jsonObject[key] = value
            }
        }

        return jsonObject.isEmpty ? nil : jsonObject
    }
    func toJSONArray() -> [[String: Any]] {
        let packageStrings = self.components(separatedBy: "\n\n")
        var jsonArray: [[String: Any]] = []

        for packageString in packageStrings {
            let lines = packageString.components(separatedBy: "\n")
            var jsonObject: [String: Any] = [:]

            for line in lines {
                let components = line.components(separatedBy: ": ")
                if components.count == 2 {
                    let key = components[0]
                    let value = components[1]
                    jsonObject[key] = value
                } else if components.count > 2 {
                    let key = components[0]
                    let value = components[1..<components.count].joined(separator: ": ")
                    jsonObject[key] = value
                }
            }

            if !jsonObject.isEmpty {
                jsonArray.append(jsonObject)
            }
        }

        return jsonArray
    }
}

extension Array {
    func atIndex(_ index: Int) -> Element? {
        return index < count ? self[index] : nil
    }
}

func refreshView(appData:AppData) {
    appData.UserData.refresh.toggle()
    appData.save()
}

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
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
                body += "\n\(device.systemName) \(systemVersion), PureKFD v\(appVersion)"
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

// Color Manager by Lemin!
class SpringboardColorManager {
    enum SpringboardType: CaseIterable {
        case dock
        case folder
        case folderBG
        case libraryFolder
        case switcher
        case notif
        case notifShadow
        case module
        case moduleBG
    }
    
    static func convertStringToSpringboardType(_ stringValue: String) -> SpringboardType? {
        switch stringValue {
        case "bannerbg":
            return .notif
        case "bannershadow":
            return .notifShadow
        case "ccbg":
            return .moduleBG
        case "cctile":
            return .module
        case "dock":
            return .dock
        case "folder":
            return .folder
        case "folderbg":
            return .folderBG
        case "libraryFolder":
            return .libraryFolder
        case "switcher":
            return .switcher
        default:
            return nil
        }
    }
    
    private static let finalFiles: [SpringboardType: [String]] = [
        .folder: ["folderDark", "folderLight"],
        .libraryFolder: ["podBackgroundViewDark", "podBackgroundViewLight"],
        .dock: ["dockDark", "dockLight"],
        .folderBG: ["folderExpandedBackgroundHome", "homeScreenOverlay", "homeScreenOverlay-iPad"],
        .switcher: ["homeScreenBackdrop-application"],
        .notif: ["plattersDark", "platters"],
        .notifShadow: ["platterVibrantShadowDark", "platterVibrantShadowLight"],
        .module: ["modules"],
        .moduleBG: ["modulesBackground"]
    ]
    
    private static let fileFolders: [SpringboardType: String] = [
        .folder: "/System/Library/PrivateFrameworks/SpringBoardHome.framework/",
        .libraryFolder: "/System/Library/PrivateFrameworks/SpringBoardHome.framework/",
        .dock: "/System/Library/PrivateFrameworks/CoreMaterial.framework/",
        .folderBG: "/System/Library/PrivateFrameworks/SpringBoardHome.framework/",
        .switcher: "/System/Library/PrivateFrameworks/SpringBoard.framework/",
        .notif: "/System/Library/PrivateFrameworks/CoreMaterial.framework/",
        .notifShadow: "/System/Library/PrivateFrameworks/PlatterKit.framework/",
        .module: "/System/Library/PrivateFrameworks/CoreMaterial.framework/",
        .moduleBG: "/System/Library/PrivateFrameworks/CoreMaterial.framework/"
    ]
    
    private static let fileExt: [SpringboardType: String] = [
        .folder: ".materialrecipe",
        .libraryFolder: ".visualstyleset",
        .dock: ".materialrecipe",
        .folderBG: ".materialrecipe",
        .switcher: ".materialrecipe",
        .notif: ".materialrecipe",
        .notifShadow: ".visualstyleset",
        .module: ".materialrecipe",
        .moduleBG: ".materialrecipe"
    ]
    
    static func getDictValue(_ dict: [String: Any], _ key: String) -> Any? {
        for (k, v) in dict {
            if k == key {
                return dict[k]
            } else if let subDict = v as? [String: Any] {
                let temp: Any? = getDictValue(subDict, key)
                if temp != nil {
                    return temp
                }
            }
        }
        // did not find key in dictionary
        return nil
    }
    
    static func getColor(forType: SpringboardType) -> Color {
        let bgDir = getBackgroundDirectory()
        if bgDir == nil || finalFiles[forType] == nil || fileExt[forType] == nil || !FileManager.default.fileExists(atPath: (bgDir!.appendingPathComponent("\(finalFiles[forType]![0])\(fileExt[forType]!)").path)) {
            return Color.gray
        }
        do {
            let newData = try Data(contentsOf: bgDir!.appendingPathComponent("\(finalFiles[forType]![0])\(fileExt[forType]!)"))
            let plist = try PropertyListSerialization.propertyList(from: newData, options: [], format: nil) as! [String: Any]
            // get the colors
            let r = getDictValue(plist, "red") as? Double ?? CIColor.gray.red
            let g = getDictValue(plist, "green") as? Double ?? CIColor.gray.green
            let b = getDictValue(plist, "blue") as? Double ?? CIColor.gray.blue
            let mFactor = getAlphaMultiplier(forType: forType)
            let a = (getDictValue(plist, "tintAlpha") as? Double ?? mFactor)/mFactor
            
            return Color.init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b)).opacity(a)
        } catch {
            print(error.localizedDescription)
        }
        return Color.gray
    }
    
    static func getBlur(forType: SpringboardType) -> Double {
        let bgDir = getBackgroundDirectory()
        if bgDir == nil || finalFiles[forType] == nil || !FileManager.default.fileExists(atPath: (bgDir!.appendingPathComponent("\(finalFiles[forType]![0])\(fileExt[forType]!)").path)) {
            return 30
        }
        do {
            let newData = try Data(contentsOf: bgDir!.appendingPathComponent("\(finalFiles[forType]![0])\(fileExt[forType]!)"))
            let plist = try PropertyListSerialization.propertyList(from: newData, options: [], format: nil) as! [String: Any]
            // get the blur
            return getDictValue(plist, "blurRadius") as? Double ?? 30
        } catch {
            print(error.localizedDescription)
        }
        return 30
    }
    
    static func revertFiles(forType: SpringboardType) async throws {
        if finalFiles[forType] != nil && fileFolders[forType] != nil && fileExt[forType] != nil {
            for file in finalFiles[forType]! {
                if let url: URL = Bundle.main.url(forResource: file, withExtension: fileExt[forType]!) {
                    let replacementFile = try Data(contentsOf: url)
                    try await overwriteFile(at: "\(fileFolders[forType]!)\(file)\(fileExt[forType]!)", with: replacementFile)
                } else {
                    throw "No file resource was found!"
                }
            }
        } else {
            throw "File type doesn't exist in table???"
        }
    }
    
//    static func changeColor(plist: [String: Any], color: CIColor, blur: Int) throws {
//        var newPlist: [String: Any] = plist
//
//
//    }
    
    static func getAlphaMultiplier(forType: SpringboardType) -> Double {
        if forType == .module {
            return 0.8
        } else if forType == .moduleBG || forType == .notifShadow || forType == .notif || forType == .folder || forType == .folderBG {
            return 1
        } else {
            return 0.3
        }
    }
    
    static func createColorOLD(forType: SpringboardType, color: CIColor, blur: Int, asTemp: Bool = false) throws {
        let bgDir = getBackgroundDirectory()
        
        if bgDir != nil && finalFiles[forType] != nil && fileFolders[forType] != nil && fileExt[forType] != nil {
            // get the files
            let url = Bundle.main.url(forResource: "replacement", withExtension: ".materialrecipe")
            // set the colors
            if url != nil {
                do {
                    let plistData = try Data(contentsOf: url!)
                    var plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as! [String: Any]
                    
                    if var firstLevel = plist["baseMaterial"] as? [String : Any], var secondLevel = firstLevel["tinting"] as? [String: Any], var thirdLevel = secondLevel["tintColor"] as? [String: Any] {
                        // set the colors
                        thirdLevel["red"] = color.red
                        thirdLevel["green"] = color.green
                        thirdLevel["blue"] = color.blue
                        thirdLevel["alpha"] = 1
                        
                        if var secondLevel2 = firstLevel["materialFiltering"] as? [String: Any] {
                            secondLevel2["blurRadius"] = blur
                            firstLevel["materialFiltering"] = secondLevel2
                        }
                        
                        secondLevel["tintColor"] = thirdLevel
                        secondLevel["tintAlpha"] = color.alpha*(getAlphaMultiplier(forType: forType))
                        firstLevel["tinting"] = secondLevel
                        plist["baseMaterial"] = firstLevel
                    }
                    
                    if forType == .module {
                        let styles: [String: String] = [
                            "fill": "moduleFill",
                            "stroke": "moduleStroke"
                        ]
                        plist["styles"] = styles
                        plist["materialSettingsVersion"] = 2
                    }
                    
                    // fill with empty data
                    for (_, file) in finalFiles[forType]!.enumerated() {
                        // get original data
                        let path: String = "\(fileFolders[forType]!)\(file)\(fileExt[forType]!)"
                        let newUrl = URL(fileURLWithPath: path)
                        do {
                            let originalFileSize = try Data(contentsOf: newUrl).count
                            let newData = try UsefulFunctions.addEmptyData(matchingSize: originalFileSize, to: plist)
                            // save file to background directory
                            if newData.count == originalFileSize {
                                if asTemp {
                                    try newData.write(to: FileManager.default.temporaryDirectory.appendingPathComponent(file+fileExt[forType]!))
                                } else {
                                    try newData.write(to: bgDir!.appendingPathComponent(file+fileExt[forType]!))
                                }
                            } else {
                                print("NOT CORRECT SIZE")
                            }
                        } catch {
                            print(error.localizedDescription)
                            throw error.localizedDescription
                        }
                    }
                } catch {
                    throw error.localizedDescription
                }
            }
        } else {
            throw "Could not find the background files directory!"
        }
    }
    
    static func createColor(forType: SpringboardType, color: CIColor, blur: Int, asTemp: Bool = false) throws {
        let bgDir = getBackgroundDirectory()
        
        if bgDir != nil && finalFiles[forType] != nil && fileFolders[forType] != nil && fileExt[forType] != nil {
            if fileExt[forType] == ".materialrecipe" && forType != .switcher {
                try createColorOLD(forType: forType, color: color, blur: blur, asTemp: asTemp)
                return
            }
            if forType == .switcher {
                for file in finalFiles[forType]! {
                    let path: String = "\(fileFolders[forType]!)\(file)\(fileExt[forType]!)"
                    let plistData = try Data(contentsOf: URL(fileURLWithPath: path))
                    var plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as! [String: Any]
                    
                    if var firstLevel = plist["baseMaterial"] as? [String : Any], var secondLevel = firstLevel["materialFiltering"] as? [String: Any] {
                        secondLevel["blurRadius"] = blur
                        firstLevel["materialFiltering"] = secondLevel
                        plist["baseMaterial"] = firstLevel
                    }
                    plist["materialSettingsVersion"] = nil
                    
                    let newUrl = URL(fileURLWithPath: path)
                    do {
                        let originalFileSize = try Data(contentsOf: newUrl).count
                        let newData = try UsefulFunctions.addEmptyData(matchingSize: originalFileSize, to: plist)
                        // save file to background directory
                        if newData.count == originalFileSize {
                            if asTemp {
                                if FileManager.default.fileExists(atPath: FileManager.default.temporaryDirectory.appendingPathComponent(file+fileExt[forType]!).path) {
                                    try FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent(file+fileExt[forType]!))
                                }
                                try newData.write(to: FileManager.default.temporaryDirectory.appendingPathComponent(file+fileExt[forType]!))
                            } else {
                                if FileManager.default.fileExists(atPath: bgDir!.appendingPathComponent(file+fileExt[forType]!).path) {
                                    try FileManager.default.removeItem(at: bgDir!.appendingPathComponent(file+fileExt[forType]!))
                                }
                                try newData.write(to: bgDir!.appendingPathComponent(file+fileExt[forType]!))
                            }
                        } else {
                            print("NOT CORRECT SIZE")
                            throw "Not the correct file size for item \(file+fileExt[forType]!)!"
                        }
                    } catch {
                        print(error.localizedDescription)
                        throw error.localizedDescription
                    }
                }
                return
            }
            // get the files
            for file in finalFiles[forType]! {
                let url = Bundle.main.url(forResource: file, withExtension: fileExt[forType]!)
                if url != nil {
                    //let originPath = fileFolders[forType]! + file + fileExt[forType]!
                    let newColor: CIColor = CIColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha*getAlphaMultiplier(forType: forType))
                    let newData = try ColorSwapManager.setColor(url: url!, color: newColor, blur: blur)
                    if asTemp {
                        if FileManager.default.fileExists(atPath: FileManager.default.temporaryDirectory.appendingPathComponent(file+fileExt[forType]!).path) {
                            try FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent(file+fileExt[forType]!))
                        }
                        try newData.write(to: FileManager.default.temporaryDirectory.appendingPathComponent(file+fileExt[forType]!))
                    } else {
                        if FileManager.default.fileExists(atPath: bgDir!.appendingPathComponent(file+fileExt[forType]!).path) {
                            try FileManager.default.removeItem(at: bgDir!.appendingPathComponent(file+fileExt[forType]!))
                        }
                        try newData.write(to: bgDir!.appendingPathComponent(file+fileExt[forType]!))
                    }
                } else {
                    throw "Backup url could not be found!"
                }
            }
            return
        } else {
            throw "Could not find the background files directory!"
        }
    }
    
    static func deteleColor(forType: SpringboardType) throws {
        let bgDir = getBackgroundDirectory()
        if bgDir != nil {
            for (_, file) in finalFiles[forType]!.enumerated() {
                let path: URL = bgDir!.appendingPathComponent(file+fileExt[forType]!)
                try FileManager.default.removeItem(at: path)
            }
        } else {
            throw "Could not find the background files directory!"
        }
    }
    
    static func applyColor(forType: SpringboardType, exploit_method: Int, asTemp: Bool = false) async {
        let bgDir = getBackgroundDirectory()
        
        if bgDir != nil && finalFiles[forType] != nil && fileFolders[forType] != nil && fileExt[forType] != nil {
            for (_, file) in finalFiles[forType]!.enumerated() {
                do {
                    var newData: Data? = nil
                    if asTemp {
                        newData = try Data(contentsOf: FileManager.default.temporaryDirectory.appendingPathComponent(file + fileExt[forType]!))
                    } else {
                        newData = try Data(contentsOf: bgDir!.appendingPathComponent(file + fileExt[forType]!))
                    }
                    if newData == nil {
                        throw "No color files found!"
                    }
                    // overwrite file
                    let path: String = "\(fileFolders[forType]!)\(file)\(fileExt[forType]!)"
                    if exploit_method == 0 {
                        try await overwriteFile(at: path, with: newData!)
                    } else {
                        try MDC.overwriteFile(at: path, with: newData!)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    // get the directory of where background files are saved
    static func getBackgroundDirectory() -> URL? {
        do {
            let newURL: URL = URL.documents.appendingPathComponent("Background_Files")
            if !FileManager.default.fileExists(atPath: newURL.path) {
                try FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: false)
            }
            return newURL
        } catch {
            print("An error occurred getting/making the background files directory")
        }
        return nil
    }
}

class UsefulFunctions {
    static func addEmptyData(matchingSize: Int, to plist: [String: Any]) throws -> Data {
        var newPlist = plist
        // create the new data
        guard var newData = try? PropertyListSerialization.data(fromPropertyList: newPlist, format: .binary, options: 0) else { throw "Unable to get data" }
        // add data if too small
        // while loop to make data match because recursive function didn't work
        // very slow, will hopefully improve
        if newData.count == matchingSize {
            return newData
        }
        var newDataSize = newData.count
        var added = matchingSize - newDataSize
        if added < 0 {
            added = 1
        }
        var count = 0
        while newDataSize != matchingSize && count < 200 {
            count += 1
            if added < 0 {
                print("LESS THAN 0")
                break
            }
            newPlist.updateValue(String(repeating: "#", count: added), forKey: "MdC")
            do {
                newData = try PropertyListSerialization.data(fromPropertyList: newPlist, format: .binary, options: 0)
            } catch {
                newDataSize = -1
                print("ERROR SERIALIZING DATA")
                break
            }
            newDataSize = newData.count
            if count < 5 {
                // max out this method at 5 if it isn't working
                added += matchingSize - newDataSize
            } else {
                if newDataSize > matchingSize {
                    added -= 1
                } else if newDataSize < matchingSize {
                    added += 1
                }
            }
        }

        return newData
    }
    
    public static func respring() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1) {
            let windows: [UIWindow] = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
            
            for window in windows {
                window.alpha = 0
                window.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        }
        
        animator.addCompletion { _ in
            if UserDefaults.standard.string(forKey: "RespringType") ?? "Frontboard" == "Backboard" {
                //backboard_respring()
            } else {
                //respring()
            }
            
            //sleep(2) // give the springboard some time to restart before exiting
            exit(0)
        }
        
        animator.startAnimation()
    }
    
    public static func getDefaultStr(forKey: String, defaultValue: String = "Visible") -> String {
        let defaults = UserDefaults.standard
        
        return defaults.string(forKey: forKey) ?? defaultValue
    }
}

enum OverwritingFileTypes {
    case springboard
    case cc
    case plist
    case audio
    case region
}

class ColorSwapManager {
    public static func setColor(url: URL, color: CIColor, blur: Int) throws -> Data {
        let plistData = try Data(contentsOf: url)
        if let originalPlist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
            var plist = setColor(list: originalPlist, color: color, blur: blur)
            let newData = try UsefulFunctions.addEmptyData(matchingSize: plistData.count, to: plist)
            if newData.count == plistData.count {
                return newData
            } else {
                throw "File size does not match!!!\nNew: \(newData.count)\nOld: \(plistData.count)"
            }
        } else {
            throw "Error serializing original plist data!"
        }
    }
    
    public static func setColor(list: [String: Any], color: CIColor, blur: Int) -> [String: Any] {
        func changeValue(dict: [String: Any], keyName: String, newName: String, replacement: Any, remove: Bool = true, appends: Bool = false) -> [String: Any] {
            var newDict = dict
            for (k, _) in dict {
                if k == keyName {
                    if remove {
                        newDict[k] = nil
                        newDict[newName] = replacement
                    } else {
                        if appends, var repDict = dict[k] as? [String: Any] {
                            repDict[newName] = replacement
                            newDict[k] = repDict
                        } else {
                            newDict[k] = [newName: replacement]
                        }
                    }
                } else if let subdict = dict[k] as? [String: Any] {
                    newDict[k] = changeValue(dict: subdict, keyName: keyName, newName: newName, replacement: replacement, remove: remove)
                }
            }
            return newDict
        }
        
        var changed = list
        changed["materialSettingsVersion"] = nil
        changed["visualStyleSetVersion"] = nil
        changed["MdC"] = nil
        
        let tintColor: [String: Double] = [
            "alpha": color.alpha,
            "red": color.red,
            "green": color.green,
            "blue": color.blue
        ]
        let tinting: [String: Any] = [
            "tintAlpha": color.alpha,
            "tintColor": tintColor
        ]
        
        let newMaterialFiltering: [String: Any] = [
            "blurRadius": blur,
            "tinting": tinting
        ]
        
        changed = changeValue(dict: changed, keyName: "blurRadius", newName: "blurRadius", replacement: blur)
        changed = changeValue(dict: changed, keyName: "materialFiltering", newName: "materialFiltering", replacement: newMaterialFiltering)
        changed = changeValue(dict: changed, keyName: "filtering", newName: "tinting", replacement: tinting)
        
        // return it
        return changed
    }
}
