//
//  InstalledView.swift
//  purekfd
//
//  Created by Lrdsnow on 6/26/24.
//

import SwiftUI
import Alamofire
import Zip
import JASON
#if canImport(SwiftKFD_objc)
import SwiftKFD_objc
#else
extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
#endif

struct InstalledView: View {
    @EnvironmentObject var appData: AppData
    @Binding var installing: Bool
    @State private var searchText: String = ""
    @State private var showErrorSheet: Bool = false
    @State private var showTweakSettings: Bool = false
    @State private var selectedTweak: Package? = nil
    @State private var prefJSON: String = ""
    @State private var selectedPkg: Package? = nil
    @AppStorage("saveEnv") var saveEnv: [String:String] = [:]
    @AppStorage("savedExploitSettings") var savedSettings: [String: String] = [:]
    @AppStorage("accentColor") private var accentColor: Color = Color(hex: "#D4A7FC")!
    
    var body: some View {
        NavigationViewC {
            ZStack(alignment: .bottom) {
#if !os(macOS)
                Color.accentColor
                    .ignoresSafeArea(.all)
                    .opacity(0.07)
#endif
                
                ScrollView(.vertical) {
                    VStack {
#if !os(macOS)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Installed").font(.system(size: 36, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                            }
                            Spacer()
                        }.padding(.leading, 1)
                        HStack {
                            TextField("Search", text: $searchText)
                                .padding(.horizontal, 25)
                                .padding()
                                .autocorrectionDisabled()
                                .overlay(
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.accentColor.opacity(0.7))
                                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading, 15)
                                        
                                        if !searchText.isEmpty {
                                            Button(action: {
                                                self.searchText = ""
                                            }) {
                                                Image(systemName: "multiply.circle.fill")
                                                    .foregroundColor(.accentColor.opacity(0.7))
                                                    .padding(.trailing, 15)
                                            }
                                        }
                                    }
                                )
                        }.background(RoundedRectangle(cornerRadius: 25).foregroundColor(.accentColor.opacity(0.1))).padding(.bottom, 2)
                        HStack {
                            Button(action: {
                                TweakHandler.applyTweaks(pkgs: appData.installed_pkgs, appData.selectedExploit, .overwrite, savedSettings, saveEnv)
                            }, label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "sparkles")
                                    Text("Apply").font(.headline.bold())
                                    Spacer()
                                }.padding()
                            }).background(RoundedRectangle(cornerRadius: 25).foregroundColor(Color.accentColor.opacity(0.1))).contextMenu(menuItems: {
                                Button(action: {
                                    TweakHandler.applyTweaks(pkgs: appData.installed_pkgs, appData.selectedExploit, .restore, savedSettings, saveEnv)
                                }, label: {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Restore All").font(.headline.bold())
                                        Spacer()
                                    }
                                })
                            })
                            let reboot_action = ExploitHandler.exploits[appData.selectedExploit].reboot == true
                            Button(action: {
                                if reboot_action {
                                    let loading = showLoadingPopup()
                                    Task.detached {
                                        if let error = ExploitHandler.reboot(appData.selectedExploit) {
                                            DispatchQueue.main.async {
#if !os(macOS)
                                                loading.dismiss(animated: true) {
                                                    showPopup("Error", error)
                                                }
#else
                                                loading.window.orderOut(nil)
                                                showPopup("Error", error)
#endif
                                            }
                                        }
                                    }
                                } else {
                                    restartBackboard()
                                }
                            }, label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.clockwise")
                                    Text(reboot_action ? "Reboot" : "Respring").font(.headline.bold())
                                    Spacer()
                                }.padding()
                            }).background(RoundedRectangle(cornerRadius: 25).foregroundColor(Color.accentColor.opacity(0.1))).contextMenu(menuItems: {
                                Button(action: {
                                    restartBackboard()
                                }, label: {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Backboard Respring").font(.headline.bold())
                                        Spacer()
                                    }
                                })
                                Button(action: {
                                    restartFrontboard()
                                }, label: {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Frontboard Respring").font(.headline.bold())
                                        Spacer()
                                    }
                                })
                            })
                        }
