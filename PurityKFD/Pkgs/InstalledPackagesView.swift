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
    }
    
    var body: some View {
        List {
            ForEach(installedPackages.indices, id: \.self) { index in
                let installedPackage = installedPackages[index]
                if !installedPackage.preferences.isEmpty {
                    NavigationLink(destination: PreferencesView(preferences: installedPackage.preferences, installedPackage: $installedPackages[index])) {
                        row(for: installedPackage)
                    }
                } else {
                    row(for: installedPackage)
                }
            }
            .onDelete(perform: deletePackages)
        }
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
        let path = documentsDirectory.appendingPathComponent("Installed").appendingPathComponent(pkg.bundleID)
        try? fileManager.removeItem(at: path)
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
    case color(Color)
    case picker(Int)
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
        case .color(let value):
            try container.encode("color", forKey: .type)
            try container.encode(value.toHex(), forKey: .value)
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
        case "color":
            let hexString = try container.decode(String.self, forKey: .value)
            self = .color(Color(hex: hexString))
        case "picker":
            self = .picker(try container.decode(Int.self, forKey: .value))
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
            
        // Load saved preferences from config.json
        loadSavedPreferences()
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(preferences.indices, id: \.self) { index in
                    let preference = preferences[index]
                    Section(header: header(for: preference),
                        footer: footer(for: preference)) {
                        preferenceView(for: preference, at: index)
                    }
                }
            }

            .navigationBarTitle("Preferences")
        }.navigationBarItems(trailing: applyButton)
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text("Preferences have been successfully saved."),
                    dismissButton: .default(Text("OK"))
                )
            }
        
    }
    
    private var applyButton: some View {
        Button("Apply", action: applyChanges)
    }
    
    private func header(for preference: InstalledPackage.Preference) -> some View {
        Text(preference.title)
    }
    
    private func footer(for preference: InstalledPackage.Preference) -> some View {
        Text(preference.description)
            .font(.subheadline)
            .foregroundColor(.gray)
    }
    
    private func preferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
            switch preference.valueType {
            case "color":
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
            default:
                return AnyView(unsupportedPreferenceView(preference.valueType))
            }
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

    private func pickerPreferenceView(for preference: InstalledPackage.Preference, at index: Int) -> some View {
        Picker(selection: Binding<Int>(
            get: {
                if let selectedIndex = preference.options?.firstIndex(of: tempPreferences[preference.key] as? String ?? "") {
                    return selectedIndex
                }
                return 0 // Default to the first option
            },
            set: { newValue in
                if let selectedOption = preference.options?[newValue] as? String {
                    tempPreferences[preference.key] = selectedOption
                }
            }
        ), label: Text(preference.title)) {
            ForEach(preference.options ?? [], id: \.self) { option in
                Text(option)
                    .tag(option) // Use the option itself as the tag
            }
        }
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
        let upperBound = preference.optionValues?.last ?? 100
        
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
            
            Text("Range: \(lowerBound) - \(upperBound)")
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
            
            Text("Range: \(lowerBound) - \(upperBound)")
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
        
        for (key, value) in tempPreferences {
            if let preferenceValue = value as? PreferenceValue {
                encodedPreferences[key] = preferenceValue
            } else if let color = value as? Color {
                encodedPreferences[key] = .color(color)
            }
            // Handle other types as needed
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
            return false // Return false to indicate failure
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
                decoder.keyDecodingStrategy = .convertFromSnakeCase // If your keys are in snake_case format
                
                // Decode the preferences dictionary from the config.json data
                let preferencesDict = try decoder.decode([String: PreferenceValue].self, from: configData)
                
                // Apply the decoded preferences to tempPreferences
                tempPreferences = preferencesDict
            }
        } catch {
            print("Error loading preferences from config.json: \(error)")
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
                Text(installedPackage.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
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
    struct Preference: Codable, Hashable {
        let valueType: String
        let key: String
        let options: Array<String>?
        let optionValues: Array<Int>?
        let title: String
        let description: String
    }
    
    var savedPreferences: [String: PreferenceValue] = [:]
    var preferences: [Preference]
    
    static func == (lhs: InstalledPackage, rhs: InstalledPackage) -> Bool {
        return lhs.id == rhs.id
    }
}

func getInstalledPackages() -> [InstalledPackage] {
    let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed")
    
    do {
        let installedFolders = try FileManager.default.contentsOfDirectory(at: installedFolderPath, includingPropertiesForKeys: nil, options: [])
        var installedPackages: [InstalledPackage] = []
        
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
                        
                        let preference = InstalledPackage.Preference(valueType: valueType, key: key, options: options, optionValues: optionValues, title: title, description: description)
                        preferences.append(preference)
                    }
                }
                
                let installedPackage = InstalledPackage(name: name, author: author, version: version, bundleID: bundleID, icon: iconURL, preferences: preferences)
                installedPackages.append(installedPackage)
            }
        }
        
        return installedPackages
    } catch {
        print("Error fetching installed packages: \(error)")
        return []
    }
}
