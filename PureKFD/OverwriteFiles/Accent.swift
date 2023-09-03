//
//  Accent.swift
//  PurityKFD
//
//  Created by Lrdsnow on 8/21/23.
//

import Foundation
import SwiftUI

struct ColorData: Codable {
    let keyName: String
    let hexColorValue: String
    let startingOffset: Int
}

func modifyCARFile(filePath: String, startingOffset: Int, newColorValue: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: filePath))
    
    // Convert hex color value to bytes
    guard let newColorData = newColorValue.hexadecimalData else {
        throw NSError(domain: "InvalidHexColorValue", code: 0, userInfo: nil)
    }
    
    // Replace bytes in data
    let range = startingOffset..<startingOffset + newColorData.count
    data.replaceSubrange(range, with: newColorData)
    
    // Write modified data back to file
    try overwriteFile(at: String(URL(fileURLWithPath: filePath).absoluteString.dropFirst(7)), with: data)
    
    print("Color modified successfully.")
}

func modifyColorsInCARFile(jsonData: [String: Any], carFilePath: String, newColorValue: Color) {
    do {
        guard let data = jsonData["data"] as? [[String: Any]] else {
            print("Error: Invalid JSON data format")
            return
        }
        
        var modifications: [(String, [(Int, String)])] = []
        
        for colorData in data {
            if let startingOffsetStr = colorData["startingOffset"] as? String,
               let hexColorValue = colorData["hexColorValue"] as? String,
               let startingOffset = Int(startingOffsetStr) {
                let filePath = colorData["filePath"] as? String ?? carFilePath
                if let index = modifications.firstIndex(where: { $0.0 == filePath }) {
                    modifications[index].1.append((startingOffset, hexColorValue))
                } else {
                    modifications.append((filePath, [(startingOffset, hexColorValue)]))
                }
            }
        }
        
        for (filePath, batch) in modifications {
            var data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            for (offset, hexValue) in batch {
                guard let newColorData = hexValue.hexadecimalData else {
                    print("Invalid hex color value")
                    continue
                }
                let range = offset..<offset + newColorData.count
                data.replaceSubrange(range, with: newColorData)
            }
            try overwriteFile(at: String(URL(fileURLWithPath: filePath).absoluteString.dropFirst(7)), with: data)
        }
        
        print("Colors modified successfully.")
    } catch {
        print("Error: \(error)")
    }
}
