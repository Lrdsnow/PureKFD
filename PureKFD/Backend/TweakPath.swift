//
//  TweakPath.swift
//  purebox
//
//  Created by Lrdsnow on 9/12/24.
//

import Foundation

class TweakPath {
    
    public static func parseSegment(_ input: String) -> (name: String, identifiers: [String], values: [String])? {
        let cleanedInput = input.trimmingCharacters(in: CharacterSet(charactersIn: "%"))
        guard let segmentRange = cleanedInput.range(of: "Segment") else {
            log("[!] Segment not found in string: \(input)")
            return nil
        }
        
        let segmentString = String(cleanedInput[segmentRange.lowerBound...])
        guard let nameRange = segmentString.range(of: "Name: '")?.upperBound,
              let endNameRange = segmentString.range(of: "'", range: nameRange..<segmentString.endIndex)?.lowerBound else {
            log("[!] Name not found in string: \(input)")
            return nil
        }
        let name = String(segmentString[nameRange..<endNameRange])
        
        let identifiers = extractAttributes(from: segmentString, attribute: "Identifier")
        let values = extractAttributes(from: segmentString, attribute: "Value")
        
        return (name, identifiers, values)
    }
    
    public static func extractAttributes(from text: String, attribute: String) -> [String] {
        var attributes = [String]()
        let pattern = "\(attribute): '([^']*)'"
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    attributes.append(String(text[range]))
                }
            }
        } catch {
            log("[!] Invalid regex pattern for \(attribute)")
        }
        return attributes
    }
    
    public static func parseAppUUID(_ input: String) -> (appIdentifier: String, data: String)? {
        let cleanedInput = input.trimmingCharacters(in: CharacterSet(charactersIn: "%"))
        guard let appUUIDRange = cleanedInput.range(of: "AppUUID{'") else {
            log("[!] AppUUID not found in string: \(input)")
            return nil
        }
        let appUUIDString = String(cleanedInput[appUUIDRange.upperBound...])
        guard let endAppIdentifierRange = appUUIDString.range(of: "'")?.lowerBound else {
            log("[!] App Identifier not found in string: \(input)")
            return nil
        }
        let appIdentifier = String(appUUIDString[..<endAppIdentifierRange])
        let remainingString = appUUIDString[endAppIdentifierRange...].dropFirst(3)
        let data = remainingString.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "}", with: "")
        return (appIdentifier, data)
    }
    
    public static func processPath(_ url: URL, _ pkgpath: URL, _ exploit: Int = 0, _ saveEnv: [String:String] = [:]) -> (from: URL?, toPath: String)? {
        var path = url.path
        var from: URL? = nil
        
        let pathComponents = url.pathComponents
        
        var save: [String:Any] = [:]
        if let save_data = try? Data(contentsOf: pkgpath.appendingPathComponent("save.json")),
           let _save = try? JSONSerialization.jsonObject(with: save_data) as? [String:Any] {
            save = _save
        }
        save.merge(saveEnv.mapValues { $0 as Any }) { (_, new) in new }
        
        for temp_component in pathComponents {
            var component = temp_component
            let pure_plist = component.contains("?pure_plist.")
            let pure_plist_noread = component.contains("?pure_plist_noread.")
            let pure_text = component.contains("?pure_text.")
            if pure_plist || pure_plist_noread {
                component = temp_component.replacingOccurrences(of: "?pure_plist.", with: "").replacingOccurrences(of: "?pure_plist_noread.", with: "")
                path = path.replacingOccurrences(of: "?pure_plist.", with: "").replacingOccurrences(of: "?pure_plist_noread.", with: "")
                let new_from = URL.documents.appendingPathComponent("temp/\(component)")
                var format = PropertyListSerialization.PropertyListFormat.xml
                do {
                    let plistData = try Data(contentsOf: pkgpath.appendingPathComponent("Overwrite/\(url.path.replacingOccurrences(of: "//private/var", with: "var"))"))
                    if var plistObject = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                        plistObject = applySaveToPlist(plistObject, save)
                        if pure_plist {
                            let plistData2 = try Data(contentsOf: URL(fileURLWithPath: url.path.replacingOccurrences(of: "//private/var", with: "/var").replacingOccurrences(of: "?pure_plist.", with: "").replacingOccurrences(of: "?pure_plist_noread.", with: "")))
                            if let plistObject2 = try PropertyListSerialization.propertyList(from: plistData2, options: [], format: &format) as? [String: Any] {
                                let newPlist = mergeDictionaries(plistObject2, with: plistObject)
                                let newData = try PropertyListSerialization.data(fromPropertyList: newPlist, format: format, options: 0)
                                try newData.write(to: new_from)
                                from = new_from
                            }
                        } else {
                            let newData = try PropertyListSerialization.data(fromPropertyList: plistObject, format: format, options: 0)
                            try newData.write(to: new_from)
                            from = new_from
                        }
                    } else {
                        return nil
                    }
                } catch {
                    log("[!] pure_plist error: \(error)")
                    return nil
                }
            } else if pure_text {
                component = temp_component.replacingOccurrences(of: "?pure_text.", with: "")
                path = path.replacingOccurrences(of: "?pure_text.", with: "")
                let new_from = URL.documents.appendingPathComponent("temp/\(component)")
                do {
                    var contents = try String(contentsOf: URL(fileURLWithPath: url.path.replacingOccurrences(of: "//private/var", with: "/var").replacingOccurrences(of: "?pure_text.", with: "")), encoding: .utf8)
                    for key in save.keys {
                        contents = contents.replacingOccurrences(of: key, with: save[key] as? String ?? "")
                    }
                    try contents.write(to: new_from, atomically: true, encoding: .utf8)
                    from = new_from
                } catch {
                    log("[!] pure_text error: \(error)")
                    return nil
                }
            }
            if component.contains("Segment{"),
               let components = parseSegment(component) {
                from = pkgpath.appendingPathComponent("imported/\(components.name)")
                if FileManager.default.fileExists(atPath: from!.path) {
                    path = path.replacingOccurrences(of: component, with: components.name)
                } else {
                    if let variable = save[components.identifiers.first ?? ""],
                       variable as? String == components.values.first {
                        path = path.replacingOccurrences(of: component, with: components.name)
                    } else {
                        return nil
                    }
                }
            } else if component.contains("?pure_binary.") {
                // eta s0n
                return nil
            } else if component.contains("AppUUID{") {
                if let components = parseAppUUID(component),
                   let _path = ExploitHandler.getAppPath(components.appIdentifier, components.data, exploit) {
                    return (nil, _path+(path.components(separatedBy: ".app").last ?? ""))
                } else {
                    return nil
                }
            } else if component.hasPrefix("%"), component.hasSuffix("%") {
                return nil
            }
        }
        
        path = path.replacingOccurrences(of: "%Optional%", with: "")
        
        return (from, path)
    }
    
}

