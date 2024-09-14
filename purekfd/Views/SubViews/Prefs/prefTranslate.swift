//
//  prefTranslate.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/21/23.
//
//  WARNING: the code here is very bad
//

import Foundation

func translatePicassoPrefs(picassoData: [String: [[String: Any]]]) -> [[String: Any]]? {
    var PureKFDData: [[String: Any]] = []

    if let preferences = picassoData["preferences"] {
        for pref in preferences {
            if let valueType = pref["valueType"] as? String,
               let key = pref["key"] as? String,
               let title = pref["title"] as? String {
                var item: [String: Any] = [:]
                switch valueType {
                case "color":
                    item[title + ":colorpicker"] = key
                case "string":
                    item[title + ":string"] = key
                case "double":
                    item[title + ":double"] = key
                case "int":
                    item[title + ":int"] = key
                case "bool":
                    item[title + ":bool"] = key
                default:
                    break
                }
                PureKFDData.append(item)
            }
        }
    }

    return PureKFDData
}

func translateLegacyEncryptedPrefsTweaks(_ tweaks: [[String: Any]], hidertoggle: Bool = false) -> [[String: Any]] {
    var result: [[String:Any]] = []

    NSLog("%@", "\(tweaks)")
    for tweak in tweaks {
        var resultDict: [String: Any] = [:]
        if let hide = tweak["Hide"] as? Int { if !hidertoggle { break } }
        if let ui = tweak["UI"] as? String {
            switch ui {
            case "Text":
                if let labelText = tweak["Label"] as? String {
                    resultDict["\(labelText):label"] = ""
                }
            case "ImagePicker":
                if let label = tweak["Label"] as? String,
                   let url = tweak["URL"] as? String {
                    resultDict["\(label):imagepicker"] = [url]
                }
            case "FilePicker":
                if let label = tweak["Label"] as? String,
                   let url = tweak["URL"] as? String {
                    resultDict["\(label):filepicker"] = [url]
                }
            case "NavigationLink":
                if let labelText = tweak["Label"] as? String,
                   let categories = tweak["Categories"] as? [[String: Any]] {
                    let categoryContents = translateLegacyEncryptedPrefsTweaks(categories)
                    let key = "\(labelText):navlink"
                    resultDict[key] = categoryContents
                }
            case "Link":
                if let labelText = tweak["Label"] as? String,
                   let url = tweak["URL"] as? String {
                    resultDict["\(labelText):link"] = url
                }
            case "Image":
                if let url = tweak["URL"] as? String {
                    resultDict["\(UUID()):image"] = url
                }
            case "Toggle":
                if let labelText = tweak["Label"] as? String,
                   let identifier = tweak["Identifier"] as? String {
                    resultDict["\(labelText):toggle"] = identifier
                }
            case "SegmentedControl", "Picker":
                if var labelText = tweak["Label"] as? String,
                   let selection = tweak["Selection"] as? [[String: Any]],
                   let identifier = tweak["Identifier"] as? String {
                    var segments: [[String:String]] = []
                    for sel in selection {
                        segments.append([
                            "label":sel["Label"] as? String ?? "",
                            "value":sel["Value"] as? String ?? ""
                        ])
                    }
                    let key = "\(labelText):picker"
                    resultDict[key] = [identifier, segments]
                }
            case "Hider_Toggle", "Enabler_Toggle":
                if let variableToSaveAs = "hidertoggle" as? String,
                   let labelText = tweak["Label"] as? String,
                   let states = tweak["Identifiers"] as? [String: Any] {
                    NSLog("%@", "\(tweak)")
                    let enableTweaks = states["To_Disable"] as? [String] ?? []
                    let disableTweaks = states["To_Enable"] as? [String] ?? []
                    var hiddenTweaks: [String: Any] = [:]
                    hiddenTweaks["true"] = [:]
                    hiddenTweaks["false"] = [:]
                    for tweak in tweaks {
                        NSLog("%@", "\(tweak)")
                        if let hidden = tweak["Hide"] as? Int,
                           let identifier = tweak["Identifier"] as? String {
                            if disableTweaks.contains(identifier) {
                                hiddenTweaks["false"] = translateLegacyEncryptedPrefsTweaks([tweak], hidertoggle: true)
                            }
                            if enableTweaks.contains(identifier) {
                                hiddenTweaks["true"] = translateLegacyEncryptedPrefsTweaks([tweak], hidertoggle: true)
                            }
                        }
                    }
                    NSLog("%@", "\(hiddenTweaks)")
                    resultDict["\(labelText):hidertoggle"] = ["\(tweak["Identifier"] ?? UUID())", hiddenTweaks]
                }
            default:
                resultDict["\(UUID()):\(ui)"] = "\(UUID())"
                break
            }
        } else {
            if let type = tweak["Type"] as? String {
                NSLog("\n\n\(type)\n\n")
                switch type {
                case "Color_Hex":
                    if let identifier = tweak["Identifier"] as? String,
                       let labelText = tweak["Label"] as? String {
                        resultDict["\(labelText):colorpicker"] = identifier
                    }
                case "String":
                    if let identifier = tweak["Identifier"] as? String,
                       let labelText = tweak["Label"] as? String {
                        resultDict["\(labelText):string"] = identifier
                    }
                case "Int":
                    if let labelText = tweak["Label"] as? String,
                       let identifier = tweak["Identifier"] as? String {
                        resultDict["\(labelText):intpad"] = identifier
                    }
                default:
                    if tweak["UI"] == nil {
                        resultDict["\(UUID()):\(type)"] = "\(UUID())"
                        break
                    }
                }
            }
        }
        if let label = tweak["Category"] as? String,
           let tweaks = tweak["Tweaks"] as? [[String: Any]] {
            let categoryContents = translateLegacyEncryptedPrefsTweaks(tweaks)
            let key = "\(label):section"
            resultDict[key] = categoryContents
        }
        result.append(resultDict)
    }
    
    NSLog("%@", "\(result)")

    return result
}

