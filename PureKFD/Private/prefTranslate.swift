//
//  prefTranslate.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/21/23.
//

import Foundation

func translatePicassoPrefs(picassoData: [String: [[String: Any]]]) -> [String: Any]? {
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

    // Ensure the dictionaries maintain the same order as the array
    let orderedKeys = PureKFDData.map { dictionary in
        return dictionary.keys.first ?? ""
    }

    var finalDictionary: [String: Any] = [:]

    for key in orderedKeys {
        if let itemToMerge = PureKFDData.first(where: { $0.keys.first == key }) {
            finalDictionary.merge(itemToMerge) { (_, new) in new }
        }
    }

    return finalDictionary
}

func translateMisakaPrefsTweaks(_ tweaks: [[String: Any]], hidertoggle: Bool = false) -> [String: Any] {
    var resultDict: [String: Any] = [:]

    print(tweaks)
    for tweak in tweaks {
        if let hide = tweak["Hide"] as? Int { if !hidertoggle { break } }
        if let ui = tweak["UI"] as? String {
            switch ui {
            case "Text":
                if let labelText = tweak["Label"] as? String {
                    resultDict["\(labelText):label"] = ""
                }
//            case "ImagePicker":
//                if let label = tweak["Label"] as? String,
//                   let url = tweak["URL"] as? String,
//                   let v = tweak["Identifier"] as? String {
//                    resultDict["\(label):imagepicker"] = [v, url]
//                }
//            case "FilePicker":
//                if let label = tweak["Label"] as? String,
//                   let url = tweak["URL"] as? String,
//                   let v = tweak["Identifier"] as? String {
//                    resultDict["\(label):filepicker"] = [v, url]
//                }
            case "NavigationLink":
                if let labelText = tweak["Label"] as? String,
                   let categories = tweak["Categories"] as? [[String: Any]] {
                    let categoryContents = translateMisakaPrefsTweaks(categories)
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
            case "SegmentedControl":
                if var labelText = tweak["Label"] as? String,
                   let selection = tweak["Selection"] as? [[String: Any]],
                   let identifier = tweak["Identifier"] as? String {
                    var segments: [String:String] = [:]
                    for sel in selection {
                        segments[sel["Label"] as? String ?? ""] = sel["Value"] as? String ?? ""
                    }
                    let key = "\(labelText):segmentpicker"
                    resultDict[key] = [identifier, segments]
                }
            case "Hider_Toggle", "Enabler_Toggle":
                if let variableToSaveAs = "hidertoggle" as? String,
                   let labelText = tweak["Label"] as? String,
                   let states = tweak["Identifiers"] as? [String: Any] {
                    print(tweak)
                    let enableTweaks = states["To_Disable"] as? [String] ?? []
                    let disableTweaks = states["To_Enable"] as? [String] ?? []
                    var hiddenTweaks: [String: Any] = [:]
                    hiddenTweaks["true"] = [:]
                    hiddenTweaks["false"] = [:]
                    for tweak in tweaks {
                        print(tweak)
                        if let hidden = tweak["Hide"] as? Int,
                           let identifier = tweak["Identifier"] as? String {
                            if disableTweaks.contains(identifier) {
                                hiddenTweaks["false"] = translateMisakaPrefsTweaks([tweak], hidertoggle: true)
                            }
                            if enableTweaks.contains(identifier) {
                                hiddenTweaks["true"] = translateMisakaPrefsTweaks([tweak], hidertoggle: true)
                            }
                        }
                    }
                    print(hiddenTweaks)
                    resultDict["\(labelText):hidertoggle"] = ["\(tweak["Identifier"] ?? UUID())", hiddenTweaks]
                }
            default:
                resultDict["\(UUID()):\(ui)"] = "\(UUID())"
                break
            }
        } else {
            if let type = tweak["Type"] as? String {
                print("\n\n\(type)\n\n")
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
            let categoryContents = translateMisakaPrefsTweaks(tweaks)
            let key = "\(label):section"
            resultDict[key] = categoryContents
        }
    }
    
    print(resultDict)

    return resultDict
}

func translateMisakaPrefs(plistData: Data) -> [String: Any]? {
    do {
        if let plistArray = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [[String: Any]] {
            let sortedPlistArray = plistArray.sorted { (dict1, dict2) -> Bool in
                if let id1 = dict1["ID"] as? Int, let id2 = dict2["ID"] as? Int {
                    return id1 < id2
                }
                return false
            }

            var jsonItems: [[String: Any]] = []

            for item in sortedPlistArray {
                if let category = item["Category"] as? String,
                   let tweaks = item["Tweaks"] as? [[String: Any]] {
                    let categoryPrefix = !category.isEmpty ? "\(category):" : ""
                    let categoryContents = translateMisakaPrefsTweaks(tweaks)
                    if let desc = item["Description"] as? String {
                        jsonItems.append(["\(category):section":[desc, categoryContents]])
                    } else {
                        jsonItems.append(["\(category):section":categoryContents])
                    }
                }
            }
            
            var jsonDict: [String: Any] = [:]
            for item in jsonItems {
                jsonDict.merge(item) { (_, new) in new }
            }

            return jsonDict
        }
    } catch {
        print("Error converting plist to JSON: \(error)")
    }

    return nil
}
