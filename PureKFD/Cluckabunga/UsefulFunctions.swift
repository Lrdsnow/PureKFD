//
//  UsefulFunctions.swift
//  Chicken Butt
//
//  Created by lemin on 8/2/23.
//

import Foundation
import UIKit

class UsefulFunctions {
    static func addEmptyData(matchingSize: Int, to plist: [String: Any]) throws -> Data {
        var newPlist = plist
        // create the new data
        guard var newData = try? PropertyListSerialization.data(fromPropertyList: newPlist, format: .binary, options: 0) else { throw "Unable to get data" }
        // add data if too small
        // while loop to make data match because recursive function didn't work
        // very slow, will hopefully improve
        if newData.count == matchingSize {
            return newData
        }
        var newDataSize = newData.count
        var added = matchingSize - newDataSize
        if added < 0 {
            added = 1
        }
        var count = 0
        while newDataSize != matchingSize && count < 200 {
            count += 1
            if added < 0 {
                print("LESS THAN 0")
                break
            }
            newPlist.updateValue(String(repeating: "#", count: added), forKey: "MdC")
            do {
                newData = try PropertyListSerialization.data(fromPropertyList: newPlist, format: .binary, options: 0)
            } catch {
                newDataSize = -1
                print("ERROR SERIALIZING DATA")
                break
            }
            newDataSize = newData.count
            if count < 5 {
                // max out this method at 5 if it isn't working
                added += matchingSize - newDataSize
            } else {
                if newDataSize > matchingSize {
                    added -= 1
                } else if newDataSize < matchingSize {
                    added += 1
                }
            }
        }

        return newData
    }
    
    public static func respring() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1) {
            let windows: [UIWindow] = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
            
            for window in windows {
                window.alpha = 0
                window.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        }
        
        animator.addCompletion { _ in
            if UserDefaults.standard.string(forKey: "RespringType") ?? "Frontboard" == "Backboard" {
                //backboard_respring()
            } else {
                //respring()
            }
            
            //sleep(2) // give the springboard some time to restart before exiting
            exit(0)
        }
        
        animator.startAnimation()
    }
    
    public static func getDefaultStr(forKey: String, defaultValue: String = "Visible") -> String {
        let defaults = UserDefaults.standard
        
        return defaults.string(forKey: forKey) ?? defaultValue
    }
}

enum OverwritingFileTypes {
    case springboard
    case cc
    case plist
    case audio
    case region
}
