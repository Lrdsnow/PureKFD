//
//  InstalledPackagesView.swift
//  test
//
//  Created by Lrdsnow on 8/20/23.
//

import Foundation
import SwiftUI

struct InstalledPackagesView: View {
    @State private var installedPackages: [InstalledPackage]
    
    
    
    init(installedPackages: [InstalledPackage]) {
        self._installedPackages = State(initialValue: installedPackages)
        print(installedPackages)
    }
    
    var body: some View {
        List {
            ForEach(installedPackages.indices, id: \.self) { index in
                let installedPackage = installedPackages[index]
                if !installedPackage.preferences.isEmpty {
                    NavigationLink(destination: PreferencesView(preferences: installedPackage.preferences, installedPackage: $installedPackages[index])) {
                        row(for: installedPackage)
                    }.listRowBackground(Color.clear)
                } else {
                    row(for: installedPackage).listRowBackground(Color.clear)
                }
            }
            .onDelete(perform: deletePackages)
            .onMove(perform: moveRow)
        }
    }
    
    func moveRow(from source: IndexSet, to destination: Int) {
        installedPackages.move(fromOffsets: source, toOffset: destination)
    }
    
    private func row(for installedPackage: InstalledPackage) -> some View {
        InstalledPackageRow(installedPackage: installedPackage)
            .contextMenu {
                Button(role: .destructive, action: {
                    if let index = installedPackages.firstIndex(of: installedPackage) {
                        deletePackage(at: index)
                    }
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    if let index = installedPackages.firstIndex(of: installedPackage) {
                        deletePackage(at: index)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
    
    private func deletePackage(at index: Int) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pkg = installedPackages[index]
        if pkg.type == "misaka" {
            let path = documentsDirectory.appendingPathComponent("Misaka/Installed").appendingPathComponent(pkg.bundleID)
            try? fileManager.removeItem(at: path)
        } else {
            let path = documentsDirectory.appendingPathComponent("Installed").appendingPathComponent(pkg.bundleID)
            try? fileManager.removeItem(at: path)
        }
        installedPackages.remove(at: index)
    }
    
    private func deletePackages(at offsets: IndexSet) {
        installedPackages.remove(atOffsets: offsets)
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }

    func toHex(includeAlpha: Bool = true) -> String {
        let uiColor = UIColor(self)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let redValue = Int(red * 255)
        let greenValue = Int(green * 255)
        let blueValue = Int(blue * 255)
        let alphaValue = Int(alpha * 255)

        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", redValue, greenValue, blueValue, alphaValue)
        } else {
            return String(format: "#%02X%02X%02X", redValue, greenValue, blueValue)
        }
    }
}


enum PreferenceValue: Codable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case colorHex(String)
    case picker([Int: String])
    case resfield([String: Int])

    enum CodingKeys: String, CodingKey {
        case type, value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .bool(let value):
            try container.encode("bool", forKey: .type)
            try container.encode(value, forKey: .value)
        case .int(let value):
            try container.encode("int", forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode("double", forKey: .type)
            try container.encode(value, forKey: .value)
        case .string(let value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .value)
        case .colorHex(let value):
            try container.encode("colorHex", forKey: .type)
            try container.encode(value, forKey: .value)
        case .picker(let value):
            try container.encode("picker", forKey: .type)
            try container.encode(value, forKey: .value)
        case .resfield(let value):
            try container.encode("resfield", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "bool":
            self = .bool(try container.decode(Bool.self, forKey: .value))
        case "int":
            self = .int(try container.decode(Int.self, forKey: .value))
        case "double":
            self = .double(try container.decode(Double.self, forKey: .value))
        case "string":
            self = .string(try container.decode(String.self, forKey: .value))
        case "colorHex":
            self = .colorHex(try container.decode(String.self, forKey: .value))
        case "picker":
            self = .picker(try container.decode([Int: String].self, forKey: .value))
        case "resfield":
            self = .resfield(try container.decode([String: Int].self, forKey: .value))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown preference type")
        }
    }
}





struct PreferencesView: View {
    let preferences: [InstalledPackage.Preference]
    @Binding var installedPackage: InstalledPackage
    
    // UI stuffs
    @State private var showAlert = false
    
    // Temporary values to hold changes before applying
    @State private var tempPreferences: [String: Any] = [:]
    
    init(preferences: [InstalledPackage.Preference], installedPackage: Binding<InstalledPackage>) {
        self.preferences = preferences
        self._installedPackage = installedPackage
        
        // Setup default stuff
        setupDefaultTempPreferences()
        
        // Load saved preferences from config.json
        loadSavedPreferences()
    }
    
    var body: some View {
            List {
                ForEach(preferences.indices, id: \.self) { index in
                    let preference = preferences[index]
                    Section(header: header(for: preference),
                        footer: footer(for: preference)) {
                        preferenceView(for: preference, at: index)
                    }
                }
            }
            .navigationBarTitle("Preferences", displayMode: .large)
            .navigationBarItems(trailing: applyButton)
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text("Preferences have been successfully saved. These will persist till you Apply new ones."),
                    dismissButton: .default(Text("OK"))
                )
            }.onAppear {
                loadSavedPreferences()
            }

    }
    
    private var applyButton: some View {
        Button("Apply", action: applyChanges)
    }
    
    private func header(for preference: InstalledPackage.Preference) -> some View {
            Group {
            if preference.valueType == "String" {
                Text("Notice")
            } else if false /* Your condition here */ {
                Text(preference.title)
            } else {
                EmptyView()
            }
        }
    }
    
    private func footer(for preference: InstalledPackage.Preference) -> some View {
        Group {
            if preference.valueType != "String" && preference.valueType != "NavigationLink" {
                Text(preference.description)
                    .font(.subheadline)
            } else {
                EmptyView()
            }
        }
    }
    
    private func preferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
            switch preference.valueType {
            case "color", "Color_Hex":
                return AnyView(colorPreferenceView(for: preference, at: index))
            case "resfield":
                return AnyView(resfieldPreferenceView(for: preference, at: index))
            case "picker":
                return AnyView(pickerPreferenceView(for: preference, at: index))
            case "bool":
                return AnyView(booleanPreferenceView(for: preference, at: index))
            case "int":
                return AnyView(integerPreferenceView(for: preference, at: index))
            case "double":
                return AnyView(doublePreferenceView(for: preference, at: index))
            case "string":
                return AnyView(stringPreferenceView(for: preference, at: index))
            case "String":
                return AnyView(noticePreferenceView(for: preference, at: index))
            case "NavigationLink":
                return AnyView(navLinkPreferenceView(for: preference, at: index))
            case "Link":
                return AnyView(linkPreferenceView(for: preference, at: index))
            default:
                return AnyView(unsupportedPreferenceView(preference.valueType))
            }
        }
    
