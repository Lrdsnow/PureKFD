//
//  SettingsView.swift
//  purekfd
//
//  Created by Lrdsnow on 7/4/24.
//

import SwiftUI
import NukeUI

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            ScrollView(.vertical) {
                DeviceRow()
                ExploitRow()
                ThemeRow()
                CreditViewNavLink()
            }.padding()
        }
    }
}

struct DeviceRow: View {
    var body: some View {
        HStack {
            HStack {
                LazyImage(url: URL(string: "https://ipsw.me/assets/devices/\(DeviceInfo.modelName).png")) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }.frame(width: 80, height: 80).cornerRadius(11).padding(.trailing, 3)
                VStack(alignment: .leading) {
                    Text(DeviceInfo.prettyModel ?? DeviceInfo.modelName).font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                    Text("\(DeviceInfo.modelName) (\(DeviceInfo.cpu))").font(.subheadline.weight(.semibold)).minimumScaleFactor(0.8).lineLimit(1).opacity(0.8).foregroundColor(.accentColor)
                    Text("\(DeviceInfo.osString) \(DeviceInfo.version)\(DeviceInfo.build == "" ? "" : " (\(DeviceInfo.build))")").font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).opacity(0.7).foregroundColor(.accentColor)
                    Text("PureKFD v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")").font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).opacity(0.7).foregroundColor(.accentColor)
                }
                Spacer()
            }.padding()
        }.background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1)))
    }
}

struct ExploitRow: View {
    @AppStorage("selectedExploit") var exploit = 0
    @AppStorage("FilterPackages") var filterPackages = true
    @AppStorage("savedExploitSettings") var savedSettings: [String: String] = [:]
    let exploits = ExploitHandler.exploits
    
    var body: some View {
        VStack {
            HStack {
                Text("Exploit Settings").font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                Spacer()
            }.padding(.horizontal).padding(.top).padding(.bottom, 7)
            
            if !ExploitHandler.isExploitCompatible(exploit) {
                Text("\(Image(systemName: "exclamationmark.circle.fill")) Warning: Your device is not compatible with this exploit").foregroundColor(.accentColor).lineLimit(1).minimumScaleFactor(0.2).padding(.horizontal)
            }
            
            HStack {
                Text("Exploit").minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                Spacer()
                Picker(selection: $exploit, content: {
                    ForEach(exploits.indices, id:\.self) { _exploit in
                        Text(exploits[_exploit].name).tag(_exploit)
                    }
                }, label: { Text("Exploit") }).pickerStyle(.menu).animation(.none)
            }.padding(.leading)
            
            if exploits[exploit].varOnly {
                Toggle("Filter Tweaks", isOn: $filterPackages)
                    .padding(.horizontal)
                    .foregroundColor(.accentColor)
                    .tint(.accentColor)
            }
            
            VStack {
                let settings = exploits[exploit].settings
                if !settings.isEmpty {
                    ForEach(settings.keys.sorted(), id: \.self) { key in
                        let keyComponents = key.split(separator: "_")
                        let name = keyComponents.count > 1 ? String(keyComponents.last!) : key
                        let hidden = ((savedSettings[String(keyComponents.first ?? "")] ?? "true") != "true" && key.contains("_"))
                        
                        if let value = settings[key], !hidden {
                            switch value {
                            case "Bool":
                                Toggle(name, isOn: Binding(
                                    get: { self.savedSettings[key] == "true" },
                                    set: { newValue in self.savedSettings[key] = newValue ? "true" : "false" }
                                ))
                                .padding(.horizontal)
                                .foregroundColor(.accentColor)
                                .tint(.accentColor)
                                
                            case let options where options.contains(","):
                                let optionList = options.split(separator: ",").map(String.init)
                                HStack {
                                    Text(name)
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
                                        .foregroundColor(.accentColor)
                                    Spacer()
                                    Picker(name, selection: Binding(
                                        get: { self.savedSettings[key] ?? optionList.first ?? "" },
                                        set: { newValue in self.savedSettings[key] = newValue }
                                    )) {
                                        ForEach(optionList, id: \.self) { option in
                                            Text(option).tag(option)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                                .padding(.leading)
                                
                            case "Double":
                                let doubleValue = Binding(
                                    get: { Double(self.savedSettings[key] ?? "0.0") ?? 0.0 },
                                    set: { newValue in self.savedSettings[key] = "\(newValue)" }
                                )
                                VStack {
                                    Slider(value: doubleValue, in: 0...100)
                                    Text("Value: \(doubleValue.wrappedValue, specifier: "%.2f")")
                                }
                            
                            case "FilePicker":
                                FilePickerButton(key: key).padding(.horizontal).padding(.vertical, 5)
                            
                            default:
                                Text("Unknown type for key: \(key)")
                            }
                        }
                        
                    }
                }
            }.padding(.bottom, 15)
        }.background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1))).animation(.spring)
    }
}

