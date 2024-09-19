//
//  DeviceInfo.swift
//  purekfd
//
//  Created by Lrdsnow on 9/1/24.
//

import Foundation
import AppKit

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
            let systemVersion = ProcessInfo().operatingSystemVersion
            return "\(systemVersion.majorVersion).\(systemVersion.minorVersion)"
        }
    }
    
    static var modelName: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        
        var modelIdentifier: [CChar] = Array(repeating: 0, count: size)
        sysctlbyname("hw.model", &modelIdentifier, &size, nil, 0)
        
        return String(cString: modelIdentifier)
    }
    
    static var osString: String {
        get {
            return "macOS"
        }
    }
    
    static var ipad: Bool {
        return true
    }
    
    let CPU_ARCH_MASK          = 0xff
    let CPU_TYPE_X86           = cpu_type_t(7)
    let CPU_TYPE_ARM           = cpu_type_t(12)
    
    static var cpu: String {
        return utsname.sMachine
    }
}

extension utsname {
    static var sMachine: String {
        var utsname = utsname()
        uname(&utsname)
        return withUnsafePointer(to: &utsname.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
    }
    static var isAppleSilicon: Bool {
        sMachine == "arm64"
    }
}
