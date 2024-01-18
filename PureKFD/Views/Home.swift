//
//  Home.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import SwiftUI

extension NSLock {
    func synchronized<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
}

@available(iOS 15.0, *)
struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @Binding var showSetup: Bool
    @Binding var updated: Bool
    @State private var exploitMethod = "None"
    @State private var iosversion = DeviceInfo()
    @State private var repoSections: [String:[Repo]] = [:]
    @State private var featuredPackages: [Featured] = []
    @State private var packageList: [Package] = []
    @State private var ts = false
    @State private var exploitString = "None"
    @State private var refreshed = false
    let mainView: MainView
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if updated {
                        Button(action: {
                            updated = false
                            try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("config/setup_done"))
                            showSetup = true
                            mainView.updateRepos()
                        }) {
                            Text("Looks like you've updated! Would you like to rerun Setup?")
                                .font(.headline)
                                .padding(.horizontal)
                        }.tint(.accentColor).buttonStyle(.bordered).controlSize(.large).hideListRowSeparator()
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2).listRowBackground(appData.appColors.background)
                    }
                    
                    // Featured Packages
                    if !featuredPackages.isEmpty {
                        FeaturedPackagesView(featuredPackages: featuredPackages, homeView: true)
                            .padding(.horizontal, -16)
                            .padding(.bottom, -35)
                            .listRowSeparator(.hidden)
                            .listStyle(.plain)
                            .background(Color.clear)
                            .listRowBackground(appData.appColors.background)
                    } else {
                        PlaceholderFeaturedView()
                            .padding(.horizontal, -12)
                            .padding(.bottom, -35)
                            .listRowSeparator(.hidden)
                            .listStyle(.plain)
                            .background(Color.clear)
                            .listRowBackground(appData.appColors.background)
                    }
                    
                    Section("Need Ideas?") {
                        if !packageList.isEmpty {
                            ForEach(packageList) { package in
                                NavigationLink(destination: PackageDetailView(package: package, appData: appData)) {
                                    if #available(iOS 16, *) {
                                        PkgRow(pkgname: package.name, pkgauthor: package.author, pkgiconURL: package.icon, pkg: package, installedPackageView: true)
                                            .contextMenu(menuItems: {Button(action: {
                                                let pasteboard = UIPasteboard.general
                                                pasteboard.string = package.bundleID
                                            }) {
                                                Text("Copy Bundle ID")
                                                Image("copy_icon")
                                                    .renderingMode(.template)
                                            }}, preview: {PackagePreviewView(package: package).if(package.accent != nil) { view in
                                                view.accentColor(package.accent!.toColor())
                                            }}).background(Color.clear)
                                    } else {
                                        PkgRow(pkgname: package.name, pkgauthor: package.author, pkgiconURL: package.icon, pkg: package, installedPackageView: true).background(Color.clear)
                                    }
                                }.background(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        } else {
                            PlaceholderPackageListView()
                                .listRowSeparator(.hidden)
                                .background(Color.clear)
                        }
                    }.background(Color.clear).listRowBackground(appData.appColors.background)
                    
                    Text("PureKFD v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0") • \(exploitString)\n\(iosversion.modelIdentifier)\(iosversion.lowend ? " (LPM)":"") • \(iosversion.major == 0 ? "Unknown Version" : "iOS \(iosversion.major).\(iosversion.sub)\(iosversion.minor == 0 ? "" : ".\(iosversion.minor)")")\(iosversion.beta ? " Beta" : "")\(iosversion.build_number == "0" ? "" : " (\(iosversion.build_number))")").frame(maxWidth: .infinity, alignment: .center).opacity(0.7).font(.footnote).listRowSeparator(.hidden).multilineTextAlignment(.center).listRowBackground(appData.appColors.background)
                }.background(Color.clear)
            }
            .bgImage(appData)
            .task {
                haptic()
            }
            .navigationTitle("Home")
            .navigationBarItems(trailing: gearButton)
            .refreshable {
                repoSections = [:]
                featuredPackages = []
                packageList = []
                await fetchRepos()
            }.task() {
                if !refreshed {
                    Task {
                        let deviceinfo = getDeviceInfo(appData: appData)
                        iosversion = deviceinfo.3
                        ts = deviceinfo.2
                        switch deviceinfo.0 {
                        case 0:
                            exploitMethod = "KFD"
                            if ts {
                                exploitString = "KFD (w/ TS)"
                            }
                        case 1:
                            exploitMethod = "MDC"
                            if ts {
                                exploitString = "MDC (w/ TS)"
                            }
                        case 2:
                            exploitMethod = "Rootful"
                        default:
                            exploitMethod = "None"
                            appData.UserData.filters.jb = true
                            appData.UserData.filters.kfd = true
                            if ts {
                                exploitString = "Trollstore"
                            }
                        }
                    }
                    fetchRepos()
                    refreshed = true
                }
            }
        }.navigationViewStyle(.stack)
    }
    
    private var gearButton: some View {
        NavigationLink(destination: SettingsView()) {
            Image("tabbar_gear_icon")
                .renderingMode(.template)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .contextMenu(menuItems: {
                    Button(action: {
                        appData.RepoData = SavedRepoData(urls: [])
                        appData.save()
                    }, label: {Text("Clear Repo Data"); Image("apply_icon").renderingMode(.template)})
                    Button(action: {
                        appData.UserData = SavedUserData()
                        appData.save()
                    }, label: {Text("Clear User Data"); Image("apply_icon").renderingMode(.template)})
                    Button(action: {
                        UserDefaults.standard.set("", forKey: "accentColor")
                    }, label: {Text("Clear Accent Color"); Image("apply_icon").renderingMode(.template)})
                })
        }
    }
    
    private func fetchRepos() {
        repoSections = [:]
        
        let repos = getCachedRepos()
        
        for repo in repos {
            let repoType = repo.repotype
            if var existingRepos = repoSections[repoType] {
                if let existingRepoIndex = existingRepos.firstIndex(where: { $0.url == repo.url }) {
                    existingRepos[existingRepoIndex] = repo
                } else {
                    existingRepos.append(repo)
                }
                repoSections[repoType] = existingRepos
            } else {
                repoSections[repoType] = [repo]
            }
        }
        var temp_featuredPackages: [Featured] = []
        var temp_packageList: [Package] = []
        for (_, repoList) in repoSections {
            for repo in repoList {
                if !(repo.featured?.isEmpty ?? true) {
                    temp_featuredPackages.append(contentsOf: repo.featured!)
                }
            }
        }
        
        temp_featuredPackages = Array(temp_featuredPackages.shuffled().prefix(5)) as? [Featured] ?? []
        for (_, repoList) in repoSections {
            for repo in repoList {
                var filteredPackages: [Package] = repo.packages
                filteredPackages = filteredPackages.filter { !($0.screenshots?.isEmpty ?? true) }
                filteredPackages = filteredPackages.filter { !($0.banner == nil) }
                filteredPackages = filteredPackages.filter { !($0.icon == nil || $0.icon == URL(string: "")) }
                temp_packageList.append(contentsOf: filteredPackages)
            }
        }
        
        temp_packageList = Array(temp_packageList.shuffled().prefix(10)) as? [Package] ?? []
        packageList = temp_packageList
        featuredPackages = temp_featuredPackages
        appData.repoSections = repoSections
        appData.refreshedRepos = true
    }
}

