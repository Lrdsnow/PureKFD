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
            print("Segment not found")
            return nil
        }
        
        let segmentString = String(cleanedInput[segmentRange.lowerBound...])
        guard let nameRange = segmentString.range(of: "Name: '")?.upperBound,
              let endNameRange = segmentString.range(of: "'", range: nameRange..<segmentString.endIndex)?.lowerBound else {
            print("Name not found")
            return nil
        }
        let name = String(segmentString[nameRange..<endNameRange])
        
        let identifiers = extractAttributes(from: segmentString, attribute: "Identifier")
        let values = extractAttributes(from: segmentString, attribute: "Value")
        
        print(name,  identifiers, values)
        
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
            print("Invalid regex pattern for \(attribute)")
        }
        return attributes
    }
    
    public static func parseAppUUID(_ input: String) -> (appIdentifier: String, data: String)? {
        // Trim the input
        let cleanedInput = input.trimmingCharacters(in: CharacterSet(charactersIn: "%"))
        
        // Ensure the "AppUUID{" exists
        guard let appUUIDRange = cleanedInput.range(of: "AppUUID{'") else {
            log("AppUUID not found")
            return nil
        }
        
        // Extract everything after "AppUUID{'"
        let appUUIDString = String(cleanedInput[appUUIDRange.upperBound...])
        
        // Find the closing quote of the first string (the app identifier)
        guard let endAppIdentifierRange = appUUIDString.range(of: "'")?.lowerBound else {
            log("App Identifier not found")
            return nil
        }
        
        // Extract the app identifier
        let appIdentifier = String(appUUIDString[..<endAppIdentifierRange])
        
        // Move past the first string to find the second string (data)
        let remainingString = appUUIDString[endAppIdentifierRange...].dropFirst(3) // Skip "', '"
        
        // Extract the data
        let data = remainingString.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "}", with: "")
        
        log("\(appIdentifier) \(data)")
        return (appIdentifier, data)
    }
    
    public static func processPath(_ url: URL, _ pkgpath: URL, _ exploit: Int = 0) -> (from: URL?, toPath: String)? {
        var path = url.path
        var from: URL? = nil
        
        let pathComponents = url.pathComponents
        
        var save: [String:Any] = [:]
        if let save_data = try? Data(contentsOf: pkgpath.appendingPathComponent("save.json")),
           let _save = try? JSONSerialization.jsonObject(with: save_data) as? [String:Any] {
            save = _save
        }
        
        for component in pathComponents {
            if component.contains("Segment"),
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
            } else if component.contains("AppUUID") {
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

