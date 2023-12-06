//
//  purePrefs.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/11/23.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

@available(iOS 15.0, *)
struct PrefView: View {
    let pkg: Package
    var body: some View {
        let pkgpath: URL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("installed/\(pkg.bundleID)"))!
        if FileManager.default.fileExists(atPath: pkgpath.appendingPathComponent("config.json").path) {
            let jsonString = String(data: FileManager.default.contents(atPath: pkgpath.appendingPathComponent("config.json").path) ?? Data(), encoding: .utf8) ?? ""
            FullPrefView(json: jsonString, pkgpath: pkgpath.path)
        } else if FileManager.default.fileExists(atPath: pkgpath.appendingPathComponent("config.plist").path) {
            let plistPath = pkgpath.appendingPathComponent("config.plist").path
            if let plistData = FileManager.default.contents(atPath: plistPath),
               let jsonDictionary = translateMisakaPrefs(plistData: plistData),
               let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                FullPrefView(json: jsonString, pkgpath: pkgpath.path)
            }
        } else if FileManager.default.fileExists(atPath: pkgpath.appendingPathComponent("prefs.json").path) {
            let plistPath = pkgpath.appendingPathComponent("prefs.json").path
            if let picassoPrefData = FileManager.default.contents(atPath: plistPath),
               let picassoPrefDict = try? JSONSerialization.jsonObject(with: picassoPrefData, options: []),
               let jsonDictionary = translatePicassoPrefs(picassoData: picassoPrefDict as? [String : [[String : Any]]] ?? [:]),
               let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                FullPrefView(json: jsonString, pkgpath: pkgpath.path)
            }
        } else {
            Text("Unsupported Prefs")
        }
    }
}

@available(iOS 15.0, *)
struct FullPrefView: View {
    @State private var savejson: String = ""
    @State var json: String
    @State var pkgpath: String

    @State private var variables: [String: Any] = [:]
    @State private var randomvariables: [String: Any] = [:]
    
