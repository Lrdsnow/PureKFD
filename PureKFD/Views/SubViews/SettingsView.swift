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
            #if os(iOS)
            Color.accentColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            #endif
            ScrollView(.vertical) {
                DeviceRow()
                ExploitRow()
                #if os(iOS)
                ThemeRow()
                EnvVarViewNavLink()
                CreditViewNavLink()
                #elseif os(macOS)
                CreditsView().padding(.top)
                #endif
            }.padding()
            #if os(macOS)
                .navigationTitle("Settings")
            #endif
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
                }
                #if os(macOS)
                .frame(width: 120, height: 80)
                #else
                .frame(width: 80, height: 80)
                #endif
                .cornerRadius(11).padding(.trailing, 3)
                VStack(alignment: .leading) {
                    Text(DeviceInfo.prettyModel ?? DeviceInfo.modelName).font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1)
#if os(iOS)
                        .foregroundColor(.accentColor)
                    #endif
                    Text("\(DeviceInfo.modelName) (\(DeviceInfo.cpu))").font(.subheadline.weight(.semibold)).minimumScaleFactor(0.8).lineLimit(1).opacity(0.8)
#if os(iOS)
                        .foregroundColor(.accentColor)
#endif
                    Text("\(DeviceInfo.osString) \(DeviceInfo.version)\(DeviceInfo.build == "" ? "" : " (\(DeviceInfo.build))")").font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).opacity(0.7)
                    #if os(iOS)
                        .foregroundColor(.accentColor)
                    #endif
                    #if !os(macOS)
                    Text("PureKFD v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")").font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).opacity(0.7).foregroundColor(.accentColor)
                    #else
                    Text("PureRestore v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")").font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).opacity(0.7)
                    #endif
                }
                Spacer()
            }.padding()
        }
        #if os(iOS)
        .background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1)))
        #endif
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
                Text("Exploit Settings").font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1)
#if os(iOS)
                    .foregroundColor(.accentColor)
#endif
                Spacer()
            }.padding(.horizontal).padding(.top).padding(.bottom, 7)
            
#if os(iOS)
            if !ExploitHandler.isExploitCompatible(exploit) {
                Text("\(Image(systemName: "exclamationmark.circle.fill")) Warning: Your device is not compatible with this exploit").foregroundColor(.accentColor).lineLimit(1).minimumScaleFactor(0.2).padding(.horizontal)
            }
#endif
            
            HStack {
#if os(iOS)
                Text("Exploit").minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                Spacer()
#endif
                Picker(selection: $exploit, content: {
                    ForEach(exploits.indices, id:\.self) { _exploit in
                        Text(exploits[_exploit].name).tag(_exploit)
                    }
                }, label: { Text("Exploit") }).pickerStyle(.menu).animation(.none)
            }.padding(.leading)
            
            if exploits[exploit].varOnly {
                HStack {
                    Toggle("Filter Tweaks", isOn: $filterPackages)
                        .padding(.horizontal)
#if os(iOS)
                        .foregroundColor(.accentColor)
                        .tint(.accentColor)
#endif
                    #if os(macOS)
                    Spacer()
                    #endif
                }
            }
            
            VStack(alignment: DeviceInfo.osString == "macOS" ? .leading : .center) {
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
#if os(iOS)
                                .foregroundColor(.accentColor)
                                .tint(.accentColor)
#endif
                                
                            case let options where options.contains(","):
                                let optionList = options.split(separator: ",").map(String.init)
                                HStack {
                                    Text(name)
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
#if os(iOS)
                                        .foregroundColor(.accentColor)
#endif
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
            }
#if os(iOS)
            .padding(.bottom, 15)
#endif
        }
#if os(iOS)
        .background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1)))
#endif
        .animation(.spring)
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
        }
        #if os(iOS)
        .background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1)))
        #endif
    }
}

struct EnvVarViewNavLink: View {
    var body: some View {
        VStack {
            HStack {
                NavigationLink(destination: EnvVarView(), label: {
                    Text("Environment Variables")
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.accentColor).font(.footnote)
                })
            }.padding()
        }
#if os(iOS)
        .background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1)))
        #endif
    }
}

