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

@discardableResult
func quickConvertLegacyOverwriteTweak(pkg: Package) -> String? {
    let url = pkg.pkgpath.appendingPathComponent("Overwrite")
    return searchFilesInFolder(url)
}

func searchFilesInFolder(_ url: URL) -> String? {
    let searchPattern = "%*Overwrite%"
    let fileManager = FileManager.default
    let regexPattern = searchPattern.replacingOccurrences(of: "%", with: ".*").replacingOccurrences(of: "*", with: ".*")
    guard fileManager.fileExists(atPath: url.path, isDirectory: nil) else {
        return "The provided path is not a valid directory."
    }
    
    do {
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey], options: [])

        for fileURL in contents {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .typeIdentifierKey])

            if resourceValues.isDirectory == true {
                return searchFilesInFolder(fileURL)
            } else if let typeIdentifier = resourceValues.typeIdentifier {
                if typeIdentifier == "com.apple.property-list" || fileURL.lastPathComponent.contains(".plist") {
                    if let plistData = try? Data(contentsOf: fileURL) {
                        if var plistObject = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) {
                            if var dictionary = plistObject as? [String: Any] {
                                let regex = try? NSRegularExpression(pattern: regexPattern, options: [])
                                let keysToRemove = dictionary.keys.filter { key in
                                    return regex?.firstMatch(in: key, options: [], range: NSRange(location: 0, length: key.utf16.count)) != nil
                                }
                                
                                keysToRemove.forEach { dictionary.removeValue(forKey: $0) }

                                let modifiedPlistObject: Any = dictionary
                                if let newData = try? PropertyListSerialization.data(fromPropertyList: modifiedPlistObject, format: .xml, options: 0) {
                                    try newData.write(to: fileURL)
                                    try fileManager.moveItem(at: fileURL, to: fileURL.deletingLastPathComponent().appendingPathComponent("?pure_plist.\(fileURL.lastPathComponent)"))
                                }
                            }
                        }
                    }
                } else {
                    print("Skipping file \(fileURL.path) of type \(typeIdentifier)")
                }
            }
        }
    } catch {
        return "Error while accessing the directory: \(error)"
    }
    return nil
}


func findTweakFolder(in directory: URL) -> URL? {
    let fileManager = FileManager.default
    guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
        return nil
    }
    for item in contents {
        if item.lastPathComponent == "tweak.json" || item.lastPathComponent == "Overwrite" {
            return directory
        }
    }
    for item in contents {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory), isDirectory.boolValue {
            if let foundDirectory = findTweakFolder(in: item) {
                return foundDirectory
            }
        }
    }
    
    return nil
}