    private func testView() -> some View {
        Text("Test")
    }
    
    private func autoGenView(for preference: InstalledPackage.Preference) -> some View {
        Text(preference.title)
    }
    
    private func navLinkPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        NavigationLink(preference.title, destination: autoGenView(for: preference))
    }
    
    private func linkPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        Text(preference.title)
    }
    
    private func noticePreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        Text(preference.title)
    }
    
    private func resfieldPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        HStack {
            let preferenceObject = tempPreferences[preference.key] as? [String: Int] ?? ["height": 2796, "width": 1290]
            
            let heightBinding = Binding<Int>(
                get: {
                    preferenceObject["height"] ?? 2796
                },
                set: { newValue in
                    var updatedPreferenceObject = preferenceObject
                    updatedPreferenceObject["height"] = newValue
                    tempPreferences[preference.key] = updatedPreferenceObject
                }
            )
            
            let widthBinding = Binding<Int>(
                get: {
                    preferenceObject["width"] ?? 1290
                },
                set: { newValue in
                    var updatedPreferenceObject = preferenceObject
                    updatedPreferenceObject["width"] = newValue
                    tempPreferences[preference.key] = updatedPreferenceObject
                }
            )
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16)], spacing: 16) {
                HStack {
                    Text("Height")
                    Divider()
                    TextField("Height", value: heightBinding, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                }
                Divider()
                HStack {
                    Text("Width")
                    Divider()
                    TextField("Width", value: widthBinding, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                }
            }
        }
    }
    
    private func colorPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        if preference.valueType == "color" {
            return AnyView(regularColorPreferenceView(for: preference, at: index))
        } else if preference.valueType == "Color_Hex" {
            return AnyView(hexColorPreferenceView(for: preference, at: index))
        } else {
            return AnyView(Text("Unsupported preference type: \(preference.valueType)"))
        }
    }

    private func regularColorPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        ColorPicker(selection: Binding<Color>(
            get: {
                tempPreferences[preference.key] as? Color ?? (installedPackage.savedPreferences[preference.key] as? Color ?? Color.white)
            },
            set: { newValue in
                tempPreferences[preference.key] = newValue
            }
        ), label: {
            Text(preference.title)
        })
    }

    private func hexColorPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        ColorPicker(selection: Binding<Color>(
            get: {
                let hexValue = tempPreferences[preference.key] as? String ?? ""
                return Color(hex: hexValue)
            },
            set: { newValue in
                tempPreferences[preference.key] = newValue.toHex()
            }
        ), label: {
            Text(preference.title)
        })
    }

    private func pickerPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        let selectedOption = Binding<String>(
            get: {
                return tempPreferences[preference.key] as? String ?? preference.options?.first ?? ""
            },
            set: { newValue in
                tempPreferences[preference.key] = newValue
            }
        )
        
        return Picker(selection: selectedOption, label: Text(preference.title)) {
            ForEach(preference.options ?? [], id: \.self) { option in
                Text(option)
                    .tag(option) // Use the option itself as the tag
            }
        }
        //.pickerStyle(DefaultPickerStyle()) // Add a picker style here if needed
    }

    private func booleanPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        Toggle(preference.title, isOn: Binding<Bool>(
            get: {
                tempPreferences[preference.key] as? Bool ?? (installedPackage.savedPreferences[preference.key] as? Bool ?? false)
            },
            set: { newValue in
                tempPreferences[preference.key] = newValue
            }
        ))
    }

    private func integerPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        let lowerBound = preference.optionValues?.first ?? 0
        let upperBound = preference.optionValues?.last ?? 1000
        
        let range = lowerBound...upperBound
        
        return VStack {
            Stepper(value: Binding<Int>(
                get: {
                    tempPreferences[preference.key] as? Int ?? (installedPackage.savedPreferences[preference.key] as? Int ?? lowerBound)
                },
                set: { newValue in
                    tempPreferences[preference.key] = newValue
                }
            ), in: range) {
                Text("\(preference.title): \(tempPreferences[preference.key] as? Int ?? lowerBound)")
            }
        }
    }

    private func doublePreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        let lowerBound = preference.optionValues?.first ?? 0
        let upperBound = preference.optionValues?.last ?? 1
        
        let range = Double(lowerBound)...Double(upperBound)
        
        return VStack {
            Slider(value: Binding<Double>(
                get: {
                    tempPreferences[preference.key] as? Double ?? (installedPackage.savedPreferences[preference.key] as? Double ?? Double(lowerBound))
                },
                set: { newValue in
                    tempPreferences[preference.key] = newValue
                }
            ), in: range) {
                Text(preference.title)
            }
        }
    }

    private func stringPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        TextField(preference.title, text: Binding<String>(
            get: {
                tempPreferences[preference.key] as? String ?? (installedPackage.savedPreferences[preference.key] as? String ?? "")
            },
            set: { newValue in
                tempPreferences[preference.key] = newValue
            }
        ))
    }

    private func unsupportedPreferenceView(_ valueType: String) -> some View {
        Text("Unsupported preference type: \(valueType)")
    }

    
    private func applyChanges() {
        // Apply the temporary changes to the installedPackage.savedPreferences
        for (key, value) in tempPreferences {
            print(key, value)
            installedPackage.savedPreferences[key] = value as? PreferenceValue
        }
        
        // Clear the temporary preferences
        //tempPreferences.removeAll()
        
        // Save preferences to config.json
        if savePreferences() {
            showAlert = true // Show the success alert
        }
    }

    private func savePreferences() -> Bool {
        var encodedPreferences: [String: PreferenceValue] = [:]
        print("\nSaving Preferences...\n")
        
        for (key, value) in tempPreferences {
            if let colorValue = value as? Color {
                encodedPreferences[key] = .colorHex(colorValue.toHex())
            } else if let resfieldValue = value as? [String: Int] {
                encodedPreferences[key] = .resfield(resfieldValue)
            } else if let boolValue = value as? Bool {
                encodedPreferences[key] = .bool(boolValue)
            } else if let intValue = value as? Int {
                encodedPreferences[key] = .int(intValue)
            } else if let doubleValue = value as? Double {
                encodedPreferences[key] = .double(doubleValue)
            } else if let stringValue = value as? String {
                encodedPreferences[key] = .string(stringValue)
            } else if let pickerValue = value as? [Int: String] {
                encodedPreferences[key] = .picker(pickerValue)
            } else if let preferenceValue = value as? PreferenceValue {
                encodedPreferences[key] = preferenceValue
            }
        }

        let fileManager = FileManager.default
        let packageFolder = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed").appendingPathComponent(installedPackage.bundleID)
        let configURL = packageFolder.appendingPathComponent("config.json")
        
        do {
            let preferencesData = try JSONEncoder().encode(encodedPreferences)
            try preferencesData.write(to: configURL)
            return true
        } catch {
            print("Error writing preferences to config.json: \(error)")
            return false
        }
    }

    private func loadSavedPreferences() {
        let fileManager = FileManager.default
        let packageFolder = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed").appendingPathComponent(installedPackage.bundleID)
        let configURL = packageFolder.appendingPathComponent("config.json")

        do {
            if fileManager.fileExists(atPath: configURL.path) {
                let configData = try Data(contentsOf: configURL)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                do {
                    let preferencesDict = try decoder.decode([String: PreferenceValue].self, from: configData)
                    
                    tempPreferences = [:]

                    for (key, value) in preferencesDict {
                        switch value {
                        case .colorHex(let hexValue):
                            if let color = UIColor(hex: hexValue) {
                                tempPreferences[key] = Color(color)
                            } else {
                                print("Invalid hex color value: \(hexValue)")
                            }
                        case .resfield(let resfieldValue):
                            tempPreferences[key] = resfieldValue
                        case .bool(let boolValue):
                            tempPreferences[key] = boolValue
                        case .int(let intValue):
                            tempPreferences[key] = intValue
                        case .double(let doubleValue):
                            tempPreferences[key] = doubleValue
                        case .string(let stringValue):
                            tempPreferences[key] = stringValue
                        case .picker(let pickerValue):
                            tempPreferences[key] = pickerValue
                        }
                    }
                } catch {
                    print("Error decoding preferences from config.json: \(error)")
                }
            }
        } catch {
            print("Error loading preferences from config.json: \(error)")
        }
    }
    
    private func setupDefaultTempPreferences() {
        for preference in preferences {
            switch preference.valueType {
            case "color", "Color_Hex":
                tempPreferences[preference.key] = Color.white // Set default color or hex color here
            case "resfield":
                tempPreferences[preference.key] = ["height": 2796, "width": 1290] // Set default resfield values here
            case "picker":
                tempPreferences[preference.key] = [0, preference.options?.first ?? ""] // Set default picker values here
            case "bool":
                tempPreferences[preference.key] = false // Set default boolean value here
            case "int":
                tempPreferences[preference.key] = preference.optionValues?.first ?? 0 // Set default int value here
            case "double":
                tempPreferences[preference.key] = Double(preference.optionValues?.first ?? 0) // Set default double value here
            case "string":
                tempPreferences[preference.key] = "" // Set default string value here
            case "String":
                tempPreferences[preference.key] = "" // Set default notice value here
            // Handle other cases as needed
            default:
                break
            }
        }
    }


}

