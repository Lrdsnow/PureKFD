//
//  OtherExtensions.swift
//  purebox
//
//  Created by Lrdsnow on 9/16/24.
//

import Foundation

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