#endif
                        if !appData.queued_pkgs.isEmpty {
                            Section(content: {
                                ForEach(appData.queued_pkgs, id:\.0.bundleid) { tweak in
                                    TweakListRowView(tweak: tweak.0, navlink: false, installing: $installing).contextMenu(menuItems: {
                                        if tweak.0.error != nil {
                                            Button(action: {
                                                selectedPkg = tweak.0
                                                showErrorSheet = true
                                            }, label: {
                                                HStack {
                                                    Text("Error Info")
                                                    Spacer()
                                                    Image(systemName: "exclamationmark.circle.fill")
                                                }
                                            })
                                        }
                                        Button(action: {
                                            appData.queued_pkgs.removeAll(where: { $0.0.bundleid == tweak.0.bundleid })
                                        }, label: {
                                            HStack {
                                                Text("Remove from Queue")
                                                Spacer()
                                                Image(systemName: "clock.fill")
                                            }
                                        })
                                    })
                                }
                            }, header: {
                                HStack {
#if os(iOS)
                                    Image(systemName: "clock.fill")
                                    #endif
                                    Text("Queued").font(.title2.bold())
                                    Spacer()
                                }
#if os(iOS)
                                .foregroundColor(.accentColor).padding(.bottom, -2)
                                #endif
                            }).padding(.bottom, 2)
                        }
                        if !appData.installed_pkgs.isEmpty {
                            Section(content: {
                                ForEach(appData.installed_pkgs, id:\.bundleid) { tweak in
                                    TweakListRowView(tweak: tweak, navlink: false).opacity(tweak.disabled == true ? 0.7 : 1)
                                        .contextMenu(menuItems: {
                                            Button(action: {
                                                selectedPkg = tweak
                                                showErrorSheet = true
                                            }, label: {
                                                if tweak.error != nil {
                                                    HStack {
                                                        Text("Error Info")
                                                        Spacer()
                                                        Image(systemName: "exclamationmark.circle.fill")
                                                    }
                                                } else {
                                                    HStack {
                                                        Text("Force Repair")
                                                        Spacer()
                                                        Image(systemName: "wrench.and.screwdriver.fill")
                                                    }
                                                }
                                            })
                                            
                                            if tweak.installed {
                                                Button(action: {
                                                    prefJSON = ""
                                                    selectedTweak = tweak
                                                    showTweakSettings = true
                                                }, label: {
                                                    HStack {
                                                        Text("Tweak Settings")
                                                        Spacer()
                                                        Image(systemName: "gearshape.fill")
                                                    }
                                                })
                                            }
                                            
                                            Button(action: {
                                                if let index = appData.installed_pkgs.firstIndex(where: { $0.bundleid == tweak.bundleid }) {
                                                    if tweak.disabled == true {
                                                        appData.installed_pkgs[index].disabled = false
                                                    } else {
                                                        appData.installed_pkgs[index].disabled = true
                                                    }
                                                    appData.installed_pkgs[index].save()
                                                }
                                            }, label: {
                                                HStack {
                                                    Text("\(tweak.disabled == true ? "Enable" : "Disable") Tweak")
                                                    Spacer()
                                                    Image(systemName: tweak.disabled == true ? "checkmark.circle" : "circle.slash")
                                                }
                                            })
                                            
                                            if tweak.hasRestore {
                                                Button(action: {
                                                    TweakHandler.applyTweak(pkg: tweak, appData.selectedExploit, .restore, saveEnv)
                                                }, label: {
                                                    HStack {
                                                        Text("Restore Files")
                                                        Spacer()
                                                        Image(systemName: "arrow.counterclockwise")
                                                    }
                                                })
                                            }
                                            
                                            Button(role: .destructive, action: {
                                                showConfirmPopup("Confirm", "Are you sure you'd like to uninstall this tweak") { confirm in
                                                    if confirm {
                                                        try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("pkgs").appendingPathComponent(tweak.bundleid))
                                                        appData.installed_pkgs.removeAll(where: { $0.bundleid == tweak.bundleid })
                                                    }
                                                }
                                            }, label: {
                                                HStack {
                                                    Text("Uninstall Tweak")
                                                    Spacer()
                                                    Image(systemName: "trash")
                                                }
                                            })
                                        })
                                }
                            }, header: {
#if os(iOS)
                                HStack {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("Installed").font(.title2.bold())
                                    Spacer()
                                }
                                .foregroundColor(.accentColor)
                                .padding(.bottom, -2)
#else
                                if !appData.queued_pkgs.isEmpty {
                                    HStack {
                                        Text("Installed").font(.title2.bold())
                                        Spacer()
                                    }
                                }
#endif
                            })
                        }
