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
        let cleanedInput = input.trimmingCharacters(in: CharacterSet(charactersIn: "%"))
        guard let appUUIDRange = cleanedInput.range(of: "AppUUID{") else {
            print("AppUUID not found")
            return nil
        }
        
        let appUUIDString = String(cleanedInput[appUUIDRange.upperBound...])
        
        guard let appIdentifierRange = appUUIDString.range(of: "'")?.upperBound,
              let endAppIdentifierRange = appUUIDString.range(of: "'", range: appIdentifierRange..<appUUIDString.endIndex)?.lowerBound else {
            print("App Identifier not found")
            return nil
        }
        let appIdentifier = String(appUUIDString[appIdentifierRange..<endAppIdentifierRange])
        
        guard let dataRange = appUUIDString.range(of: "'", range: endAppIdentifierRange..<appUUIDString.endIndex)?.upperBound,
              let endDataRange = appUUIDString.range(of: "'", range: dataRange..<appUUIDString.endIndex)?.lowerBound else {
            print("Data not found")
            return nil
        }
        let data = String(appUUIDString[dataRange..<endDataRange])
        
        print(appIdentifier, data)
        return (appIdentifier, data)
    }
    
    public static func processPath(_ url: URL, _ pkgpath: URL) -> (from: URL?, toPath: String)? {
        var path = url.path
        var from: URL? = nil
        
        let pathComponents = url.pathComponents
        
        for component in pathComponents {
            if component.contains("Segment"),
               let components = parseSegment(component) {
                from = pkgpath.appendingPathComponent("imported/\(components.name)")
                if FileManager.default.fileExists(atPath: from!.path) {
                    path = path.replacingOccurrences(of: component, with: components.name)
                } else {
                    return nil
                }
            } else if component.contains("?pure_binary.") {
                // eta s0n
                return nil
            } else if component.contains("AppUUID") {
                // eta s0n
                return nil
            } else if component.hasPrefix("%"), component.hasSuffix("%") {
                return nil
            }
        }
        
        path = path.replacingOccurrences(of: "%Optional%", with: "")
        
        return (from, path)
    }
    
}

