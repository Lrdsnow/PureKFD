//
//  purePrefs.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/11/23.
//
//  WARNING: the code here is very bad
//

import Foundation
import SwiftUI
import NukeUI
import UniformTypeIdentifiers
import PhotosUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

let config_filename = "purekfd_v6_config.json"

@available(iOS 15.0, *)
struct PrefView: View {
    @EnvironmentObject var appData: AppData
    @Binding var selectedTweak: Package?
    @Binding var jsonString: String
    
    @State private var isUnsupportedPrefs: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
#if os(iOS)
            Color.accentColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            #endif
            
            if let pkg = selectedTweak {
                let pkgpath: URL = URL.documents.appendingPathComponent("pkgs/\(pkg.bundleid)")
                
                if !jsonString.isEmpty {
                    if !isUnsupportedPrefs {
                        FullPrefView(json: jsonString, pkgpath: pkgpath.path)
                    } else {
                        unsupportedPrefsView()
                    }
                } else {
                    loadingView().onAppear() {
                        loadPreferences(pkgpath: pkgpath)
                    }
                }
            } else {
                loadingView()
            }
        }
    }
    
    func loadPreferences(pkgpath: URL) {
        if let json = loadJsonFromConfig(pkgpath: pkgpath) {
            jsonString = json
        } else if let json = loadJsonFromPlist(pkgpath: pkgpath) {
            jsonString = json
        } else if let json = loadJsonFromPrefs(pkgpath: pkgpath) {
            jsonString = json
        } else {
            isUnsupportedPrefs = true
        }
    }
    
    func loadJsonFromConfig(pkgpath: URL) -> String? {
        let configPath = pkgpath.appendingPathComponent(config_filename).path
        if FileManager.default.fileExists(atPath: configPath),
           let data = FileManager.default.contents(atPath: configPath) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func loadJsonFromPlist(pkgpath: URL) -> String? {
        let plistPath = pkgpath.appendingPathComponent("config.plist").path
        if FileManager.default.fileExists(atPath: plistPath),
           let plistData = FileManager.default.contents(atPath: plistPath),
           let jsonDictionary = translateLegacyEncryptedPrefs(plistData: plistData),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
    
    func loadJsonFromPrefs(pkgpath: URL) -> String? {
        let prefsPath = pkgpath.appendingPathComponent("prefs.json").path
        if FileManager.default.fileExists(atPath: prefsPath),
           let prefData = FileManager.default.contents(atPath: prefsPath),
           let prefDict = try? JSONSerialization.jsonObject(with: prefData, options: []) as? [String: [[String: Any]]],
           let jsonDictionary = translatePicassoPrefs(picassoData: prefDict),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
    
    func unsupportedPrefsView() -> some View {
        VStack {
            Spacer()
            Text("Unsupported Prefs")
            Spacer()
        }
    }
    
    func loadingView() -> some View {
        VStack {
            Spacer()
            ProgressView().tint(.accentColor)
            Spacer()
        }
    }
}

@available(iOS 15.0, *)
struct FullPrefView: View {
    @EnvironmentObject var appData: AppData
    @State private var savejson: String = ""
    @State var json: String
    @State var pkgpath: String

    @State private var variables: [String: Any] = [:]
    @State private var randomvariables: [String: Any] = [:]
    @State private var theming: [String: Any] = [:]
    
    init(json: String, pkgpath: String) {
        _json = State(initialValue: json)
        _pkgpath = State(initialValue: pkgpath)
    }
    
    var body: some View {
        List {
            if let config = loadConfig(from: json) {
                generateView(from: config)
            }
        }
        #if os(iOS)
        .navigationBarTitle("Preferences")
        #endif
        .clearListBG()
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        // Load theming data
        if let themeData = checkForTheming(in: json) {
            theming = themeData
        }
        
        // Load save.json data
        let savePath = pkgpath + "/save.json"
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: savePath)),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
           let savedVariables = jsonObject as? [String: Any] {
            variables = savedVariables
        }
    }
    
    private func loadConfig(from json: String) -> [[String: Any]]? {
        if let jsonData = json.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
           let config = jsonObject as? [[String: Any]] {
            return config
        }
        return nil
    }

    func generateView(from config: [[String: Any]]) -> some View {
        var views: [AnyView] = []
        
        for item in config {
            for key in item.keys {
                if let value = item[key] {
                    let label = String(key.split(separator: ":").first ?? "")
                    let type = String(key.split(separator: ":").last ?? "")
                    if type == "image" {
                        views.append(generateImageView(value: value as? String ?? ""))
                    } else if type == "label" {
                        views.append(AnyView(Text(label).font(.body).if((value as? String)?.toColor() != nil){view in view.foregroundStyle((value as? String ?? "").toColor() ?? Color.white)}))
                    } else if type == "string" {
                        views.append(contentsOf: generateTextInput(label: label, key: key, variable: value as? String ?? ""))
                    } else if type == "intpad" {
                        views.append(contentsOf: generateIntPadInput(label: label, key: key, variable: value as? String ?? ""))
                    } else if type == "link" {
                        views.append(AnyView(Link(destination: URL(string: value as! String) ?? URL(string: "https://example.com")!, label: {Text(label ).brightness(0.3)})))
                    } else if type == "toggle" {
                        views.append(contentsOf: generateToggle(label: label, key: key, variable: value as? String ?? ""))
                    } else if type == "colorpicker" {
                        views.append(contentsOf: generateColorPicker(label: label, key: key, variable: value as? String ?? ""))
                    } else if type == "int" {
                        views.append(contentsOf: generateIntInput(label: label, key: key, variable: value as? String ?? ""))
                    } else if type == "double" {
                        views.append(contentsOf: generateDoubleInput(label: label, key: key, variable: value as? String ?? ""))
                    } else if let dict = value as? [[String: Any]] {
                        if type == "navlink" {
                            views.append(contentsOf: generateNavLink(label: label, key: key, dict: dict))
                        } else if type == "section" {
                            print("SECTION")
                            views.append(contentsOf: generateSection(label: label, key: key, dict: dict))
                        } else if type == "presets" {
                            views.append(contentsOf: generatePresets(label: label, key: key, dict: dict))
                        }
                    } else if let array = value as? [Any] {
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
                        } else if type == "imagepicker" {
                            views.append(contentsOf: generateImagePicker(label: label, key: key, array: array))
                        } else if type == "filepicker" {
                            views.append(contentsOf: generateFilePicker(label: label, key: key, array: array))
                        }
                    } else {
                        views.append(AnyView(Text("Unsupported Pref: \(type)")))
                    }
                }
            }
        }
        
        return ForEach(views.indices, id: \.self) { index in
            views[index].padding(.vertical, 2.5)
            #if os(iOS)
                .listRowBackground(Color.accentColor.opacity(0.1))
            #endif
                .listRowSeparator(.hidden)
        }
    }
    
    func checkForTheming(in jsonString: String) -> [String: Any]? {
        if let jsonData = jsonString.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
            let config = jsonObject as? [String: Any],
            let themingValue = config["theming"] as? [String: Any] {
            log(themingValue)
            return themingValue
        }
        return nil
    }
    
    func generateImageView(value: String) -> AnyView {
        if value.starts(with: "http"), let imageURL = URL(string: value) {
            return AnyView(LazyImage(url: imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    ProgressView()
                        .scaledToFit()
                } }.cornerRadius(10))
        }
        return AnyView(LazyImage(url: URL(fileURLWithPath: "\(pkgpath)/\(value)")) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFill()
            } else if state.error != nil {
                #if os(iOS)
                Image(uiImage: UIImage(named: "DisplayAppIcon")!)
                    .resizable()
                    .scaledToFill()
                #else
                ProgressView()
                    .scaledToFit()
                #endif
            } else {
                ProgressView()
                    .scaledToFit()
            } }.cornerRadius(15).listRowBackground(Color.clear).listRowInsets(EdgeInsets()))
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
                let stateView = generateView(from: [stateComponents])
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

        guard array.count > 1,
              let key = array[safe: 0] as? String,
              let pickerOptions = array[safe: 1] as? [[String: String]] else {
            return views
        }

        let selectedOptionIndex = Binding<Int>(
            get: {
                let selectedValue = variables[key] as? String
                return pickerOptions.firstIndex(where: { $0["value"] == selectedValue }) ?? 0
            },
            set: { newValue in
                let selectedOption = pickerOptions[newValue]
                let newValue = selectedOption["value"] ?? ""
                variables[key] = newValue
                saveVariables()
            }
        )

        views.append(AnyView(
            HStack {
                Picker(label, selection: selectedOptionIndex) {
                    ForEach(pickerOptions.indices, id: \.self) { index in
                        Text(pickerOptions[index]["label"] ?? "Unknown")
                    }
                }
            }
        ))
        
        return views
    }

    func generateSegmentPicker(key: String, label: String, array: [Any]) -> [AnyView] {
        var views: [AnyView] = []

        guard array.count > 1,
              let key = array[safe: 0] as? String,
              let pickerOptions = array[safe: 1] as? [[String: String]] else {
            return views
        }

        let selectedOptionIndex = Binding<Int>(
            get: {
                let selectedValue = variables[key] as? String
                return pickerOptions.firstIndex(where: { $0["value"] == selectedValue }) ?? 0
            },
            set: { newValue in
                let selectedOption = pickerOptions[newValue]
                let newValue = selectedOption["value"] ?? ""
                variables[key] = newValue
                saveVariables()
            }
        )

        views.append(AnyView(
            HStack {
                Picker(label, selection: selectedOptionIndex) {
                    ForEach(pickerOptions.indices, id: \.self) { index in
                        Text(pickerOptions[index]["label"] ?? "Unknown")
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        ))
        
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
        #if os(iOS)
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
        #endif
        return views
    }
    
    func generateImagePicker(label: String, key: String, array: [Any]) -> [AnyView] {
#if os(iOS)
        let url = URL(fileURLWithPath: array.first as? String ?? "")
        let variable = TweakPath.parseSegment(url.lastPathComponent)?.name ?? url.lastPathComponent
        
        let imageSet = Binding<Bool>(
            get: {
                return $variables.wrappedValue[variable] != nil
            },
            set: { newValue in
                
            }
        )
        
        let image = Binding<UIImage?>(
            get: {
                return nil
            },
            set: { newValue in
                let importedFolderURL = URL(fileURLWithPath: "\(pkgpath)/imported")
                try? FileManager.default.createDirectory(at: importedFolderURL, withIntermediateDirectories: true, attributes: nil)
                let destinationURL = importedFolderURL.appendingPathComponent(variable)
                
                if let imageData = newValue?.pngData() {
                    do {
                        try imageData.write(to: destinationURL)
                        $variables.wrappedValue[variable] = destinationURL.absoluteString
                        saveVariables()
                    } catch {
                        print("Failed to save image: \(error)")
                    }
                } else {
                    $variables.wrappedValue[variable] = nil
                    saveVariables()
                }
            }
        )
        
        return [
            AnyView(
                ImagePickerView(label: label, image: image, imageSet: imageSet)
            )
        ]
#else
        return []
#endif
    }

    func generateFilePicker(label: String, key: String, array: [Any]) -> [AnyView] {
#if os(iOS)
        let url = URL(fileURLWithPath: array.first as? String ?? "")
        let variable = TweakPath.parseSegment(url.lastPathComponent)?.name ?? url.lastPathComponent
        let file_ext = variable.components(separatedBy: ".").last ?? ""
        
        var file = Binding<URL?>(
            get: {
                if let urlString = $variables.wrappedValue[variable] as? String {
                    return URL(string: urlString)
                } else {
                    return nil
                }
            },
            set: { newValue in
                $variables.wrappedValue[variable] = newValue?.absoluteString
                saveVariables()
            }
        )
        
        var bytes = Binding<Int>(
            get: {
                return $variables.wrappedValue["\(variable)_bytes"] as? Int ?? 0
            },
            set: { newValue in
                $variables.wrappedValue["\(variable)_bytes"] = newValue
                saveVariables()
            }
        )
        
        let label_components = label.components(separatedBy: "\n[")
        let _label = label_components.first ?? ""
        let limit_components = label_components.last?.components(separatedBy: "]").first?.components(separatedBy: " ") ?? []
        var limit = Int(Int64.max)
        if limit_components.count > 1,
           let _limit = Int(limit_components[1]) {
            limit = _limit
        }
        
        return [
            AnyView(
                FilePickerView(label: _label, variable: variable, pkgpath: pkgpath, file_ext: file_ext, limit: limit, file: file, bytes: bytes)
            )
        ]
#else
        return []
#endif
    }

    func generateNavLink(label: String, key: String, dict: [[String: Any]]) -> [AnyView] {
        var views: [AnyView] = []
        
        let navLinkDestination = ZStack(alignment: .bottom) {
            Color.accentColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            List {
                generateView(from: dict)
            }.navigationTitle(label)
#if os(iOS)
                .listStyle(.insetGrouped)
#endif
                .clearListBG()
        }
        
        #if os(iOS)
        views.append(AnyView(
            NavigationLink(destination: navLinkDestination, label: {Text(label).brightness(0.3)}).isDetailLink(true)
        ))
        #else
        views.append(AnyView(
            NavigationLink(destination: navLinkDestination, label: {Text(label).brightness(0.3)})
        ))
        #endif
        
        return views
    }
    
    func generateSection(label: String, key: String, dict: [[String: Any]]) -> [AnyView] {
        var views: [AnyView] = []
        
        print("SECTIONGEN")
        print(dict)

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
                generateView(from: [array[1] as? [String: Any] ?? [:]])
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
                let optionView = AnyView(generateView(from: [selectedOption[1] as? [String: Any] ?? [:]]))
                NSLog("%@", "\(selectedOption[1] as? [String: Any] ?? [:])")
                NSLog("%@", "\(optionView)")
                views.append(optionView)
            }
        }

        return views
    }

    func generatePresets(label: String, key: String, dict: [[String: Any]]) -> [AnyView] {
        var views: [AnyView] = []

        views.append(
            AnyView(Section(header: Text(label).font(.footnote)) {
                ForEach(0..<dict.count, id: \.self) { index in
                    let preset = dict[index]
                    if let presetName = preset.keys.first,
                       let presetData = preset.values.first as? [String: Any] {
                        Button(action: {
                            for (variableKey, variableValue) in presetData {
                                variables[variableKey] = variableValue
                            }
                            saveVariables()
                        }) {
                            Text(presetName).font(.headline)
                        }
                    }
                }
            })
        )

        return views
    }

    func saveVariables() {
        if let jsonData = try? JSONSerialization.data(withJSONObject: variables, options: [.prettyPrinted]) {
            savejson = String(data: jsonData, encoding: .utf8) ?? ""
            
            do {
                try savejson.write(toFile: pkgpath+"/save.json", atomically: true, encoding: .utf8)
                NSLog("Data saved to file: \(pkgpath)")
            } catch {
                NSLog("Error saving data to file: \(error)")
            }
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func clearListBG() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}

extension Array {
    func atIndex(_ index: Int) -> Element? {
        return index < count ? self[index] : nil
    }
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#if os(iOS)

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true, completion: nil)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
        }
    }
}