#if os(macOS)
                        if appData.installed_pkgs.isEmpty && appData.queued_pkgs.isEmpty {
                            Text("No Installed Tweaks")
                        }
#endif
                        NavigationLink(destination: PrefView(selectedTweak: $selectedTweak, jsonString: $prefJSON).onDisappear() { selectedTweak = nil }, isActive: $showTweakSettings, label: {Text("test")}).opacity(0.01).onTapGesture {}
                    }.padding()
                    #if os(iOS)
                        .padding(.top, 27)
                    #endif
                        .animation(.spring)
#if os(macOS)
                        .searchable(text: $searchText)
#endif
                }
                #if !os(macOS)
                if !appData.queued_pkgs.isEmpty {
                    Button(action: {
                        withAnimation(.spring) {
                            installing = true
                            installTweaks(appData, $installing)
                        }
                    }, label: {
                        HStack {
                            Spacer()
                            if installing {
                                ProgressView().tint(.accentColor)
                            } else {
                                Text("Install Tweaks").font(.headline.bold())
                            }
                            Spacer()
                        }.padding()
                    }).background(RoundedRectangle(cornerRadius: 25).foregroundColor(Color.accentColor.opacity(0.1))).padding()
                }
                #endif
            }.onAppear() {
                updateInstalledTweaks(appData)
            }.sheet(isPresented: $showErrorSheet) {
                ErrorInfoPageView(pkg: $selectedPkg, repo: .constant(nil)).accentColor(accentColor)
            }
        }
