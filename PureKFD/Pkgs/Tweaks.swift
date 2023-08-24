//
//  Tweaks.swift
//  test
//
//  Created by Lrdsnow on 8/20/23.
//

import Foundation
import SwiftUI

struct Tweaks: Codable {
    let operations: [Operation]
    let spec: String
}

protocol OperationType {
    func apply(exploit_method: Int)
    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType?
}

struct Operation: Codable {
    let type: String
}

struct SuperviseOperation: OperationType {
    let pkg: [String: Any]

    func apply(exploit_method: Int) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed")
        let configURL = installedFolderPath.appendingPathComponent(pkg["bundleID"] as! String).appendingPathComponent("config.json")
            
        var supervise: Bool = true
            
        if let config = readJSON(from: configURL) {
            // Get resfield from config once i can get the stupid thing to write
        }
        if exploit_method == 0 {
            setSuperviseMode(supervise)
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        return SuperviseOperation(
            pkg: pkg
        )
    }
}

struct WhiteListOperation: OperationType {
    let pkg: [String: Any]

    func apply(exploit_method: Int) {
        if exploit_method == 0 {
            whitelist()
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        return WhiteListOperation(
            pkg: pkg
        )
    }
}

struct ClearSMSOperation: OperationType {
    let pkg: [String: Any]

    func apply(exploit_method: Int) {
        if exploit_method == 0 {
            removeSMSCache()
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        return ClearSMSOperation(
            pkg: pkg
        )
    }
}

struct DynamicIslandOperation: OperationType {
    let pkg: [String: Any]

    func apply(exploit_method: Int) {
        if exploit_method == 0 {
            DynamicKFD(2796)
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        return DynamicIslandOperation(
            pkg: pkg
        )
    }
}

struct FixDynamicIslandOperation: OperationType {
    let pkg: [String: Any]
    
    func apply(exploit_method: Int) {
        if exploit_method == 0 {
            DynamicKFD(Int32(Int(UIScreen.main.nativeBounds.height)))
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        return FixDynamicIslandOperation(
            pkg: pkg
        )
    }
}

struct RegionChangerOperation: OperationType {
    let pkg: [String: Any]

    func apply(exploit_method: Int) {
        if exploit_method == 0 {
            regionChanger("h63QSdBCiT/z0WU6rdQv6Q", "zHeENZu+wbg7PUprwNwBWg")
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        return RegionChangerOperation(
            pkg: pkg
        )
    }
}

struct ResSetOperation: OperationType {
    let pkg: [String: Any]

    func apply(exploit_method: Int) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed")
        let configURL = installedFolderPath.appendingPathComponent(pkg["bundleID"] as! String).appendingPathComponent("config.json")
            
        var res: [String: Int] = ["height": 2796, "width": 1290]
            
        if let config = readJSON(from: configURL) {
            // Get resfield from config once i can get the stupid thing to write
        }
        if exploit_method == 0 {
            ResSet16(res["height"]!, res["width"]!)
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        return ResSetOperation(
            pkg: pkg
        )
    }
}

struct AccentColorOperation: OperationType {
    let pkg: [String: Any]
    
    func get_resourceURL(filename: String) -> URL? {
        let bundlePath = Bundle.main.bundlePath
        let jsonFilePath = bundlePath + "/" + filename
        // Im sorry for my warcrimes
        if let jsonFileURL = URL(string: URL(fileURLWithPath: jsonFilePath).absoluteString) {
            return jsonFileURL
        } else {
            print("Failed to get URL")
            return nil
        }
    }
    
    func apply(exploit_method: Int) {
        if !pkg.isEmpty && exploit_method == 0 {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed")
            let configURL = installedFolderPath.appendingPathComponent(pkg["bundleID"] as! String).appendingPathComponent("config.json")
            
            var color = Color.clear
            var blur = 1
            
            if let config = readJSON(from: configURL) {
                let color_conf = config["color"]! as! [String: Any]
                color = Color(UIColor(hex: color_conf["value"]! as! String)!)
            }
            
            modifyColorsInCARFile(jsonData: readJSON(from: get_resourceURL(filename: "LightVibrantStandard.json")!)!, carFilePath: "/System/Library/PrivateFrameworks/CoreUI.framework/DesignLibrary-iOS.bundle/iOSRepositories/LightVibrantStandard.car", newColorValue: color)
            modifyColorsInCARFile(jsonData: readJSON(from: get_resourceURL(filename: "LightStandard.json")!)!, carFilePath: "/System/Library/PrivateFrameworks/CoreUI.framework/DesignLibrary-iOS.bundle/iOSRepositories/LightStandard.car", newColorValue: color)
            modifyColorsInCARFile(jsonData: readJSON(from: get_resourceURL(filename: "LightIncreasedContrast.json")!)!, carFilePath: "/System/Library/PrivateFrameworks/CoreUI.framework/DesignLibrary-iOS.bundle/iOSRepositories/LightIncreasedContrast.car", newColorValue: color)
            modifyColorsInCARFile(jsonData: readJSON(from: get_resourceURL(filename: "DarkVibrantStandard.json")!)!, carFilePath: "/System/Library/PrivateFrameworks/CoreUI.framework/DesignLibrary-iOS.bundle/iOSRepositories/DarkVibrantStandard.car", newColorValue: color)
            modifyColorsInCARFile(jsonData: readJSON(from: get_resourceURL(filename: "DarkStandard.json")!)!, carFilePath: "/System/Library/PrivateFrameworks/CoreUI.framework/DesignLibrary-iOS.bundle/iOSRepositories/DarkStandard.car", newColorValue: color)
            modifyColorsInCARFile(jsonData: readJSON(from: get_resourceURL(filename: "DarkIncreasedContrast.json")!)!, carFilePath: "/System/Library/PrivateFrameworks/CoreUI.framework/DesignLibrary-iOS.bundle/iOSRepositories/DarkIncreasedContrast.car", newColorValue: color)
        } else {
            print("Tweak package is empty or Unsupported!")
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        return AccentColorOperation(pkg: pkg)
    }
}

struct HideOperation: OperationType {
    let originPath: String
    let pkg: [String: Any]