struct InstalledPackageRow: View {
    let installedPackage: InstalledPackage
    @State private var contentIcon: UIImage? = nil
    
    var body: some View {
        HStack {
            if let icon = contentIcon { // Display the fetched icon if available
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 30, height: 30) // Adjust the size as needed
                    .cornerRadius(5)
            } else {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
            }
            VStack(alignment: .leading) {
                Text(installedPackage.name)
                    .font(.headline)
                    .foregroundColor(.purple)
                Text(installedPackage.author)
                    .font(.subheadline)
                    .foregroundColor(.purple.opacity(0.7))
                if installedPackage.type == "misaka" {
                    if !installedPackage.preferences.isEmpty {
                        Text("Misaka - Most likely unsupported")
                            .font(.footnote)
                            .foregroundColor(.purple.opacity(0.5))
                    } else {
                        Text("Misaka - May be supported")
                            .font(.footnote)
                            .foregroundColor(.purple.opacity(0.5))
                    }
                } else {
                    Text("Picasso - Should be supported")
                        .font(.footnote)
                        .foregroundColor(.purple.opacity(0.5))
                }
            }
        }.onAppear {
            fetchImage(from: installedPackage.icon) { result in
                switch result {
                case .success(let image):
                    DispatchQueue.main.async {
                        contentIcon = image // Update the fetched image
                    }
                case .failure(let error):
                    print("Error fetching image: \(error)")
                }
            }
        }
    }
}

