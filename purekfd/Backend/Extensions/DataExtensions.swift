//
//  DataExtensions.swift
//  purekfd
//
//  Created by Lrdsnow on 7/1/24.
//

import Foundation

extension Data {
    init?(hex: String) {
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
        let length = cleanHex.count / 2
        var data = Data(capacity: length)
        
        for i in 0..<length {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: i * 2)
            let end = cleanHex.index(start, offsetBy: 2)
            if let byte = UInt8(cleanHex[start..<end], radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
        }
        
        self = data
    }
    
    func patchData(_ inputData: Data, _ json: [String:Any], _ save: [String:String]) -> Data? {
        var binaryData = inputData
        for (offset, replacement) in json["Overwrite"] as? [String:String] ?? [:] {
            log("OFFSET", offset)
            log("REPLACEMENT", save[replacement]?.replacingOccurrences(of: "#", with: "") ?? "N/A")
            if let offset = Int(offset), let replacementData = Data(hex: save[replacement]?.replacingOccurrences(of: "#", with: "") as? String ?? "") {
                binaryData.replaceSubrange(offset..<offset + replacementData.count, with: replacementData)
            }
        }
        return binaryData
    }
}