    func apply(exploit_method: Int) {
        if exploit_method == 0 {
            funVnodeHide(strdup(originPath))
        } else if exploit_method == 1 {
            do {
                try MDC.overwriteFile(at: originPath, with: Data())
            } catch {
                print("Failed to clear file!")
            }
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        guard
            let originPath = dictionary["originPath"] as? String
        else {
            return nil
        }
        return HideOperation(originPath: originPath, pkg: pkg)
    }
}

struct SpringboardColorOperation: OperationType {
    let springboardElement: String
    let pkg: [String: Any]

    func sb_apply(_ sbType: SpringboardColorManager.SpringboardType, _ color: Color, _ blur: Int, exploit_method: Int, save: Bool = true) -> Bool {
        do {
            try SpringboardColorManager.createColor(forType: sbType, color: CIColor(color: UIColor(color)), blur: blur, asTemp: !save)
            try SpringboardColorManager.applyColor(forType: sbType, exploit_method: exploit_method)
            print("Success")
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }

    func apply(exploit_method: Int) {
        print("SpringboardColorOperation,", springboardElement)
        if !pkg.isEmpty {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed")
            let configURL = installedFolderPath.appendingPathComponent(pkg["bundleID"] as! String).appendingPathComponent("config.json")
            
            var color = Color.clear
            var blur = 1
            
            if let config = readJSON(from: configURL) {
                let color_conf = config["color"]! as! [String: Any]
                color = Color(UIColor(hex: color_conf["value"]! as! String)!)
            }
            
            if let name = pkg["name"] as? String {
                let succeeded = sb_apply(SpringboardColorManager.convertStringToSpringboardType(springboardElement)!, color, blur, exploit_method: exploit_method)
                if !succeeded {
                    print("Failed to apply!!!")
                }
            } else {
                print("Invalid tweak data!")
            }
        } else {
            print("Tweak package is empty or Unsupported!")
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        guard
            let springboardElement = dictionary["springboardElement"] as? String
        else {
            return nil
        }
        return SpringboardColorOperation(springboardElement: springboardElement, pkg: pkg)
    }
}

struct ReplacingOperation: OperationType {
    let replacementFileName: String
    let replacementFileBundled: Bool
    let originPath: String
    let pkg: [String: Any]

    func apply(exploit_method: Int) {
        //print("ReplacingOperation,", replacementFileName, originPath, "ReplacementFileBundled?:", replacementFileBundled)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed")
        let replaceURL = installedFolderPath.appendingPathComponent(pkg["bundleID"] as! String).appendingPathComponent(replacementFileName)
        if replacementFileBundled {
            if exploit_method == 0 { // KFD
                overwriteWithFileImpl(replacementURL: replaceURL, pathToTargetFile: originPath)
            } else if exploit_method == 1 { // MDC
                do {
                    try MDC.overwriteFile(at: originPath, with: readFileAsData(atURL: replaceURL)!)
                } catch {
                    print("Failed to copy \(originPath): \(error)")
                }
            }
        }
    }

    static func create(from dictionary: [String: Any], pkg: [String: Any]) -> OperationType? {
        guard
            let replacementFileName = dictionary["replacementFileName"] as? String,
            let replacementFileBundled = dictionary["replacementFileBundled"] as? Bool,
            let originPath = dictionary["originPath"] as? String
        else {
            return nil
        }
        return ReplacingOperation(
            replacementFileName: replacementFileName,
            replacementFileBundled: replacementFileBundled,
            originPath: originPath,
            pkg: pkg
        )
    }
}

let operationHandlers: [String: OperationType.Type] = [
    "springboardColor": SpringboardColorOperation.self,
    "replacing": ReplacingOperation.self,
    "resset": ResSetOperation.self,
    "accentOperation": AccentColorOperation.self,
    "supervise": SuperviseOperation.self,
    "changeregion": RegionChangerOperation.self,
    "whitelist": WhiteListOperation.self,
    "clearsms": ClearSMSOperation.self,
    "dynamicIsland": DynamicIslandOperation.self,
    "fixdynamicIsland": FixDynamicIslandOperation.self,
    "removing": HideOperation.self,
    // Add other operation type mappings here
]

func readJSON(from fileURL: URL) -> [String: Any]? {
    do {
        let jsonData = try Data(contentsOf: fileURL)
        
        guard let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            print("Invalid JSON format")
            return nil
        }
        
        return jsonDictionary
    } catch {
        print("Error reading json: \(error)")
        return nil
    }
}

func applyTweaks(from fileURL: URL, exploit_method: Int) {
    do {
        let jsonData = try Data(contentsOf: fileURL)
        
        guard let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            print("Invalid JSON format")
            return
        }

        guard let operations = jsonDictionary["operations"] as? [[String: Any]] else {
            print("Missing 'operations' in JSON")
            return
        }
        
        guard let pkg = readJSON(from: fileURL.deletingLastPathComponent().appendingPathComponent("info.json")) else {
            print("Missing info.json")
            return
        }
        
        for operationData in operations {
            guard let operationType = operationData["type"] as? String else {
                print("Missing 'type' for operation")
                continue
            }

            if let operationTypeClass = operationHandlers[operationType] {
                if let operation = operationTypeClass.create(from: operationData, pkg: pkg) {
                    operation.apply(exploit_method: exploit_method)
                } else {
                    print("Error creating operation for type:", operationType)
                }
            } else {
                print("Unknown or unsupported operation type:", operationType)
                print("Possible operations are:", operationHandlers.keys)
            }
        }

        print("Tweak applied successfully.")
    } catch {
        print("Error applying tweaks: \(error)")
    }
}

func applyAllTweaks(exploit_method: Int) {
    let installedPackages = getInstalledPackages()
    for installedPackage in installedPackages {
        if installedPackage.type == "picasso" {
            let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed")
            let packageFolderPath = installedFolderPath.appendingPathComponent(installedPackage.bundleID).appendingPathComponent("tweak.json")
            print("Applying", installedPackage.bundleID)
            applyTweaks(from: packageFolderPath, exploit_method: exploit_method)
            DispatchQueue.global(qos: .utility).async {
                                 FetchLog()
                             }
        } else if installedPackage.type == "misaka" {
            let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Misaka/Installed")
            let overwriteFolderPath = installedFolderPath.appendingPathComponent(installedPackage.bundleID).appendingPathComponent("Overwrite")
            overwriteMisaka(sourceFolderURL: overwriteFolderPath, exploit_method: exploit_method)
            DispatchQueue.global(qos: .utility).async {
                                 FetchLog()
                             }
        }
        else {
            print("Unsupported Package")
        }
    }
}

func replaceBeforeAndSubstring(in input: String, targetSubstring: String, with replacement: String) -> String {
    if let range = input.range(of: targetSubstring) {
        let startIndex = input.startIndex
        let substringStartIndex = range.lowerBound
        let contentAfter = input[range.upperBound...]
        
        return replacement + contentAfter
    }
    return input
}

func readFileAsData(atURL url: URL) -> Data? {
    do {
        let fileData = try Data(contentsOf: url)
        return fileData
    } catch {
        print("Error reading file: \(error)")
        return nil
    }
}

func overwriteMisaka(sourceFolderURL: URL, exploit_method: Int) {
    let fileManager = FileManager.default
    let rootURL = URL(fileURLWithPath: "/")
    
    func processItem(at itemURL: URL, relativeTo baseURL: URL) {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory) {
            let itemName = itemURL.lastPathComponent
            let targetItemURL = rootURL.appendingPathComponent(itemName)
            
            if isDirectory.boolValue {
                do {
                    let subContents = try fileManager.contentsOfDirectory(at: itemURL, includingPropertiesForKeys: nil, options: [])
                    for subItemURL in subContents {
                        processItem(at: subItemURL, relativeTo: baseURL)
                    }
                } catch {
                    print("Error reading subdirectory: \(error)")
                }
            } else {
                let relativePath = replaceBeforeAndSubstring(in: itemURL.path, targetSubstring: "/Overwrite", with: "")
                if exploit_method == 0 { // KFD
                    overwriteWithFileImpl(replacementURL: itemURL, pathToTargetFile: relativePath)
                } else if exploit_method == 1 { // MDC
                    do {
                        try MDC.overwriteFile(at: relativePath, with: readFileAsData(atURL: itemURL)!)
                    } catch {
                        print("Failed to copy \(itemName): \(error)")
                    }
                }
            }
        } else {
            print("\(itemURL) does not exist.")
        }
    }
    
    processItem(at: sourceFolderURL, relativeTo: sourceFolderURL)
}