    init(json: String, pkgpath: String) {
        self._json = State(initialValue: json)
        self._pkgpath = State(initialValue: pkgpath)
            
        // Load data from save.json
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: pkgpath+"/save.json")),
            let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
            let savedVariables = jsonObject as? [String: Any] {
            self._variables = State(initialValue: savedVariables)
        }
    }
    
    var body: some View {
            if let jsonData = json.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
               let config = jsonObject as? [String: Any] {
                List {
                    generateView(from: config)
                }.listStyle(.insetGrouped)
                    .background(Color(UIColor.systemBackground))
                    .navigationBarTitle("Preferences")
            }
    }

    func generateView(from config: [String: Any]) -> some View {
        var views: [AnyView] = []
        
        let sortedKeys = config.keys.sorted { (key1, key2) -> Bool in
            if let index1 = json.range(of: key1)?.lowerBound,
            let index2 = json.range(of: key2)?.lowerBound {
                return index1 < index2
            }
            return false
        }
        
        for key in sortedKeys {
            if let value = config[key] {
                let label = String(key.split(separator: ":").first ?? "")
                let type = String(key.split(separator: ":").last ?? "")
                if type == "image" {
                    if let url = value as? String, let imageURL = URL(string: url) {
                        views.append(AnyView(WebImage(url: imageURL).resizable().scaledToFit().cornerRadius(10)))
                    }
                } else if type == "label" {
                    views.append(AnyView(Text(label).font(.body).if((value as? String)?.toColor() != nil){view in view.foregroundStyle((value as? String ?? "").toColor() ?? Color.white)}))
                } else if type == "string" {
                    views.append(contentsOf: generateTextInput(label: label, key: key, variable: value as? String ?? ""))
                } else if type == "intpad" {
                    views.append(contentsOf: generateIntPadInput(label: label, key: key, variable: value as? String ?? ""))
                } else if type == "link" {
                    views.append(AnyView(Link(destination: URL(string: value as! String) ?? URL(string: "https://example.com")!, label: {Text(label ).brightness(0.3)})))
                } else if type == "imagepicker" {
                    views.append(contentsOf: generateImagePicker(label: label, key: key, variable: value as? String ?? ""))
                } else if type == "filepicker" {
                    views.append(contentsOf: generateFilePicker(label: label, key: key, variable: value as? String ?? ""))
                } else if type == "toggle" {
                    views.append(contentsOf: generateToggle(label: label, key: key, variable: value as? String ?? ""))
                } else if type == "colorpicker" {
                    views.append(contentsOf: generateColorPicker(label: label, key: key, variable: value as? String ?? ""))
                } else if type == "int" {
                    views.append(contentsOf: generateIntInput(label: label, key: key, variable: value as? String ?? ""))
                } else if type == "double" {
                    views.append(contentsOf: generateDoubleInput(label: label, key: key, variable: value as? String ?? ""))
                } else if let array = value as? [Any] {
                    print(key)
                    if type == "hidertoggle" {
                        views.append(contentsOf: generateHiderToggle(key: key, label: label, array: array))
                    } else if type == "picker" {
                        views.append(contentsOf: generatePicker(key: key, label: label, array: array))
                    } else if type == "segmentpicker" {
                        views.append(contentsOf: generateSegmentPicker(key: key, label: label, array: array))
                    } else if type == "segment" {
                        views.append(contentsOf: generateSegment(label: label, key: key, array: array))
                    } else if type == "section" {
                        views.append(contentsOf: generateSectionWithFooter(label: label, key: key, array: array))
                    }
                } else if let dict = value as? [String: Any] {
                    if type == "navlink" {
                        views.append(contentsOf: generateNavLink(label: label, key: key, dict: dict))
                    } else if type == "section" {
                        views.append(contentsOf: generateSection(label: label, key: key, dict: dict))
                    } else if type == "presets" {
                        views.append(contentsOf: generatePresets(label: label, key: key, dict: dict))
                    }
                } else {
                    views.append(AnyView(Text("Unsupported Pref: \(type)")))
                }
            }
        }

        return ForEach(views.indices, id: \.self) { index in
                views[index].padding(.vertical, 2.5)
        }
    }
    
    func generateHiderToggle(key: String, label: String, array: [Any]) -> [AnyView] {
        var views: [AnyView] = []
        
        views.append(AnyView(
            Toggle(label, isOn: Binding(
                get: {
                    return variables[array[0] as! String] as? Bool ?? false
                },
                set: { newValue in
                    variables[array[0] as! String] = newValue
                    saveVariables()
                }
            ))
        ))

        if let toggleStates = array[1] as? [String: Any] {
            let toggleStateKey = variables[array[0] as! String] as? Bool == true ? "true" : "false"
            if let stateComponents = toggleStates[toggleStateKey] as? [String: Any] {
                let stateView = generateView(from: stateComponents)
                views.append(contentsOf: [
                    AnyView(stateView)
                ])
            }
        }

        return views
    }

    func generateToggle(label: String, key: String, variable: String) -> [AnyView] {
        var views: [AnyView] = []
        views.append(AnyView(
            Toggle(label, isOn: Binding(
                get: {
                    return variables[variable] as? Bool ?? false
                },
                set: { newValue in
                    variables[variable] = newValue
                    saveVariables()
                }
            ))
        ))

        return views
    }

    func generateColorPicker(label: String, key: String, variable: String) -> [AnyView] {
        var views: [AnyView] = []
        
        // Convert the UIColor to Color here
        let initialColor: Color = {
            if let hexColor = variables[variable] as? String,
                let uiColor = UIColor(hex: hexColor) {
                return Color(uiColor)
            }
            return Color.clear
        }()
        
        let colorPickerView = ColorPicker(label, selection: Binding(
            get: {
                if randomvariables[variable] == nil {
                    return initialColor
                } else {
                    return randomvariables[variable] as? Color ?? Color.clear
                }
            },
            set: { newValue in
                randomvariables[variable] = newValue
                variables[variable] = newValue.toHex()
                saveVariables()
            }
        ))
        
        views.append(AnyView(colorPickerView))

        return views
    }

    func generateIntInput(label: String, key: String, variable: String) -> [AnyView] {
        var views: [AnyView] = []
        let intBinding = Binding<Int>(
            get: {
                return $variables.wrappedValue[variable] as? Int ?? 0
            },
            set: { newValue in
                $variables.wrappedValue[variable] = newValue
                saveVariables()
            }
        )
        
        views.append(AnyView(
            Stepper("\(label):\(intBinding.wrappedValue)", value: intBinding)
        ))

        return views
    }

    func generateDoubleInput(label: String, key: String, variable: String) -> [AnyView] {
        var views: [AnyView] = []
        let doubleBinding = Binding<Double>(
            get: {
                return $variables.wrappedValue[variable] as? Double ?? 0.0
            },
            set: { newValue in
                $variables.wrappedValue[variable] = newValue
                saveVariables()
            }
        )
        
        views.append(AnyView(HStack {
            Text("\(label):\(doubleBinding.wrappedValue)")
                .font(.body)
            Slider(value: doubleBinding, in: 0.0...1.0, step: 0.01)
                .frame(width: 200)
        }))
        
        return views
    }

    func generatePicker(key: String, label: String, array: [Any]) -> [AnyView] {
        var views: [AnyView] = []
        
        if let pickerOptions = array[1] as? [String] {
            let initialIndex: Int = {
                if let selectedIndex = variables[array[0] as! String] as? Int {
                    return selectedIndex
                } else {
                    return 0
                }
            }()

            let selectedOptionIndex = Binding<Int>(
                get: {
                    return variables[array[0] as! String] as? Int ?? initialIndex
                },
                set: { newValue in
                    variables[array[0] as! String] = newValue
                    saveVariables()
                }
            )

            views.append(AnyView(
                HStack {
                    Picker(label, selection: selectedOptionIndex) {
                        ForEach(pickerOptions.indices, id: \.self) { index in
                            Text(pickerOptions[index])
                        }
                    }
                }
            ))
        }

        return views
    }
    
    func generateSegmentPicker(key: String, label: String, array: [Any]) -> [AnyView] {
        var views: [AnyView] = []
        
        if let pickerOptionsAndValues = array[safe: 1] as? [String: String] {
            let selectedVariable = variables[array[safe: 0] as? String ?? ""] as? String
            
            let pickerOptions = Array(pickerOptionsAndValues.keys)
            
            let selectedOptionIndex = Binding<Int>(
                get: {
                    let selectedValue = variables[array[safe: 0] as! String] as? String // Cast to String
                    return pickerOptions.firstIndex(of: selectedValue ?? "") ?? 0
                },
                set: { newValue in
                    let stringValue = pickerOptions[newValue]
                    variables[array[safe: 0] as! String] = stringValue
                    saveVariables()
                }
            )
            
            views.append(AnyView(
                HStack {
                    Picker(label, selection: selectedOptionIndex) {
                        ForEach(pickerOptions.indices, id: \.self) { index in
                            Text(pickerOptions[index])
                        }
                    }.pickerStyle(.segmented)
                }
            ))
        }
        
        return views
    }

    func generateTextInput(label: String, key: String, variable: String) -> [AnyView] {
        var views: [AnyView] = []
        views.append(AnyView(
            TextField(label, text: Binding(
                get: {
                    return variables[variable] as? String ?? ""
                },
                set: { newValue in
                    variables[variable] = newValue
                    saveVariables()
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
        ))

        return views
    }
    
    func generateIntPadInput(label: String, key: String, variable: String) -> [AnyView] {
        var views: [AnyView] = []
        views.append(AnyView(
            TextField(label, text: Binding(
                get: {
                    return variables[variable] as? String ?? ""
                },
                set: { newValue in
                    variables[variable] = newValue
                    saveVariables()
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
        ))

        return views
    }
    
    @State private var isShowingImagePicker = false
    @State private var isShowingDocumentPicker = false

    @State private var selectedImage: UIImage?
    @State private var selectedDocumentURL: URL?
    
    func generateImagePicker(label: String, key: String, variable: String) -> [AnyView] {
        return []
    }

    func generateFilePicker(label: String, key: String, variable: String) -> [AnyView] {
        return []
    }

    func generateNavLink(label: String, key: String, dict: [String: Any]) -> [AnyView] {
        var views: [AnyView] = []
        
        let navLinkDestination = List {generateView(from: dict)}.navigationTitle(label).listStyle(.insetGrouped)
        views.append(AnyView(
            NavigationLink(destination: navLinkDestination, label: {Text(label).brightness(0.3)})
        ))

        return views
    }
    
    func generateSection(label: String, key: String, dict: [String: Any]) -> [AnyView] {
        var views: [AnyView] = []

        views.append(AnyView(
            Section(header: Text(label).font(.footnote)) {
                generateView(from: dict)
            }
        ))

        return views
    }
    
    func generateSectionWithFooter(label: String, key: String, array: [Any]) -> [AnyView] {
        var views: [AnyView] = []

        views.append(AnyView(
            Section(header: Text(label).font(.footnote), footer: Text(array[0] as? String ?? "").font(.footnote)) {
                generateView(from: array[1] as? [String: Any] ?? [:])
            }
        ))

        return views
    }

    func generateSegment(label: String, key: String, array: [Any]) -> [AnyView] {
        var views: [AnyView] = []

        if let options = array[1] as? [String: [Any]] {
            let segmentKey = array[0] as? String ?? ""

            let selectedSegment = Binding<Int>(
                get: {
                    if let selectedIndex = (variables[segmentKey] as? [Any])?.first as? Int {
                        return selectedIndex
                    } else {
                        return 0
                    }
                },
                set: { newValue in
                    if let selectedLabel = ((array[1] as? [String: Any] ?? [:])[options.keys.sorted().atIndex(newValue) ?? ""] as? [Any])?.first as? String {
                        variables[segmentKey] = [newValue, selectedLabel]
                        saveVariables()
                    }
                }
            )

            views.append(AnyView(
                Picker(label, selection: selectedSegment) {
                    ForEach(0..<options.keys.count, id: \.self) { index in
                        Text(options.keys.sorted()[index])
                    }
                }
                .pickerStyle(.segmented)
            ))
            
            if let selectedOption = options[options.keys.sorted()[selectedSegment.wrappedValue]]  {
                let optionView = AnyView(generateView(from: selectedOption[1] as? [String: Any] ?? [:]))
                print(selectedOption[1] as? [String: Any] ?? [:])
                print(optionView)
                views.append(optionView)
            }
        }

        return views
    }

    func generatePresets(label: String, key: String, dict: [String: Any]) -> [AnyView] {
        var views: [AnyView] = []

        views.append(contentsOf: [
            AnyView(Section(header: Text(label).font(.footnote)) {
                ForEach(dict.sorted(by: { $0.key < $1.key }), id: \.key) { presetName, presetData in
                    if let variableData = presetData as? [String: Any] {
                        Button(action: {
                            for (variableKey, variableValue) in variableData {
                                variables[variableKey] = variableValue
                            }
                            saveVariables()
                        }, label: {
                            Text(presetName).font(.headline)
                        })
                    }
                }
            })
        ])

        return views
    }

    func saveVariables() {
        if let jsonData = try? JSONSerialization.data(withJSONObject: variables, options: [.prettyPrinted]) {
            savejson = String(data: jsonData, encoding: .utf8) ?? ""
            
            do {
                try savejson.write(toFile: pkgpath+"/save.json", atomically: true, encoding: .utf8)
                print("Data saved to file: \(pkgpath)")
            } catch {
                print("Error saving data to file: \(error)")
            }
        }
    }
}