struct PlaceholderPackageListView: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<10, id: \.self) { _ in
                HStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray)
                        .frame(width: 43, height: 43)
                    
                    VStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray)
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray)
                            .frame(height: 17)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct PlaceholderFeaturedView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 25) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray)
                        .frame(width: 260, height: 163)
                        .background(Color.clear)
                }
            }
            .padding()
        }
    }
}

@available(iOS 15.0, *)
struct nSettingsView: View {
    var body: some View {
        List {
            HStack {
                Button(action: {
                    
                }) {
                    HStack {
                        Spacer()
                        HStack {
                            Image("dev_icon").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 50)
                            Text("Exploit Setup")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                        }
                        Spacer()
                    }
                }.tint(.accentColor).buttonStyle(.bordered).controlSize(.large).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            }.listRowBackground(Color.clear).hideListRowSeparator()
            
            HStack {
                Button(action: {
                    
                }) {
                    HStack {
                        Spacer()
                        HStack {
                            Image("edit_row").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 50)
                            Text("Change Row Theming")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                        }
                        Spacer()
                    }
                }.tint(.accentColor).buttonStyle(.bordered).controlSize(.large).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            }.listRowBackground(Color.clear).hideListRowSeparator()
            
            HStack {
                Button(action: {
                    
                }) {
                    HStack {
                        Spacer()
                        HStack {
                            Image("app_icon").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 50)
                            Text("Change Icon")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                        }
                        Spacer()
                    }
                }.tint(.accentColor).buttonStyle(.bordered).controlSize(.large).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            }.listRowBackground(Color.clear).hideListRowSeparator()
            
            HStack {
                Button(action: {
                    
                }) {
                    HStack {
                        Spacer()
                        HStack {
                            Image("phone_icon").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 50)
                            Text("Background Setup")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                        }
                        Spacer()
                    }
                }.tint(.accentColor).buttonStyle(.bordered).controlSize(.large).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            }.listRowBackground(Color.clear).hideListRowSeparator()
            
            HStack {
                Button(action: {
                    
                }) {
                    HStack {
                        Spacer()
                        HStack {
                            Image("dev_icon").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 50)
                            Text("Advanced Setup")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                        }
                        Spacer()
                    }
                }.tint(.accentColor).buttonStyle(.bordered).controlSize(.large).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            }.listRowBackground(Color.clear).hideListRowSeparator()
            
            HStack {
                Button(action: {
                    
                }) {
                    HStack {
                        Spacer()
                        HStack {
                            Image("credits_icon").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 50)
                            Text("Credits")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                        }
                        Spacer()
                    }
                }.tint(.accentColor).buttonStyle(.bordered).controlSize(.large).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            }.listRowBackground(Color.clear).hideListRowSeparator()
            
            CustomNavigationLink {SettingsView()} label: {
                HStack {
                    Spacer()
                    HStack {
                        Image("gear_icon").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 50)
                        Text("v4 Settings")
                            .font(.headline)
                            .padding(.horizontal)
                        Spacer()
                        Image("arrow_icon").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 24)
                    }
                    Spacer()
                }
            }.listRowBackground(Color.clear).hideListRowSeparator()
        }.bgImage().navigationTitle("Settings").navigationBarTitleDisplayMode(.inline).listRowSpacing(-10)
    }
}

