//
//  TweakTranslate.swift
//  purebox
//
//  Created by Lrdsnow on 9/13/24.
//

import Foundation

@discardableResult
func quickConvertLegacyTweak(pkg: Package) -> String? {
    let fm = FileManager.default
    do {
        if let json = try JSONSerialization.jsonObject(with: Data(contentsOf: pkg.pkgpath.appendingPathComponent("tweak.json")), options: []) as? [String: Any],
           let operations = json["operations"] as? [[String: Any]] {
            
            var opCount = 0
            
            for operation in operations {
                if let type = operation["type"] as? String, type == "replacing",
                   let replacementFileName = operation["replacementFileName"] as? String,
                   let originPath = operation["originPath"] as? String {
                    
                    let destinationPath = pkg.pkgpath.appendingPathComponent("Overwrite\(originPath)")
                    let destinationDir = destinationPath.deletingLastPathComponent()
                    try? fm.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)
                    try fm.copyItem(at: pkg.pkgpath.appendingPathComponent(replacementFileName), to: destinationPath)
                    opCount += 1
                } else {
                    return "Failed to convert legacy tweak\n(Tweak incompatible)"
                }
            }
            
            if opCount > 0 {
                return nil
            } else {
                return "Failed to convert legacy tweak\n(No operations?)"
            }
        }
        return "Failed to convert legacy tweak\n(No operations?)"
    } catch {
        return "Failed to convert legacy tweak\n(Failed to parse tweak.json)"
    }
}