struct InstalledPackage: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let author: String
    let version: String
    let bundleID: String
    let icon: URL
    let type: String?
    struct Preference: Codable, Hashable {
        let valueType: String
        let key: String
        let options: Array<String>?
        let optionValues: Array<Int>?
        let title: String
        let description: String
        let extra_json_data: String?
    }
    
    var savedPreferences: [String: PreferenceValue] = [:]
    var preferences: [Preference]
    
    static func == (lhs: InstalledPackage, rhs: InstalledPackage) -> Bool {
        return lhs.id == rhs.id
    }
}

struct TweakCategory: Codable {
    let category: String?
    let tweaks: [Tweak]?
    
    enum CodingKeys: String, CodingKey {
        case category = "Category"
        case tweaks = "Tweaks"
    }
}

struct Tweak: Codable {
    let label: String?
    let type: String?
    let ui: String?
    let identifier: String?
    let value: String?
    // Include other properties as needed based on your actual structure
    
    enum CodingKeys: String, CodingKey {
        case label = "Label"
        case type = "Type"
        case ui = "UI"
        case identifier = "Identifier"
        case value = "Value"
        // Include other coding keys as needed
    }
}

func getInstalledPackages() -> [InstalledPackage] {
    let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var installedPackages: [InstalledPackage] = []

    // Get Picasso Packages
    let picassoFolderPath = installedFolderPath.appendingPathComponent("Installed")
    do {
        let installedFolders = try FileManager.default.contentsOfDirectory(at: picassoFolderPath, includingPropertiesForKeys: nil, options: [])
        
        for folderURL in installedFolders {
            if let infoURL = URL(string: folderURL.appendingPathComponent("info.json").absoluteString),
               let data = try? Data(contentsOf: infoURL),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let name = json["name"] as? String,
               let author = json["author"] as? String,
               let version = json["version"] as? String,
               let bundleID = json["bundleID"] as? String,
               let iconURL = URL(string: folderURL.appendingPathComponent("icon.png").absoluteString),
               let prefsURL = URL(string: folderURL.appendingPathComponent("prefs.json").absoluteString),
               let prefsData = try? Data(contentsOf: prefsURL),
               let prefsJSON = try? JSONSerialization.jsonObject(with: prefsData, options: []) as? [String: Any],
               let prefsArray = prefsJSON["preferences"] as? [[String: Any]] {
                
                var preferences: [InstalledPackage.Preference] = []
                
                for prefDict in prefsArray {
                    if let valueType = prefDict["valueType"] as? String,
                       let key = prefDict["key"] as? String,
                       let title = prefDict["title"] as? String,
                       let description = prefDict["description"] as? String {
                        
                        var options: [String] = []
                        var optionValues: [Int] = []
                        
                        if let optionsArray = prefDict["options"] as? [String],
                           let optionValuesArray = prefDict["optionValues"] as? [Int],
                           optionsArray.count == optionValuesArray.count {
                            options = optionsArray
                            optionValues = optionValuesArray
                        }
                        
                        let preference = InstalledPackage.Preference(valueType: valueType, key: key, options: options, optionValues: optionValues, title: title, description: description, extra_json_data: "")
                        preferences.append(preference)
                    }
                }
                
                let installedPackage = InstalledPackage(name: name, author: author, version: version, bundleID: bundleID, icon: iconURL, type: "picasso", preferences: preferences)
                installedPackages.append(installedPackage)
            }
        }
    } catch {
        print("Error fetching Picasso packages: \(error)")
    }

    // Get Misaka Packages
    let misakaFolderPath = installedFolderPath.appendingPathComponent("Misaka/Installed")

    do {
        let misakaPackageFolders = try FileManager.default.contentsOfDirectory(at: misakaFolderPath, includingPropertiesForKeys: nil, options: [])
        
        for packageFolderURL in misakaPackageFolders {
            let infoURL = packageFolderURL.appendingPathComponent("info.json")
            
            if let infoData = try? Data(contentsOf: infoURL),
               let infoJSON = try? JSONSerialization.jsonObject(with: infoData, options: []) as? [String: Any],
               let name = infoJSON["Name"] as? String,
               let bundleID = infoJSON["PackageID"] as? String,
               let iconURLString = infoJSON["Icon"] as? String,
               let iconURL = URL(string: iconURLString) {
                
                let prefsURL = packageFolderURL.appendingPathComponent("config.plist")
                var prefsData: Data? = nil
                var prefsArray: [[String: Any]] = []
                
                if FileManager.default.fileExists(atPath: prefsURL.path) {
                    prefsData = try? Data(contentsOf: prefsURL)
                    
                    if let plistData = try? PropertyListSerialization.propertyList(from: prefsData!, options: [], format: nil),
                       let prefsArrayFromPlist = plistData as? [[String: Any]] {
                        prefsArray = prefsArrayFromPlist
                    } else {
                        print("Failed to parse plist data")
                    }
                }
                
                var preferences: [InstalledPackage.Preference] = []
                
                for categoryDict in prefsArray {
                    if let tweaksArray = categoryDict["Tweaks"] as? [[String: Any]] {
                        for tweakDict in tweaksArray {
                            if let label = tweakDict["Label"] as? String,
                               var type = tweakDict["Type"] as? String?,
                               let ui = tweakDict["UI"] as? String? {
                                
                                var identifier: String?
                                                                   
                                if let identifierFromDict = tweakDict["Identifier"] as? String {
                                                                       identifier = identifierFromDict
                                                                   } else if let keyFromDict = tweakDict["key"] as? String {
                                                                       identifier = keyFromDict
                                                                   }
                                                                   
                                                                   var options: [String] = []
                                                                   var optionValues: [Int] = []
                                                                   var extra_json_data: String = ""
                                                                   
                                                                   if type == "Color_Hex", let value = tweakDict["Value"] as? String {
                                                                       var colorValue = value
                                                                       if colorValue.hasPrefix("#") {
                                                                           colorValue = String(colorValue.dropFirst())
                                                                       }
                                                                       
                                                                       options.append(colorValue)
                                                                       optionValues.append(0)
                                                                   }
                                                                   
                                                                   print("\n", ui ?? "noUI", "\n")
                                                                   if let ui = tweakDict["UI"] as? String, ui == "NavigationLink" {
                                                                       type = ui
                                                                       var extra_data: [String: Any] = [:]  // Changed to use [String: Any]
                                                                       
                                                                       if let categoriesArray = tweakDict["Categories"] as? [[String: Any]] {
                                                                           var categoriesInfo: [[String: Any]] = []
                                                                           
                                                                           for categoryInfo in categoriesArray {
                                                                               if let categoryName = categoryInfo["Category"] as? String,
                                                                                  let tweaksArray = categoryInfo["Tweaks"] as? [[String: Any]] {
                                                                                   var tweaksInfo: [[String: Any]] = []
                                                                                   
                                                                                   for tweakInfo in tweaksArray {
                                                                                       if let tweakLabel = tweakInfo["Label"] as? String,
                                                                                          let tweakUI = tweakInfo["UI"] as? String,
                                                                                          let tweakURLString = tweakInfo["URL"] as? String,
                                                                                          let tweakURL = URL(string: tweakURLString)?.absoluteString {
                                                                                           let tweak = [
                                                                                               "Label": tweakLabel,
                                                                                               "UI": tweakUI,
                                                                                               "URL": tweakURL
                                                                                           ] as [String : Any]
                                                                                           tweaksInfo.append(tweak)
                                                                                       }
                                                                                   }
                                                                                   
                                        let category = [
                                            "Category": categoryName,
                                            "Tweaks": tweaksInfo
                                        ] as [String : Any]
                                            categoriesInfo.append(category)
                                            }
                                        }
                                                                
                                            extra_data["Categories"] = categoriesInfo
                                        }
                                        let jsonData = try JSONSerialization.data(withJSONObject: extra_data, options: [])
                                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                                                                           extra_json_data = jsonString
                                    }
                                }
                                                                   
                                
                                let preference = InstalledPackage.Preference(valueType: type ?? "", key: identifier ?? "", options: options, optionValues: optionValues, title: label, description: ui ?? "", extra_json_data: extra_json_data)
                                preferences.append(preference)
                            }
                        }
                    }
                }
                
                let authorDict = infoJSON["Author"] as? [String: Any] ?? ["Label": "Unknown Author"]
                let authorLabel = authorDict["Label"] as? String
                let version = infoJSON["MinIOSVersion"] as? String ?? "15.0"
                
                let installedPackage = InstalledPackage(name: name, author: authorLabel!, version: version, bundleID: bundleID, icon: iconURL, type: "misaka", preferences: preferences)
                installedPackages.append(installedPackage)
                
            } else {
                print("Failed to get data from info.json")
            }
        }
    } catch {
        print("Error fetching Misaka packages: \(error)")
    }
    
    return installedPackages
}