#if os(macOS)
        .navigationTitle("Installed")
        .toolbar {
            if !appData.queued_pkgs.isEmpty {
                ToolbarItem {
                    Button(action: {
                        withAnimation(.spring) {
                            installing = true
                            installTweaks(appData, $installing)
                        }
                    }, label: {
                        if installing {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                    })
                }
            }
            ToolbarItem {
                Button(action: {
                    TweakHandler.applyTweaks(pkgs: appData.installed_pkgs, appData.selectedExploit, .overwrite, savedSettings, saveEnv)
                }, label: {
                    Image(systemName: "sparkles")
                }).help("Apply Tweaks")
            }
            ToolbarItem {
                Button(action: {
                    let loading = showLoadingPopup()
                    Task.detached {
                        if let error = ExploitHandler.reboot(appData.selectedExploit) {
                            DispatchQueue.main.async {
                                loading.window.orderOut(nil)
                                showPopup("Error", error)
                            }
                        }
                    }
                }, label: {
                    Image(systemName: "arrow.clockwise")
                }).help("Reboot Device")
            }
        }
#endif
    }
    
    func findFileOrFolder(_ url: URL, _ names: [String]) -> [URL] {
        var result = [URL]()
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) else {
            return result
        }
        
        for case let fileURL as URL in enumerator {
            if names.contains(fileURL.lastPathComponent) {
                result.append(fileURL)
            }
        }
        
        return result
    }
    
    func installTweaks(_ appData: AppData, _ installing: Binding<Bool>) {
        for tweak in appData.queued_pkgs {
            if let url = tweak.0.path {
                Task {
                    AF.request(url)
                        .downloadProgress { progress in
                            if let tweakIndex = appData.queued_pkgs.firstIndex(where: { $0.0.bundleid == tweak.0.bundleid }) {
                                appData.queued_pkgs[tweakIndex].1 = progress.fractionCompleted
                            }
                        }
                        .responseData { response in
                            switch response.result {
                            case .success(let data):
                                let pkgs_dir = URL.documents.appendingPathComponent("pkgs")
                                let fm = FileManager.default
                                try? fm.createDirectory(at: pkgs_dir, withIntermediateDirectories: true)
                                var unzipdir: URL? = nil
                                let url = fm.temporaryDirectory.appendingPathComponent("\(UUID()).zip")
                                do {
                                    try data.write(to: url)
                                    unzipdir = try Zip.quickUnzipFile(url, progress: { progress in  if let tweakIndex = appData.queued_pkgs.firstIndex(where: { $0.0.bundleid == tweak.0.bundleid }) { appData.queued_pkgs[tweakIndex].1 = progress } })
                                    let pkg_dir = pkgs_dir.appendingPathComponent(tweak.0.bundleid)
                                    let unzip_pkg_dir = unzipdir!.appendingPathComponent(tweak.0.bundleid)
                                    if fm.fileExists(atPath: unzip_pkg_dir.appendingPathComponent("tweak.json").path) || fm.fileExists(atPath: unzip_pkg_dir.appendingPathComponent("Overwrite").path) {
                                        try fm.moveItem(at: unzip_pkg_dir, to: pkg_dir)
                                    } else {
                                        if let folder = findFileOrFolder(unzip_pkg_dir, ["tweak.json", "Overwrite"]).first?.deletingLastPathComponent() {
                                            try fm.moveItem(at: folder, to: pkg_dir)
                                        } else {
                                            throw "Tweak folder was not found in package!"
                                        }
                                    }
                                    // less code, and we dont have to worry about optimization bcuz its the download process
                                    let temp_tweak_json_data = (try? JSONEncoder().encode(tweak.0)) ?? Data()
                                    var temp_tweak = Package((try? JSONSerialization.jsonObject(with: temp_tweak_json_data, options: []) as? [String: Any]) ?? [:], tweak.0.repo, nil)
                                    //
                                    try? fm.moveItem(at: temp_tweak.pkgpath.appendingPathComponent("overwrite"), to: temp_tweak.pkgpath.appendingPathComponent("Overwrite")) // fix common issue
                                    try? fm.moveItem(at: temp_tweak.pkgpath.appendingPathComponent("restore"), to: temp_tweak.pkgpath.appendingPathComponent("Restore")) // fix common issue 2
                                    temp_tweak.repo = nil
                                    temp_tweak.installed = true
                                    let configJsonPath = pkg_dir.appendingPathComponent(config_filename).path
                                    if !temp_tweak.hasprefs {
                                        if let error = quickConvertLegacyEncrypted(pkg_dir: pkg_dir, configJsonPath: configJsonPath) {
                                            if !error.contains("does not exist") {
                                                temp_tweak.error = error
                                            }
                                        } else {
                                            temp_tweak.hasprefs = true
                                        }
                                    }
                                    if !temp_tweak.hasprefs {
                                        if let error = quickConvertPicasso(pkg_dir: pkg_dir, configJsonPath: configJsonPath) {
                                            if !error.contains("does not exist") {
                                                temp_tweak.error = error
                                            }
                                        } else {
                                            temp_tweak.hasprefs = true
                                        }
                                    }
                                    if !temp_tweak.hasprefs {
                                        if let error = quickConvertLegacyPKFD(pkg_dir: pkg_dir, configJsonPath: configJsonPath) {
                                            if !error.contains("does not exist") {
                                                temp_tweak.error = error
                                            }
                                        } else {
                                            temp_tweak.hasprefs = true
                                        }
                                    }
                                    if !temp_tweak.hasprefs {
                                        temp_tweak.hasprefs = fm.fileExists(atPath: configJsonPath)
                                    }
                                    if FileManager.default.fileExists(atPath: pkg_dir.appendingPathComponent("tweak.json").path) {
                                        if let error = quickConvertLegacyTweak(pkg: temp_tweak) {
                                            temp_tweak.error = error
                                        }
                                    }
                                    if let error = quickConvertLegacyOverwriteTweak(pkg: temp_tweak) {
                                        temp_tweak.error = error
                                    }
                                    let jsonData = try JSONEncoder().encode(temp_tweak)
                                    try jsonData.write(to: pkg_dir.appendingPathComponent("_info.json"))
                                    appData.installed_pkgs.append(temp_tweak)
                                    if let tweakIndex = appData.queued_pkgs.firstIndex(where: { $0.0.bundleid == tweak.0.bundleid }) {
                                        appData.queued_pkgs.remove(at: tweakIndex)
                                    }
                                } catch {
                                    if let tweakIndex = appData.queued_pkgs.firstIndex(where: { $0.0.bundleid == tweak.0.bundleid }) {
                                        appData.queued_pkgs[tweakIndex].2 = error
                                        appData.queued_pkgs[tweakIndex].0.error = error.localizedDescription
                                    }
                                }
                                if let unzipdir = unzipdir {
                                    try? fm.removeItem(at: unzipdir)
                                }
                                try? fm.removeItem(at: url)
                                if !appData.queued_pkgs.contains(where: { $0.2 == nil })  {
                                    withAnimation(.spring) {
                                        _installing.wrappedValue = false
                                    }
                                }
                            case .failure(let error):
                                if let tweakIndex = appData.queued_pkgs.firstIndex(where: { $0.0.bundleid == tweak.0.bundleid }) {
                                    appData.queued_pkgs[tweakIndex].2 = error
                                    appData.queued_pkgs[tweakIndex].0.error = error.localizedDescription
                                }
                                if !appData.queued_pkgs.contains(where: { $0.2 == nil })  {
                                    withAnimation(.spring) {
                                        _installing.wrappedValue = false
                                    }
                                }
                            }
                        }
                }
            }
        }
    }
}