@available(iOS 15.0, *)
struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var selectedColorString: String = "#E3CCF8"
    @State private var selectedColor: Color = (Color(UIColor(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "") ?? UIColor(hex: "#E3CCF8")!) )
    @State private var detectedExploit = -1
    @State private var ts = false
    
    private var respringOptions = ["Frontboard", "Backboard"]
    private let appInstallOptions = ["Enterprise (Any Version)", "/Applications (Rootful JB)", "/var/jb/Applications (Rootless JB)"]
    
    var body: some View {
        List {
            
            ExploitPickers()
            
            Section(header: Text("Extras").foregroundColor(.accentColor)) {
                Picker("Respring Mode:", selection: $appData.UserData.respringMode) {
                    ForEach(0..<respringOptions.count, id: \.self) {
                        Text(respringOptions[$0])
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .onChange(of: appData.UserData.exploit_method) {_ in appData.save()}
                .listBG()
//                Toggle("Override Exploit Method", isOn: $appData.UserData.override_exploit_method)
//                    .tint(.accentColor)
//                    .foregroundColor(.accentColor)
//                    .onChange(of: appData.UserData.override_exploit_method) {_ in appData.save()}
//                    .listRowBackground(appData.appColors.background)
//
//                if appData.UserData.override_exploit_method {
//                    if appData.UserData.exploit_method == 1 {
//                        Text("Your device was detected as an MDC device, KFD IS NOT RECOMMENDED on these devices").listRowBackground(appData.appColors.background)
//                    }
//                    Picker("Exploit:", selection: $appData.UserData.exploit_method) {
//                        ForEach(0..<exploitOptions.count, id: \.self) {
//                            Text(exploitOptions[$0])
//                        }
//                    }
//                    .tint(.accentColor)
//                    .foregroundColor(.accentColor)
//                    .onChange(of: appData.UserData.exploit_method) {_ in appData.save()}
//                    .listRowBackground(appData.appColors.background)
//                }
                
                Picker("App Install Type:", selection: $appData.UserData.install_method) {
                    ForEach(0..<appInstallOptions.count, id: \.self) {
                        Text(appInstallOptions[$0])
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .onChange(of: appData.UserData.exploit_method) {_ in appData.save()}
                .listBG()
                
                ColorPicker("Accent Color", selection: $selectedColor)
                    .onChange(of: selectedColor) { newValue in
                        selectedColorString = newValue.toHex()
                        UserDefaults.standard.set(selectedColorString, forKey: "accentColor")
                        refreshView(appData: appData)
                    }.listBG()
                
                Toggle(isOn: $appData.UserData.allowlight, label: {
                    Text("Allow Light Mode")
                }).onChange(of: appData.UserData.allowlight) { _ in
                    appData.save()
                }.listBG()
                
                Toggle("Translate Prefs On Install", isOn: $appData.UserData.translateoninstall)
                    .onChange(of: appData.UserData.translateoninstall) { _ in
                        appData.save()
                    }.listBG()
                Toggle("Use BuiltIn File Picker", isOn: $appData.UserData.PureKFDFilePicker)
                    .onChange(of: appData.UserData.PureKFDFilePicker) { _ in
                        appData.save()
                    }.listBG()
                Toggle("Developer Mode", isOn: $appData.UserData.dev)
                    .onChange(of: appData.UserData.dev) { _ in
                        appData.save()
                    }.listBG()
                NavigationLink(destination: IconSelectorView(), label: {
                    Text("Change Icon")
                }).listBG()
            }.listRowBackground(Color.clear)
            
            Section(header: Text("App Data").foregroundColor(.accentColor)) {
                Button(action: {
                    appData.RepoData = SavedRepoData(urls: [])
                    appData.repoSections = [:]
                    appData.save()
                }, label: {Text("Clear Repo Data")}).listBG()
                Button(action: {
                    appData.UserData = SavedUserData()
                    appData.save()
                }, label: {Text("Clear User Data")}).listBG()
                Button(action: {
                    UserDefaults.standard.set("", forKey: "accentColor")
                    refreshView(appData: appData)
                }, label: {Text("Clear Accent Color")}).listBG()
                Button(action: {
                    BackupManager().exportBackup()
                }, label: {Text("Backup Data")}).listBG()
            }.listBG()
            
            CreditView()
                .listBG()
        }.navigationBarTitle("Settings", displayMode: .large).bgImage(appData).listBG().listStyle(.insetGrouped).clearBG()
    }
    init() {
        if (hasEntitlement("com.apple.private.security.no-sandbox" as CFString)) {
            self.respringOptions.append("mmaintenanced (userspace reboot)");
        }
    }
}

@available(iOS 15.0, *)
struct ExploitPickers: View {
    @EnvironmentObject var appData: AppData
    // iPhones: 2048-3584 work well, iPads: 4096 is what you want (tho i think 3072 and 3584 would prob work)
    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048, 3072, 3584, 4096]
    // 16: Works with trollstore installs on some devices; 65536: Basically disables hogging
    private let staticHeadroomOptions = [16, 128, 192, 256, 384, 512, 768, 1024, 1536, 2048, 4096, 65536]
    private let puafMethodOptions = ["physpuppet", "smith", "landa"]
    private let kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    private let kwriteMethodOptions = ["dup", "sem_open"]
    @State private var exploitOptions = ["KFD", "MDC", "Rootful (JB)"]
    @State private var exploitMethod = 0
    @State private var kfd_allowed = true
    
    var body: some View {
        Section(header: Text("Exploit Settings").foregroundColor(.accentColor)) {
            Picker("Exploit:", selection: $appData.UserData.exploit_method) {
                ForEach(0..<exploitOptions.count, id: \.self) {
                    Text(exploitOptions[$0])
                }
            }
            .tint(.accentColor)
            .foregroundColor(.accentColor)
            .onChange(of: exploitMethod) { _ in
                if kfd_allowed {
                    appData.UserData.exploit_method = exploitMethod
                } else {
                    appData.UserData.exploit_method = exploitMethod + 1
                }
                appData.save()
            }
            .listBG()
            
            if appData.UserData.exploit_method == 0 {
                Picker("puaf pages:", selection: $appData.UserData.kfd.puaf_pages_index) {
                    ForEach(0..<puafPagesOptions.count, id: \.self) {
                        Text(String(puafPagesOptions[$0]))
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .listBG()
                .onChange(of: appData.UserData.kfd.puaf_pages_index) {sel in
                    appData.UserData.kfd.puaf_pages = puafPagesOptions[sel]
                }
                
                Picker("puaf method:", selection: $appData.UserData.kfd.puaf_method) {
                    ForEach(0..<puafMethodOptions.count, id: \.self) {
                        Text(puafMethodOptions[$0])
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .listBG()
                
                Picker("kread method:", selection: $appData.UserData.kfd.kread_method) {
                    ForEach(0..<kreadMethodOptions.count, id: \.self) {
                        Text(kreadMethodOptions[$0])
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .listBG()
                
                Picker("kwrite method:", selection: $appData.UserData.kfd.kwrite_method) {
                    ForEach(0..<kwriteMethodOptions.count, id: \.self) {
                        Text(kwriteMethodOptions[$0])
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .listBG()
                
                Toggle("Use Static Headroom", isOn: $appData.UserData.kfd.use_static_headroom)
                    .tint(.accentColor)
                    .foregroundColor(.accentColor)
                    .onChange(of: appData.UserData.kfd.use_static_headroom) {_ in appData.save()}
                    .listBG()
                
                if appData.UserData.kfd.use_static_headroom {
                    Picker("static headroom:", selection: $appData.UserData.kfd.static_headroom_sel) {
                        ForEach(0..<staticHeadroomOptions.count, id: \.self) {
                            Text(String(staticHeadroomOptions[$0]))
                        }
                    }
                    .tint(.accentColor)
                    .foregroundColor(.accentColor)
                    .listBG()
                    .onChange(of: appData.UserData.kfd.static_headroom_sel) {sel in
                        appData.UserData.kfd.static_headroom = staticHeadroomOptions[sel]
                    }
                }
            }
        }
        .listRowSeparator(.hidden)
        .onChange(of: appData.UserData.kfd) {_ in appData.save()}
    }
}

@available(iOS 15.0, *)
struct CreditView: View {
    var body: some View {
        Section(header: Text("Credits").foregroundColor(.accentColor)) {
            CreditRow(name: "Lrdsnow", role: "Main Developer", link: URL(string: "https://github.com/Lrdsnow")).foregroundStyle(.purple)
            CreditRow(name: "Nick Chan", role: "Developer", link: URL(string: "https://github.com/asdfugil")).foregroundStyle(.green)
            CreditRow(name: "leminlimez", role: "Springboard Color Manager", link: URL(string: "https://github.com/leminlimez")).foregroundStyle(.yellow)
            CreditRow(name: "icons8", role: "Plumpy Icons", link: URL(string: "https://icons8.com")).foregroundStyle(.green)
            CreditRow(name: "emmikat", role: "M1/M2 Fixes", link: URL(string: "https://github.com/emmikat")).foregroundStyle(.pink)
            CreditRow(name: "dhinakg", role: "M1/M2 Fixes", link: URL(string: "https://github.com/dhinakg")).foregroundStyle(.green)
            CreditRow(name: "lilmayofuksu", role: "M1/M2 Fixes", link: URL(string: "https://github.com/lilmayofuksu")).foregroundStyle(.purple)
            CreditRow(name: "noxwell", role: "M1/M2 Fixes", link: URL(string: "https://github.com/noxwell")).foregroundStyle(.blue)
            CreditRow(name: "@dor4a", role: "Icon/Tweak Creator/Translator", link: URL(string: "https://discord.com/users/455513497288310785")).foregroundStyle("#c2f1ff".toColor()!)
            CreditRow(name: "@hackzy", role: "Icon/Tweak Creator", link: URL(string: "https://discord.com/users/424899221267939328")).foregroundStyle(.green)
            CreditRow(name: "@dreelpoop_er", role: "Icon/Tweak Creator", link: URL(string: "https://discord.com/users/669665537051197491")).foregroundStyle(.red)
            CreditRow(name: "Oliver Tzeng（曾嘉禾）", role: "Translator", link: URL(string: "https://github.com/olivertzeng")).foregroundStyle(.red)
            CreditRow(name: "@lunginspector", role: "Icon Creator", link: URL(string: "https://discord.com/users/1070904865657729035")).foregroundStyle(.red)
            CreditRow(name: "@k3wl.4id", role: "Icon Creator", link: URL(string: "https://discord.com/users/717985587235258388")).foregroundStyle(.brown)
            CreditRow(name: "@_severalpeople_", role: "Icon Creator", link: URL(string: "https://discord.com/users/995151326264705074")).foregroundStyle(.brown)
            CreditRow(name: "@mildpeppercat", role: "Icon Creator", link: URL(string: "https://discord.com/users/822833988997218314")).foregroundStyle(.red)
            CreditRow(name: "@modmenus", role: "Icon Creator", link: URL(string: "https://discord.com/users/672886506859266051")).foregroundStyle(.red)
        }
    }
}

struct CreditRow: View {
    let name: String
    let role: String
    let link: URL?
    var body: some View {
        Link(destination: link ?? URL(string: "file:///")!) {
            HStack {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                Text(name).font(.body.bold()).lineLimit(1)
                Spacer()
                Text(role).opacity(0.7).lineLimit(1)
            }
        }
    }
}

struct IconSelectorView: View {
    @State private var selectedIconName: String? = nil
    @EnvironmentObject var appData: AppData
    
    let iconSections: [String: [String]] = [
        "Grade A+": ["AppIcon0", "AppIcon12", "AppIcon23", "AppIcon1", "AppIcon11", "AppIconOG", "AppIcon24"],
        "Good!": ["AppIcon15", "AppIcon9", "AppIcon10", "AppIcon19"],
        "Decent":["AppIcon13", "AppIcon8", "AppIcon7"],
        "Others": ["AppIcon2", "AppIcon3", "AppIcon4", "AppIcon5", "AppIcon6"],
        "Winter!": ["AppIcon14", "AppIcon20", "AppIcon21", "AppIcon22"]
    ]
    
    let sectionOrder = ["Grade A+", "Good!", "Decent", "Others", "Winter!"]
    
    var body: some View {
        List {
            VStack(spacing: 0) {
                ForEach(sectionOrder, id: \.self) { section in
                    VStack(spacing: -20) {
                        HStack {
                            Text(section)
                                .font(.footnote)
                                .opacity(0.7)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(iconSections[section] ?? [], id: \.self) { iconName in
                                    Button(action: {
                                        NSLog("%@", iconName)
                                        setAppIcon(iconName)
                                    }) {
                                        Image(uiImage: UIImage(named: iconName) ?? UIImage())
                                            .renderingMode(.original)
                                            .resizable()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.accentColor, lineWidth: selectedIconName == iconName ? 2 : 0)
                                            )
                                            .padding(8)
                                    }
                                    .onAppear {
                                        if selectedIconName == nil {
                                            selectedIconName = UIApplication.shared.alternateIconName ?? "AppIconOG"
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }.listRowBackground(Color.clear)
        }.navigationTitle("Icons").bgImage(appData).listBG().listStyle(.plain).clearBG()
    }
    
    private func setAppIcon(_ iconName: String) {
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                NSLog("Error changing app icon: %@", error.localizedDescription)
            } else {
                selectedIconName = iconName
                NSLog("App icon changed successfully to: %@", iconName)
            }
        }
    }
}
