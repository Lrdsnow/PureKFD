//
//  StringExtensions.swift
//  purekfd
//
//  Created by Lrdsnow on 6/27/24.
//

import Foundation

// yeah this is a url extension but wtv
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

//extension String: @retroactive Error {}
//extension String: @retroactive LocalizedError {
//    public var errorDescription: String? { return self }
//}

extension String {
    func uppercaseFirstLetter() -> String {
        guard !self.isEmpty else { return self }
        let first = self.prefix(1).uppercased()
        let rest = self.dropFirst()
        return first + rest
    }
    
    func checkFirstCharacterInFile() -> Int {
        if let fileContents = try? String(contentsOfFile: self, encoding: .utf8) {
            if let firstChar = fileContents.first {
                if (firstChar == "[") {
                    return 1
                } else if (firstChar == "{") {
                    return 0
                }
            }
        }
        return -1
    }
}

// Version Compare stuff

func checkWildcard(_ component: String, currentVersion: String) -> Bool {
    if component == "*" {
        return true
    } else if component.hasPrefix("*-") {
        let endVersion = String(component.dropFirst(2))
        return compareVersions(currentVersion, to: endVersion) <= 0
    }
    return false
}

func checkRange(_ component: String, currentVersion: String, currentBuild: String) -> Bool {
    let rangeParts = component.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
    
    if rangeParts.count == 2 {
        let start = rangeParts[0]
        let end = rangeParts[1]
        
        if compareVersions(currentVersion, to: start) >= 0 && compareVersions(currentVersion, to: end) <= 0 {
            return true
        }
    }
    return false
}

func compareVersions(_ version1: String, to version2: String) -> Int {
    let version1Components = version1.split(separator: ".").map { Int($0) ?? 0 }
    let version2Components = version2.split(separator: ".").map { Int($0) ?? 0 }
    
    for i in 0..<max(version1Components.count, version2Components.count) {
        let v1 = i < version1Components.count ? version1Components[i] : 0
        let v2 = i < version2Components.count ? version2Components[i] : 0
        
        if v1 != v2 {
            return v1 < v2 ? -1 : 1
        }
    }
    
    return 0
}

func compareCPURange(cpu: String, startRange: String, endRange: String) -> Bool {
    let cpuType = cpu.prefix(1)
    guard let cpuVersion = Int(cpu.dropFirst(1)) else { return false }
    
    let startType = startRange.prefix(1)
    guard let startVersion = Int(startRange.dropFirst(1)) else { return false }
    
    let endType = endRange.prefix(1)
    guard let endVersion = Int(endRange.dropFirst(1)) else { return false }
    
    if cpuType == startType && cpuType == endType {
        return cpuVersion >= startVersion && cpuVersion <= endVersion
    }
    
    return false
}