struct ErrorInfoPageView: View {
    @Binding var pkg: Package?
    @Binding var repo: Repo?
    @State private var fixes: [Solution] = []
    @EnvironmentObject var appData: AppData
    @State private var subView = AnyView(EmptyView())
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.accentColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
                .background(Color.black)
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        if let title = pkg?.bundleid ?? repo?.description {
                            Text(title).font(.system(size: 30, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                        }
                        Text("Error:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                    }
                    Spacer()
                }.padding(.leading, 1).padding(.bottom, -3)
                HStack {
                    Text(pkg?.error ?? repo?.error ?? "No Error").foregroundColor(.accentColor)
                    Spacer()
                }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                subView
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(fixes, id:\.text) { fix in
                            if fix.button {
                                Button(action: fix.function, label: {
                                    Text(fix.text).padding()
                                }).background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                            } else {
                                Text(fix.text).font(.system(size: 20, weight: .bold)).foregroundColor(.accentColor)
                            }
                        }
                    }
                    Spacer()
                }
            }.padding().padding(.vertical, 10).onAppear() {
                if let pkg = pkg {
                    fixes = getPkgSolutions(pkg)
                } else if let repo = repo {
                    fixes = getRepoSolutions(repo)
                }
            }
        }
    }
    
    struct Solution {
        let text: String
        let function: () -> Void
        let button: Bool
    }
    
    func getPkgSolutions(_ pkg: Package) -> [Solution] {
        var fixes: [Solution] = []
        let error = pkg.error?.lowercased() ?? ""
        let _tweak = appData.pkgs.first(where: { $0.bundleid == pkg.bundleid })
        let pkg_dir = pkg.pkgpath
        
        if error.contains("error decoding") || error == "" {
            fixes.append(
                Solution(text:"Attempt Repair", function: {
                    var overrideDebug = false
                    do {
                        var temp_tweak = pkg
                        if let _tweak = _tweak {
                            temp_tweak = _tweak
                            temp_tweak.repo = nil
                            let jsonData = try JSONEncoder().encode(temp_tweak)
                            let pkg_dir = temp_tweak.pkgpath
                            try jsonData.write(to: pkg_dir.appendingPathComponent("_info.json"))
                        } else {
                            if let jsonDict = try JSONSerialization.jsonObject(with: try Data(contentsOf: pkg_dir.appendingPathComponent("_info.json"))) as? [String:Any] {
                                temp_tweak = Package(jsonDict, nil, nil)
                                let jsonData = try JSONEncoder().encode(temp_tweak)
                                try jsonData.write(to: pkg_dir.appendingPathComponent("_info.json"))
                            } else {
                                throw "Error Decoding Tweak"
                            }
                        }
                        let configJsonPath = pkg_dir.appendingPathComponent(config_filename).path
                        do {
                            if let error = quickConvertLegacyEncrypted(pkg_dir: pkg_dir, configJsonPath: configJsonPath) {
                                if !error.contains("exist") {
                                    throw error
                                }
                            }
                            if let error = quickConvertPicasso(pkg_dir: pkg_dir, configJsonPath: configJsonPath) {
                                if !error.contains("exist") {
                                    throw error
                                }
                            }
                            if let error = quickConvertLegacyPKFD(pkg_dir: pkg_dir, configJsonPath: configJsonPath) {
                                if !error.contains("exist") {
                                    throw error
                                }
                            }
                        } catch {
                            var jsonURL: URL? = nil
                            if error.localizedDescription.contains("config.json") {
                                jsonURL = pkg_dir.appendingPathComponent("config.json")
                            } else if error.localizedDescription.contains("prefs.json") {
                                jsonURL = pkg_dir.appendingPathComponent("prefs.json")
                            }
                            if let jsonURL = jsonURL {
                                let data = try Data(contentsOf: jsonURL)
                                let _error = lintJSON(jsonData: data)
                                let json = (String(data: data, encoding: .utf8) ?? "").components(separatedBy: "\n")
                                overrideDebug = true
                                subView = AnyView (
                                    VStack {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("Repair Result:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                                            }
                                            Spacer()
                                        }.padding(.leading, 1).padding(.bottom, -3)
                                        HStack {
                                            Text("Failed to translate preferences: \(error.localizedDescription)").foregroundColor(.accentColor)
                                            Spacer()
                                        }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                                        
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("Debug:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                                            }
                                            Spacer()
                                        }.padding(.leading, 1).padding(.bottom, -3)
                                        HStack {
                                            Text(_error.0).foregroundColor(.accentColor)
                                            Spacer()
                                        }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                                        if let line = _error.1 {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("Debug Preview:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                                                }
                                                Spacer()
                                            }.padding(.leading, 1).padding(.bottom, -3)
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    if json.count >= line {
                                                        Text("\(line-2) \(json[line-2])").foregroundColor(.accentColor)
                                                        Text("\(line-1) \(json[line-1])").foregroundColor(.accentColor)
                                                        Text("\(line) \(json[line])").foregroundColor(.accentColor).background(Color.accentColor.opacity(0.1))
                                                        if json.count >= line+1 {
                                                            Text("\(line+1) \(json[line+1])").foregroundColor(.accentColor)
                                                            if json.count >= line+2 {
                                                                Text("\(line+2) \(json[line+2])").foregroundColor(.accentColor)
                                                            }
                                                        }
                                                    }
                                                }
                                                Spacer()
                                            }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                                        }
                                    }
                                )
                            } else {
                                throw "Error processing tweak preferences"
                            }
                        }
                        if FileManager.default.fileExists(atPath: pkg_dir.appendingPathComponent("tweak.json").path),
                           !FileManager.default.fileExists(atPath: pkg_dir.appendingPathComponent("Overwrite").path) {
                            quickConvertLegacyTweak(pkg: temp_tweak)
                        }
                        if !overrideDebug {
                            subView = AnyView(
                                VStack {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Repair Result:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                                        }
                                        Spacer()
                                    }.padding(.leading, 1).padding(.bottom, -3)
                                    HStack {
                                        Text("No errors occured on repair, please restart PureKFD").foregroundColor(.accentColor)
                                        Spacer()
                                    }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                                }
                            )
                        }
                    } catch {
                        subView = AnyView(
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Repair Result:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                                    }
                                    Spacer()
                                }.padding(.leading, 1).padding(.bottom, -3)
                                HStack {
                                    Text(error.localizedDescription ?? "An unknown error occured while attempting tweak repair").foregroundColor(.accentColor)
                                    Spacer()
                                }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                            }
                        )
                    }
                }, button: true)
            )
            if let _tweak = _tweak {
                fixes.append(
                    Solution(text:"Reinstall Tweak", function: {
                        showConfirmPopup("Confirm", "Are you sure you'd like to reinstall this tweak") { confirm in
                            if confirm {
                                try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("pkgs").appendingPathComponent(_tweak.bundleid))
                                if !appData.queued_pkgs.contains(where: { $0.0.bundleid == _tweak.bundleid }) {
                                    appData.queued_pkgs.append((_tweak, 0.0, nil))
                                    subView = AnyView(
                                        VStack {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("Result:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                                                }
                                                Spacer()
                                            }.padding(.leading, 1).padding(.bottom, -3)
                                            HStack {
                                                Text("The tweak was added to queue.").foregroundColor(.accentColor)
                                                Spacer()
                                            }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                                        }
                                    )
                                }
                            }
                        }
                    }, button: true)
                )
            }
        } else if error.contains("zip.ziperror error 1") {
            fixes.append(
                Solution(text:"This error is normally the result of a corrupt tweak, Please notify the tweak creator", function: {}, button: false)
            )
        } else {
            if let _tweak = _tweak {
                fixes.append(
                    Solution(text:"Reinstall Tweak", function: {
                        showConfirmPopup("Confirm", "Are you sure you'd like to reinstall this tweak") { confirm in
                            if confirm {
                                try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("pkgs").appendingPathComponent(_tweak.bundleid))
                                if !appData.queued_pkgs.contains(where: { $0.0.bundleid == _tweak.bundleid }) {
                                    appData.queued_pkgs.append((_tweak, 0.0, nil))
                                    subView = AnyView(
                                        VStack {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("Result:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                                                }
                                                Spacer()
                                            }.padding(.leading, 1).padding(.bottom, -3)
                                            HStack {
                                                Text("The tweak was added to queue.").foregroundColor(.accentColor)
                                                Spacer()
                                            }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                                        }
                                    )
                                }
                            }
                        }
                    }, button: true)
                )
            } else {
                fixes.append(
                    Solution(text:"No fix found for tweak and it does not appear to be available on any of the current repos", function: {}, button: false)
                )
            }
        }
        return fixes
    }
    
    func getRepoSolutions(_ repo: Repo) -> [Solution] {
        var fixes: [Solution] = []
        if let error = repo.error?.lowercased() {
            
            if error.contains("invalid json") {
                if let url = URL(string: repo.description) {
                    fixes.append(
                        Solution(text:"Debug Repo (Repo Creator)", function: {
                            AF.request(url).responseData { response in
                                switch response.result {
                                case .success(let data):
                                    let _error = lintJSON(jsonData: data)
                                    let json = (String(data: data, encoding: .utf8) ?? "").components(separatedBy: "\n")
                                    subView = AnyView (
                                        VStack {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("Debug:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                                                }
                                                Spacer()
                                            }.padding(.leading, 1).padding(.bottom, -3)
                                            HStack {
                                                Text(_error.0).foregroundColor(.accentColor)
                                                Spacer()
                                            }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                                            if let line = _error.1 {
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text("Debug Preview:").font(.system(size: 25, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                                                    }
                                                    Spacer()
                                                }.padding(.leading, 1).padding(.bottom, -3)
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        if json.count >= line {
                                                            Text("\(line-2) \(json[line-2])").foregroundColor(.accentColor)
                                                            Text("\(line-1) \(json[line-1])").foregroundColor(.accentColor)
                                                            Text("\(line) \(json[line])").foregroundColor(.accentColor).background(Color.accentColor.opacity(0.1))
                                                            if json.count >= line+1 {
                                                                Text("\(line+1) \(json[line+1])").foregroundColor(.accentColor)
                                                                if json.count >= line+2 {
                                                                    Text("\(line+2) \(json[line+2])").foregroundColor(.accentColor)
                                                                }
                                                            }
                                                        }
                                                    }
                                                    Spacer()
                                                }.padding().background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.accentColor.opacity(0.1)))
                                            }
                                        }
                                    )
                                case .failure(_):
                                    showPopup("Error Debugging", "Failed to get repo manifest")
                                }
                            }
                        }, button: true)
                    )
                }
                fixes.append(
                    Solution(text:"Repo appears to have an invalid manifest, please contact the repo creator", function: {}, button: false)
                )
            } else if error.contains("could not connect to the server") {
                fixes.append(
                    Solution(text:"No repo appears to exist at this url, Did you input the URL correctly?", function: {}, button: false)
                )
            } else {
                fixes.append(
                    Solution(text:"No fix was found for this repo, if this appears to be an issue with the repo, please contact the repo creator", function: {}, button: false)
                )
            }
            
        }
        return fixes
    }
    
    func lintJSON(jsonData: Data) -> (String, Int?) {
        do {
            let _ = try JSONSerialization.jsonObject(with: jsonData, options: [])
            return ("JSON appears valid", nil)
        } catch let error as NSError {
            if let debugDesc = error.userInfo[NSDebugDescriptionErrorKey] {
                let desc = "\(debugDesc)"
                do {
                    let regex = try NSRegularExpression(pattern: "line (\\d+), column (\\d+)")
                    let nsString = desc as NSString
                    let results = regex.matches(in: desc, range: NSRange(location: 0, length: nsString.length))

                    if let match = results.first {
                        let lineRange = match.range(at: 1)
                        let line = nsString.substring(with: lineRange)
                        return (desc, Int(line))
                    } else {
                        throw "line not found"
                    }
                } catch {
                    return (desc, nil)
                }
            } else {
                return ("Error parsing json: \(error.localizedDescription)", nil)
            }
        }
    }
}