func applySaveToPlist(_ dictionary: [String: Any], _ save: [String:Any]) -> [String: Any] {
    var result = [String: Any]()

    for (key, value) in dictionary {
        if let stringValue = value as? String {
            if save.keys.contains(stringValue) {
                result[key] = save[stringValue] as? String ?? stringValue
            } else {
                result[key] = stringValue
            }
        } else if let boolValue = value as? Bool {
            let keyComponents = key.components(separatedBy: ":")
            if keyComponents.count == 2 {
                if save.keys.contains(keyComponents[1]) {
                    result[keyComponents[0]] = save[keyComponents[1]] as? Bool ?? boolValue
                } else {
                    result[keyComponents[0]] = boolValue
                }
            } else {
                result[key] = boolValue
            }
        } else if let intValue = value as? Int {
            let keyComponents = key.components(separatedBy: ":")
            if keyComponents.count == 2 {
                if save.keys.contains(keyComponents[1]) {
                    result[keyComponents[0]] = save[keyComponents[1]] as? Int ?? intValue
                } else {
                    result[keyComponents[0]] = intValue
                }
            } else {
                result[key] = intValue
            }
        } else if let dataValue = value as? Data {
            let keyComponents = key.components(separatedBy: ":")
            if keyComponents.count == 2 {
                if save.keys.contains(keyComponents[1]) {
                    result[keyComponents[0]] = save[keyComponents[1]] as? Data ?? dataValue
                } else {
                    result[keyComponents[0]] = dataValue
                }
            } else {
                result[key] = dataValue
            }
        } else if let nestedDictionary = value as? [String: Any] {
            result[key] = applySaveToPlist(nestedDictionary, save)
        } else {
            result[key] = value
        }
    }
    
    return result
}

func mergeDictionaries(_ original: [String: Any], with updates: [String: Any]) -> [String: Any] {
    var merged = original
    
    for (key, updateValue) in updates {
        if let updateDict = updateValue as? [String: Any], let originalDict = original[key] as? [String: Any] {
            // Recursively merge dictionaries
            merged[key] = mergeDictionaries(originalDict, with: updateDict)
        } else {
            // Overwrite with new value
            merged[key] = updateValue
        }
    }
    
    return merged
}
