//
//  OtherModsManager.swift
//  Chicken Butt
//
//  Created by lemin on 8/3/23.
//

import Foundation

class OtherModsManager {
    public static func changeDictValue(_ dict: [String: Any], _ key: String, _ value: Int) -> [String: Any] {
        var newDict = dict
        for (k, v) in dict {
            if k == key {
                newDict[k] = value
            } else if let subDict = v as? [String: Any] {
                newDict[k] = changeDictValue(subDict, key, value)
            }
        }
        return newDict
    }
    
    public static func applyDeviceSubtype(newSubType: Int) throws {
        DynamicKFD(Int32(newSubType))
    }
}
