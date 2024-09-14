//
//  DeviceInfo.swift
//  purekfd
//
//  Created by Lrdsnow on 7/4/24.
//

import Foundation
import UIKit

class DeviceInfo {
    static var build: String {
        get {
            let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
            let pattern = "\\(Build (.*)\\)"
                
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsString = systemVersion as NSString
                let results = regex.matches(in: systemVersion, range: NSRange(location: 0, length: nsString.length))
                
                if let match = results.first {
                    let buildNumberRange = match.range(at: 1)
                    return nsString.substring(with: buildNumberRange)
                }
            }
            return ""
        }
    }
    
    static var version: String {
        get {
            return UIDevice.current.systemVersion
        }
    }
    
    static var modelName: String {
        #if targetEnvironment(simulator)
        let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Unknown"
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        #endif
        return identifier
    }
    
    static var osString: String {
        get {
#if os(macOS)
            return "macOS"
#elseif os(tvOS)
            return "tvOS"
#elseif os(watchOS)
            return "watchOS"
#elseif os(visionOS)
            return "visionOS"
#else
            if ipad {
                return "iPadOS"
            } else {
                return "iOS"
            }
#endif
        }
    }
    
    static var ipad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var cpu: String {
        let model = self.modelName
        
        if let cpu = processorDict[model] {
            return cpu
        } else {
            let num = Int("\((model.components(separatedBy: ",").first ?? "").filter { $0.isNumber })")
            if let num = num {
                if model.contains("iPad") {
                    return "M\(num-12)"
                } else {
                    return "A\(num+1)"
                }
            }
        }
        return "Unknown"
    }
    
    public static let processorDict: [String: String] = [
        "iPod1,1": "APL0098",
        "iPhone1,1": "APL0098",
        "iPhone1,2": "APL0098",
        "iPod2,1": "APL0278",
        "iPhone2,1": "APL0298",
        "iPod3,1": "APL2298",
        "iPod4,1": "A4",
        "iPhone3,1": "A4",
        "iPhone3,2": "A4",
        "iPhone3,3": "A4",
        "iPad1,1": "A4",
        "iPhone4,1": "A5",
        "iPod5,1": "A5",
        "iPad2,5": "A5",
        "iPad2,6": "A5",
        "iPad2,7": "A5",
        "iPad2,1": "A5",
        "iPad2,2": "A5",
        "iPad2,3": "A5",
        "iPad2,4": "A5",
        "iPad3,1": "A5X",
        "iPad3,2": "A5X",
        "iPad3,3": "A5X",
        "iPhone5,1": "A6",
        "iPhone5,2": "A6",
        "iPhone5,3": "A6",
        "iPhone5,4": "A6",
        "iPad3,4": "A6X",
        "iPad3,5": "A6X",
        "iPad3,6": "A6X",
        "iPhone6,1": "A7",
        "iPhone6,2": "A7",
        "iPad4,4": "A7",
        "iPad4,5": "A7",
        "iPad4,6": "A7",
        "iPad4,7": "A7",
        "iPad4,8": "A7",
        "iPad4,9": "A7",
        "iPad4,1": "A7",
        "iPad4,2": "A7",
        "iPad4,3": "A7",
        "iPhone7,1": "A8",
        "iPhone7,2": "A8",
        "iPod7,1": "A8",
        "iPad5,1": "A8",
        "iPad5,2": "A8",
        "iPad5,4": "A8X",
        "iPad5,3": "A8X",
        "iPhone8,1": "A9",
        "iPhone8,2": "A9",
        "iPhone8,4": "A9",
        "iPad6,11": "A9",
        "iPad6,12": "A9",
        "iPad6,3": "A9X",
        "iPad6,4": "A9X",
        "iPad6,7": "A9X",
        "iPad6,8": "A9X",
        "iPhone9,1": "A10",
        "iPhone9,2": "A10",
        "iPhone9,3": "A10",
        "iPhone9,4": "A10",
        "iPad7,5": "A10",
        "iPad7,6": "A10",
        "iPod9,1": "A10",
        "iPad7,11": "A10",
        "iPad7,12": "A10",
        "iPad7,1": "A10X",
        "iPad7,2": "A10X",
        "iPad7,3": "A10X",
        "iPad7,4": "A10X",
        "iPhone10,1": "A11",
        "iPhone10,2": "A11",
        "iPhone10,3": "A11",
        "iPhone10,4": "A11",
        "iPhone10,5": "A11",
        "iPhone10,6": "A11",
        "iPhone11,2": "A12",
        "iPhone11,4": "A12",
        "iPhone11,6": "A12",
        "iPhone11,8": "A12",
        "iPad11,3": "A12",
        "iPad11,4": "A12",
        "iPad11,1": "A12",
        "iPad11,2": "A12",
        "iPad11,6": "A12",
        "iPad11,7": "A12",
        "iPad8,1": "A12X",
        "iPad8,2": "A12X",
        "iPad8,3": "A12X",
        "iPad8,4": "A12X",
        "iPad8,5": "A12X",
        "iPad8,6": "A12X",
        "iPad8,7": "A12X",
        "iPad8,8": "A12X",
        "iPad8,9": "A12Z",
        "iPad8,10": "A12Z",
        "iPad8,11": "A12Z",
        "iPad8,12": "A12Z",
        "iPhone12,1": "A13",
        "iPhone12,3": "A13",
        "iPhone12,5": "A13",
        "iPhone12,8": "A13",
        "iPad12,2": "A13",
        "iPad12,1": "A13",
        "iPhone13,1": "A14",
        "iPhone13,2": "A14",
        "iPhone13,3": "A14",
        "iPhone13,4": "A14",
        "iPad13,1": "A14",
        "iPad13,2": "A14",
        "iPad13,18": "A14",
        "iPad13,19": "A14",
        "iPad13,4": "M1",
        "iPad13,5": "M1",
        "iPad13,6": "M1",
        "iPad13,7": "M1",
        "iPad13,8": "M1",
        "iPad13,9": "M1",
        "iPad13,10": "M1",
        "iPad13,11": "M1",
        "iPad13,16": "M1",
        "iPad13,17": "M1",
        "iPhone14,4": "A15",
        "iPhone14,5": "A15",
        "iPhone14,2": "A15",
        "iPhone14,3": "A15",
        "iPad14,2": "A15",
        "iPad14,1": "A15",
        "iPhone14,6": "A15",
        "iPhone14,7": "A15",
        "iPhone14,8": "A15",
        "iPhone15,2": "A16",
        "iPhone15,3": "A16",
        "iPhone15,4": "A16",
        "iPhone15,5": "A16",
        "iPad14,3": "M2",
        "iPad14,4": "M2",
        "iPad14,5": "M2",
        "iPad14,6": "M2",
        "iPad14,8": "M2",
        "iPad14,9": "M2",
        "iPad14,10": "M2",
        "iPad14,11": "M2",
        "iPhone16,1": "A17",
        "iPhone16,2": "A17",
        "iPad16,3": "M4",
        "iPad16,4": "M4",
        "iPad16,5": "M4",
        "iPad16,6": "M4"
    ]
    
    static var prettyModel: String? {
        switch modelName {
        case "iPod1,1":
            return "iPod touch (1st generation)"
        case "iPod2,1":
            return "iPod touch (2nd generation)"
        case "iPod3,1":
            return "iPod touch (3rd generation)"
        case "iPod4,1":
            return "iPod touch (4th generation)"
        case "iPod5,1":
            return "iPod touch (5th generation)"
        case "iPod7,1":
            return "iPod touch (6th generation)"
        case "iPod9,1":
            return "iPod touch (7th generation)"
        case "iPhone1,1":
            return "iPhone"
        case "iPhone1,2":
            return "iPhone 3G"
        case "iPhone2,1":
            return "iPhone 3GS"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":
            return "iPhone 4"
        case "iPhone4,1":
            return "iPhone 4S"
        case "iPhone5,1", "iPhone5,2":
            return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":
            return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":
            return "iPhone 5s"
        case "iPhone7,1":
            return "iPhone 6 Plus"
        case "iPhone7,2":
            return "iPhone 6"
        case "iPhone8,1":
            return "iPhone 6s"
        case "iPhone8,2":
            return "iPhone 6s Plus"
        case "iPhone8,4":
            return "iPhone SE (1st generation)"
        case "iPhone9,1", "iPhone9,3":
            return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":
            return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4":
            return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":
            return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":
            return "iPhone X"
        case "iPhone11,8":
            return "iPhone XR"
        case "iPhone11,2":
            return "iPhone XS"
        case "iPhone11,4", "iPhone11,6":
            return "iPhone XS Max"
        case "iPhone12,1":
            return "iPhone 11"
        case "iPhone12,3":
            return "iPhone 11 Pro"
        case "iPhone12,5":
            return "iPhone 11 Pro Max"
        case "iPhone12,8":
            return "iPhone SE (2nd generation)"
        case "iPhone13,1":
            return "iPhone 12 mini"
        case "iPhone13,2":
            return "iPhone 12"
        case "iPhone13,3":
            return "iPhone 12 Pro"
        case "iPhone13,4":
            return "iPhone 12 Pro Max"
        case "iPad1,1":
            return "iPad (1st generation)"
        case "iPad2,1", "iPad2,4", "iPad2,2", "iPad2,3":
            return "iPad 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":
            return "iPad mini"
        case "iPad3,1", "iPad3,2", "iPad3,3":
            return "iPad (3rd generation) (The new iPad)"
        case "iPad3,4", "iPad3,5", "iPad3,6":
            return "iPad (4th generation) (iPad with Retina display)"
        case "iPad4,1", "iPad4,2", "iPad4,3":
            return "iPad Air (1st generation)"
        case "iPad4,4", "iPad4,5", "iPad4,6":
            return "iPad mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":
            return "iPad mini 3"
        case "iPad5,1", "iPad5,2":
            return "iPad mini 4"
        case "iPad5,3", "iPad5,4":
            return "iPad Air 2"
        case "iPad6,3", "iPad6,4":
            return "iPad Pro (9.7-inch)"
        case "iPad6,7", "iPad6,8":
            return "iPad Pro (12.9-inch) (1st generation)"
        case "iPad6,11", "iPad6,12":
            return "iPad (5th generation)"
        case "iPad7,1", "iPad7,2":
            return "iPad Pro (12.9-inch) (2nd generation)"
        case "iPad7,3", "iPad7,4":
            return "iPad Pro (10.5-inch)"
        case "iPad7,5", "iPad7,6":
            return "iPad (6th generation)"
        case "iPad7,11", "iPad7,12":
            return "iPad (7th generation)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":
            return "iPad Pro (11-inch)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":
            return "iPad Pro (12.9-inch) (3rd generation)"
        case "iPad8,9", "iPad8,10":
            return "iPad Pro (11-inch) (2nd generation)"
        case "iPad8,11", "iPad8,12":
            return "iPad Pro (12.9-inch) (4th generation)"
        case "iPad11,1", "iPad11,2":
            return "iPad mini (5th generation)"
        case "iPad11,3", "iPad11,4":
            return "iPad Air (3rd generation)"
        case "iPad11,6", "iPad11,7":
            return "iPad (8th generation)"
        case "iPad13,1", "iPad13,2":
            return "iPad Air (4th generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":
            return "iPad Pro (11-inch) (3rd generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":
            return "iPad Pro (12.9-inch) (5th generation)"
        case "iPhone14,4":
            return "iPhone 13 mini"
        case "iPhone14,5":
            return "iPhone 13"
        case "iPhone14,2":
            return "iPhone 13 Pro"
        case "iPhone14,3":
            return "iPhone 13 Pro Max"
        case "iPad12,2", "iPad12,1":
            return "iPad (9th generation)"
        case "iPad14,2", "iPad14,1":
            return "iPad mini (6th generation)"
        case "iPhone14,6":
            return "iPhone SE (3rd generation)"
        case "iPad13,16", "iPad13,17":
            return "iPad Air (5th generation)"
        case "iPhone14,7":
            return "iPhone 14"
        case "iPhone14,8":
            return "iPhone 14 Plus"
        case "iPhone15,2":
            return "iPhone 14 Pro"
        case "iPhone15,3":
            return "iPhone 14 Pro Max"
        case "iPad13,18", "iPad13,19":
            return "iPad (10th generation)"
        case "iPad14,3_A", "iPad14,3_B", "iPad14,4_A", "iPad14,4_B":
            return "iPad Pro (11-inch) (4th generation)"
        case "iPad14,5_A", "iPad14,5_B", "iPad14,6_A", "iPad14,6_B":
            return "iPad Pro (12.9-inch) (6th generation)"
        case "iPhone15,4":
            return "iPhone 15"
        case "iPhone15,5":
            return "iPhone 15 Plus"
        case "iPhone16,1":
            return "iPhone 15 Pro"
        case "iPhone16,2":
            return "iPhone 15 Pro Max"
        case "iPad14,8", "iPad14,9":
            return "iPad Air (6th generation) (11-inch)"
        case "iPad14,10", "iPad14,11":
            return "iPad Air (6th generation) (13-inch)"
        case "iPad16,3", "iPad16,4":
            return "iPad Pro (M4) (11-inch)"
        case "iPad16,5", "iPad16,6":
            return "iPad Pro (M4) (13-inch)"
        default:
            return "Unknown device"
        }

    }
}