struct EnvVarView: View {
    @AppStorage("saveEnv") var env: [String:String] = [:]
    @State private var newKey = ""
    @State private var newValue = ""
    
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            List {
                ForEach(env.keys.sorted(), id: \.self) { key in
                    HStack {
                        TextField("Key", text: Binding(
                            get: { key },
                            set: { newKey in
                                if let value = env.removeValue(forKey: key) {
                                    env[newKey] = value
                                }
                            })
                        )
                        Spacer()
                        TextField("Value", text: Binding(
                            get: { env[key] ?? "" },
                            set: { newValue in
                                env[key] = newValue
                            })
                        )
                    }.listRowBackground(Color.accentColor.opacity(0.1)).listRowSeparator(.hidden)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let key = env.keys.sorted()[index]
                        env.removeValue(forKey: key)
                    }
                }
                Section {
                    TextField("New Key", text: $newKey)
                    TextField("New Value", text: $newValue)
                    Button(action: {
                        if !newKey.isEmpty && !newValue.isEmpty {
                            env[newKey] = newValue
                            newKey = ""
                            newValue = ""
                        }
                    }) {
                        Text("Add Variable")
                    }
                }.listRowBackground(Color.accentColor.opacity(0.1)).listRowSeparator(.hidden)
                Section {
                    Button(action: {
                        showConfirmPopup("Confirm", "This will reset Environment Variables to default", completion: { confirmed in
                            if confirmed {
                                SaveEnv().reset()
                            }
                        })
                    }, label: {
                        Text("Reset Variables")
                    })
                }.listRowBackground(Color.accentColor.opacity(0.1)).listRowSeparator(.hidden)
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .clearListBG()
        }
        .navigationTitle("Environment Variables")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
        }
#if os(iOS)
        .background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1)))
        #endif
    }
}

struct CreditsView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        ZStack {
            #if os(iOS)
            Color.accentColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            #endif
            VStack {
                #if os(macOS)
                HStack {
                    Text("Credits").font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1)
                    Spacer()
                }.padding(.horizontal).padding(.bottom, -5)
                #endif
                Button(action: {
                    if let url = URL(string: "https://github.com/Lrdsnow") {
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #elseif os(macOS)
                        NSWorkspace.shared.open(url)
                        #endif
                    }
                }) {
                    CreditView(name: "Lrdsnow", role: "Developer", icon: URL(string: "https://github.com/lrdsnow.png")!)
                }
                #if os(macOS)
                .buttonStyle(.plain)
                #endif
                Spacer()
            }
            #if os(iOS)
            .padding()
            .navigationTitle("Credits")
            #endif
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
#if os(iOS)
                            .onAppear() {
                                if accent == nil,
                                   UserDefaults.standard.bool(forKey: "useAvgImageColors") {
                                    if let uiImage = state.imageContainer?.image,
                                       let accentColor = averageColor(from: uiImage) {
                                        accent = Color(accentColor.bright())
                                    }
                                }
                            }
#endif
                    } else if state.error != nil {
#if os(iOS)
                        appIconImage
                            .resizable()
                            .scaledToFill()
#else
                        ProgressView()
                            .scaledToFit()
#endif
                    } else {
                        ProgressView()
                            .scaledToFit()
                    }
                }.frame(width: 45, height: 45).cornerRadius(11).padding(.trailing, 3)
                VStack(alignment: .leading) {
                    Text(name).font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1)
#if os(iOS)
                        .foregroundColor(accent ?? .accentColor)
#endif
                    Text(role).font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).opacity(0.7)
#if os(iOS)
                        .foregroundColor(accent ?? .accentColor)
#endif
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(accent ?? .accentColor).font(.footnote)
            }
            .padding()
        }
#if os(iOS)
        .background(RoundedRectangle(cornerRadius: 25).foregroundColor((accent ?? .accentColor).opacity(0.1)))
#endif
    }
}