struct FilePickerButton: View {
    let key: String
    @State private var isPresented = false
    @State private var selectedFile = false
    
    var body: some View {
        Button(action: {
            isPresented = true
        }, label: {
            HStack {
                Text("Select File")
                Spacer()
                if selectedFile {
                    Image(systemName: "checkmark")
                } else {
                    Text(key)
                }
            }
        })
        .onAppear() {
            if FileManager.default.fileExists(atPath: URL.documents.appendingPathComponent("imported").appendingPathComponent(key).path) {
                selectedFile = true
            }
        }
        .fileImporter(isPresented: $isPresented, allowedContentTypes: [.item], onCompletion: { result in
            switch result {
            case .success(let url):
                url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let importedFolderURL = URL.documents.appendingPathComponent("imported")
                    try FileManager.default.createDirectory(at: importedFolderURL, withIntermediateDirectories: true, attributes: nil)
                    let destinationURL = importedFolderURL.appendingPathComponent(key)
                    try? FileManager.default.removeItem(at: destinationURL)
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    selectedFile = true
                } catch {
                    print("Failed to move or process file: \(error)")
                    selectedFile = false
                }
            case .failure(let error):
                print("Failed to import file: \(error)")
                selectedFile = false
            }
        })
    }
}

struct ThemeRow: View {
    @AppStorage("accentColor") private var accentColor: Color = Color(hex: "#D4A7FC")!
    
    var body: some View {
        
        VStack {
            HStack {
                Text("Theme Settings").font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                Spacer()
            }.padding(.horizontal).padding(.top).padding(.bottom, 7)
            VStack {
                ColorPicker(selection: $accentColor, label: { Text("Accent Color") }).foregroundColor(accentColor)
            }.padding(.bottom, 15).padding(.horizontal)
        }.background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1)))
    }
}

struct CreditViewNavLink: View {
    var body: some View {
        VStack {
            HStack {
                NavigationLink(destination: CreditsView(), label: {
                    Text("Credits")
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.accentColor).font(.footnote)
                })
            }.padding()
        }.background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1)))
    }
}

struct CreditsView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            VStack {
                Button(action: {
                    if let url = URL(string: "https://github.com/Lrdsnow") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    CreditView(name: "Lrdsnow", role: "Developer", icon: URL(string: "https://github.com/lrdsnow.png")!)
                }
                Spacer()
            }.padding().navigationBarTitle("Credits")
        }
    }
}

struct CreditView: View {
    let name: String
    let role: String
    let icon: URL
    @State private var accent: Color? = nil
    
    var body: some View {
        HStack {
            HStack {
                LazyImage(url: icon) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .background(Color.black)
                            .onAppear() {
                                if accent == nil,
                                   UserDefaults.standard.bool(forKey: "useAvgImageColors") {
                                    if let uiImage = state.imageContainer?.image,
                                       let accentColor = averageColor(from: uiImage) {
                                        accent = Color(accentColor.bright())
                                    }
                                }
                            }
                    } else if state.error != nil {
                        appIconImage
                            .resizable()
                            .scaledToFill()
                    } else {
                        ProgressView()
                            .scaledToFit()
                    }
                }.frame(width: 45, height: 45).cornerRadius(11).padding(.trailing, 3)
                VStack(alignment: .leading) {
                    Text(name).font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(accent ?? .accentColor)
                    Text(role).font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).opacity(0.7).foregroundColor(accent ?? .accentColor)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(accent ?? .accentColor).font(.footnote)
            }.padding()
        }.background(RoundedRectangle(cornerRadius: 25).foregroundColor((accent ?? .accentColor).opacity(0.1)))
    }
}