struct FilePickerView: View {
    let label: String
    let variable: String
    let pkgpath: String
    let file_ext: String
    let limit: Int
    @Binding var file: URL?
    @Binding var bytes: Int
    @State private var isPresented = false
    
    var body: some View {
        Button(action: {
            isPresented = true
        }, label: {
            HStack {
                Text(label)
                Spacer()
                Text("\(bytes) bytes")
            }
        }).fileImporter(isPresented: $isPresented, allowedContentTypes: [UTType(filenameExtension: file_ext) ?? .item], onCompletion: { result in
            switch result {
            case .success(let url):
                url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let _bytes = fileAttributes[.size] as? Int ?? 0
                    if _bytes <= limit {
                        let importedFolderURL = URL(fileURLWithPath: "\(pkgpath)/imported")
                        try FileManager.default.createDirectory(at: importedFolderURL, withIntermediateDirectories: true, attributes: nil)
                        let destinationURL = importedFolderURL.appendingPathComponent(variable)
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                        file = destinationURL
                        bytes = _bytes
                    } else {
                        print("Failed to import file: File too big!")
                    }
                } catch {
                    print("Failed to move or process file: \(error)")
                }
            case .failure(let error):
                print("Failed to import file: \(error)")
            }
        })
    }
    
}

struct ImagePickerView: View {
    let label: String
    @Binding var image: UIImage?
    @Binding var imageSet: Bool
    @State private var isPresented = false
    
    var body: some View {
        Button(action: {
            isPresented = true
        }, label: {
            HStack {
                Text(label)
                Spacer()
                Text(imageSet ? "Image Selected" : "No Image")
            }
        }).sheet(isPresented: $isPresented) {
            PhotoPicker(image: $image)
        }
    }
    
}

#endif