func translateLegacyEncryptedPrefs(plistData: Data) -> [[String: Any]]? {
    do {
        if let plistArray = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [[String: Any]] {

            var jsonItems: [[String: Any]] = []

            for item in plistArray {
                if let category = item["Category"] as? String,
                   let tweaks = item["Tweaks"] as? [[String: Any]] {
                    let categoryPrefix = !category.isEmpty ? "\(category):" : ""
                    let categoryContents = translateLegacyEncryptedPrefsTweaks(tweaks)
                    if let desc = item["Description"] as? String {
                        jsonItems.append(["\(category):section":[desc, categoryContents]])
                    } else {
                        jsonItems.append(["\(category):section":categoryContents])
                    }
                }
            }
            
            return jsonItems
        }
    } catch {
        NSLog("Error converting plist to JSON: \(error)")
    }

    return nil
}

func translateLegacyPureKFDPrefs(json: String) -> [[String:Any]] {
    var result: [[String:Any]] = []
    if let jsonData = json.data(using: .utf8),
       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
       let config = jsonObject as? [String: Any] {
        func translateBit(config: [String:Any]) -> [[String:Any]] {
            var result: [[String:Any]] = []
            
            let sortedKeys = config.keys.sorted { (key1, key2) -> Bool in
                if let index1 = json.range(of: key1)?.lowerBound,
                   let index2 = json.range(of: key2)?.lowerBound {
                    return index1 < index2
                }
                return false
            }
            
            for key in sortedKeys {
                var _data = config[key]
                if let data = _data as? [String:Any] {
                    _data=translateBit(config: data)
                }
                result.append([key:_data])
            }
            return result
        }
        
        return translateBit(config: config)
    }
    return []
}

@discardableResult
func quickConvertLegacyPKFD(pkg_dir: URL, configJsonPath: String) -> String? {
    let fm = FileManager.default
    let legacyConfigJsonPath = pkg_dir.appendingPathComponent("config.json").path
    if fm.fileExists(atPath: legacyConfigJsonPath) {
        if let jsonData = fm.contents(atPath: legacyConfigJsonPath) {
            do {
                if let legacyPureKFDData = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any] {
                    let translatedPrefs = translateLegacyPureKFDPrefs(json: try String(contentsOfFile: legacyConfigJsonPath, encoding: .utf8))
                    let configData = try JSONSerialization.data(withJSONObject: translatedPrefs, options: .prettyPrinted)
                    try? fm.removeItem(atPath: configJsonPath)
                    fm.createFile(atPath: configJsonPath, contents: configData, attributes: nil)
                    return nil
                } else {
                    return "Failed to decode tweak settings\n(Invalid JSON format in config.json)"
                }
            } catch {
                return "Failed to decode tweak settings\n(Failed to load or parse config.json: \(error.localizedDescription))"
            }
        } else {
            return "Failed to decode tweak settings\n(Failed to load config.json data)"
        }
    } else {
        return "Failed to decode tweak settings\n(config.json does not exist)"
    }
}

@discardableResult
func quickConvertPicasso(pkg_dir: URL, configJsonPath: String) -> String? {
    let fm = FileManager.default
    let prefsJsonPath = pkg_dir.appendingPathComponent("prefs.json").path
    try? fm.removeItem(atPath: configJsonPath)
    if fm.fileExists(atPath: prefsJsonPath) {
        if let jsonData = fm.contents(atPath: prefsJsonPath) {
            do {
                if let picassoData = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [[String: Any]]] {
                    if let translatedPrefs = translatePicassoPrefs(picassoData: picassoData) {
                        let configData = try JSONSerialization.data(withJSONObject: translatedPrefs, options: .prettyPrinted)
                        fm.createFile(atPath: configJsonPath, contents: configData, attributes: nil)
                        return nil
                    } else {
                        return "Failed to decode tweak settings\n(Failed to translate Picasso preferences)"
                    }
                } else {
                    return "Failed to decode tweak settings\n(Invalid JSON format in prefs.json)"
                }
            } catch {
                return "Failed to decode tweak settings\n(Failed to load or parse prefs.json: \(error.localizedDescription))"
            }
        } else {
            return "Failed to decode tweak settings\n(Failed to load prefs.json data)"
        }
    } else {
        return "Failed to decode tweak settings\n(prefs.json does not exist)"
    }
}

@discardableResult
func quickConvertLegacyEncrypted(pkg_dir: URL, configJsonPath: String) -> String? {
    let fm = FileManager.default
    let configPlistPath = pkg_dir.appendingPathComponent("config.plist").path
    try? fm.removeItem(atPath: configJsonPath)
    if fm.fileExists(atPath: configPlistPath) {
        if let plistData = fm.contents(atPath: configPlistPath) {
            do {
                let jsonPrefs = translateLegacyEncryptedPrefs(plistData: plistData)
                let jsonData = try JSONSerialization.data(withJSONObject: jsonPrefs ?? [], options: .prettyPrinted)
                fm.createFile(atPath: configJsonPath, contents: jsonData, attributes: nil)
                return nil
            } catch {
                return "Failed to decode tweak settings\n(Failed to translate or save preferences: \(error.localizedDescription))"
            }
        } else {
            return "Failed to decode tweak settings\n(Failed to load config.plist data)"
        }
    } else {
        return "Failed to decode tweak settings\n(config.plist does not exist)"
    }
}
