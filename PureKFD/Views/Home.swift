//
//  Home.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import SwiftUI

@available(iOS 15.0, *)
struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @State private var exploitMethod = "None"
    @State private var iosversion = (0, 0, 0, false, "0", "Unknown Device")
    @State private var repoSections: [String:[Repo]] = [:]
    @State private var featuredPackages: [Featured] = []
    @State private var packageList: [Package] = []
    @State private var lowend = false
    
    var body: some View {
        if true {//
            NavigationView {
                ZStack {
                    List {
                        // Featured Packages
                        if !featuredPackages.isEmpty {
                            FeaturedPackagesView(featuredPackages: featuredPackages, homeView: true)
                                .padding(.horizontal, -12)
                                .padding(.bottom, -35)
                                .listRowSeparator(.hidden)
                        }
                        
                        if !packageList.isEmpty {
                            Section("Need Ideas?") {
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
                                                }})
                                        } else {
                                            PkgRow(pkgname: package.name, pkgauthor: package.author, pkgiconURL: package.icon, pkg: package, installedPackageView: true)
                                        }
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            }
                        }
                        
                        if !packageList.isEmpty || !featuredPackages.isEmpty {
                            Text("\(iosversion.5)\(lowend ? " (LPM)":"") • \(iosversion.0 == 0 ? "Unknown Version" : "iOS \(iosversion.0).\(iosversion.1)\(iosversion.2 == 0 ? "" : ".\(iosversion.2)")")\(iosversion.3 ? " Beta" : "")\(iosversion.4 == "0" ? "" : " (\(iosversion.4))") • PureKFD v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0") • \(exploitMethod)").frame(maxWidth: .infinity, alignment: .center).opacity(0.7).font(.footnote).listRowSeparator(.hidden)
                        }
                    }
                    
                    if packageList.isEmpty && featuredPackages.isEmpty {
                        ZStack {
                            ProgressView()
                            Text("\n\nGetting Repos...")
                        }
                    }
                }
                .task {
                    haptic()
                }
                .navigationTitle("Home")
                .navigationBarItems(trailing: gearButton)
                .refreshable {
                    repoSections = [:]
                    featuredPackages = []
                    packageList = []
                }.task() {
                    Task {
                        let deviceinfo = getDeviceInfo(appData: appData)
                        iosversion = deviceinfo.2
                        lowend = deviceinfo.3
                        switch deviceinfo.0 {
                        case 0:
                            exploitMethod = "KFD"
                        case 1:
                            exploitMethod = "MDC"
                        case 2:
                            exploitMethod = "Rootful"
                        case 3:
                            exploitMethod = "Rootless"
                        default:
                            exploitMethod = "None"
                            appData.UserData.filters.jb = true
                            appData.UserData.filters.kfd = true
                        }
                    }
                    await fetchRepos()
                }
            }.navigationViewStyle(.stack)
        } else {
            if repoSections.isEmpty {
                ZStack {
                    ProgressView().task() {
                        Task {
                            let deviceinfo = getDeviceInfo(appData: appData)
                            iosversion = deviceinfo.2
                            lowend = deviceinfo.3
                            switch deviceinfo.0 {
                            case 0:
                                exploitMethod = "KFD"
                            case 1:
                                exploitMethod = "MDC"
                            case 2:
                                exploitMethod = "Rootful"
                            case 3:
                                exploitMethod = "Rootless"
                            default:
                                exploitMethod = "None"
                                appData.UserData.filters.jb = true
                                appData.UserData.filters.kfd = true
                            }
                        }
                        await fetchRepos()
                    }
                    Text("\n\nGetting Repos...")
                }
            } else {
                Text("There was an error fetching repos.\n\nDevice Info:\nModel Identifier: \(iosversion.5)\niOS Version: \(iosversion.0 == 0 ? "Unknown iOS Version" : "iOS \(iosversion.0).\(iosversion.1)\(iosversion.2 == 0 ? "" : ".\(iosversion.2)")")\(iosversion.3 ? " Beta" : "")\(iosversion.4 == "0" ? "" : " (\(iosversion.4))")\nApp Version: \(((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) != nil) ? "PureKFD v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0")" : "Unknown, Broken Bundle?")").task() {
                }.multilineTextAlignment(.center)
            }
        }
    }
    
    private var gearButton: some View {
        NavigationLink(destination: SettingsView()) {
            Image("gear_icon")
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
    
    private func fetchRepos() async {
        let temp_repoSections = Dictionary(grouping: await getAllRepos(appdata: appData), by: { $0.repotype }).mapValues { $0.sorted { $0.repotype < $1.repotype } }
        var temp_featuredPackages: [Featured] = []
        var temp_packageList: [Package] = []
        for (_, repoList) in temp_repoSections {
            for repo in repoList {
                if !(repo.featured?.isEmpty ?? true) {
                    temp_featuredPackages.append(contentsOf: repo.featured!)
                }
            }
        }
        temp_featuredPackages = Array(temp_featuredPackages.shuffled().prefix(5)) as? [Featured] ?? []
        for (_, repoList) in temp_repoSections {
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
        repoSections = temp_repoSections
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
struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var selectedColorString: String = "#FFFFFF"
    @State private var selectedColor: Color = (Color(UIColor(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "") ?? UIColor.systemPurple) )
    
    // iPhones: 2048-3584 work well, iPads: 4096 is what you want (tho i think 3072 and 3584 would prob work)
    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048, 3072, 3584, 4096]
    private let puafMethodOptions = ["physpuppet", "smith"]
    private let kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    private let kwriteMethodOptions = ["dup", "sem_open"]
    private let respringOptions = ["Frontboard", "Backboard"]
    private let exploitOptions = ["KFD", "MDC", "Rootful (JB)", "Rootless (JB)"]
    private let appInstallOptions = ["Enterprise (Any Version)", "/Applications (Rootful JB)", "/var/jb/Applications (Rootless JB)"]
    
    var body: some View {
        Form {
            Section(header: Text("Main Settings").foregroundColor(.accentColor)) {
                Picker("Respring Mode:", selection: $appData.UserData.respringMode) {
                    ForEach(0..<respringOptions.count, id: \.self) {
                        Text(respringOptions[$0])
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .onChange(of: appData.UserData.exploit_method) {_ in appData.save()}
                .listRowBackground(Color.clear)
                Toggle("Override Exploit Method", isOn: $appData.UserData.override_exploit_method)
                    .tint(.accentColor)
                    .foregroundColor(.accentColor)
                    .onChange(of: appData.UserData.override_exploit_method) {_ in appData.save()}
                    .listRowBackground(Color.clear)
                
                if appData.UserData.override_exploit_method {
                    Picker("Exploit:", selection: $appData.UserData.exploit_method) {
                        ForEach(0..<exploitOptions.count, id: \.self) {
                            Text(exploitOptions[$0])
                        }
                    }
                    .tint(.accentColor)
                    .foregroundColor(.accentColor)
                    .onChange(of: appData.UserData.exploit_method) {_ in appData.save()}
                    .listRowBackground(Color.clear)
                }
                
                Picker("App Install Type:", selection: $appData.UserData.install_method) {
                    ForEach(0..<appInstallOptions.count, id: \.self) {
                        Text(appInstallOptions[$0])
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .onChange(of: appData.UserData.exploit_method) {_ in appData.save()}
                .listRowBackground(Color.clear)
            }
            
            if appData.UserData.exploit_method == 0 && appData.UserData.override_exploit_method {
                Section(header: Text("Exploit Settings").foregroundColor(.accentColor)) {
                    Picker("puaf pages:", selection: $appData.UserData.kfd.puaf_pages_index) {
                        ForEach(0..<puafPagesOptions.count, id: \.self) {
                            Text(String(puafPagesOptions[$0]))
                        }
                    }
                    .tint(.accentColor)
                    .foregroundColor(.accentColor)
                    .listRowBackground(Color.clear)
                    
                    Picker("puaf method:", selection: $appData.UserData.kfd.puaf_method) {
                        ForEach(0..<puafMethodOptions.count, id: \.self) {
                            Text(puafMethodOptions[$0])
                        }
                    }
                    .tint(.accentColor)
                    .foregroundColor(.accentColor)
                    .listRowBackground(Color.clear)
                    
                    Picker("kread method:", selection: $appData.UserData.kfd.kread_method) {
                        ForEach(0..<kreadMethodOptions.count, id: \.self) {
                            Text(kreadMethodOptions[$0])
                        }
                    }
                    .tint(.accentColor)
                    .foregroundColor(.accentColor)
                    .listRowBackground(Color.clear)
                    
                    Picker("kwrite method:", selection: $appData.UserData.kfd.kwrite_method) {
                        ForEach(0..<kwriteMethodOptions.count, id: \.self) {
                            Text(kwriteMethodOptions[$0])
                        }
                    }
                    .tint(.accentColor)
                    .foregroundColor(.accentColor)
                    .listRowBackground(Color.clear)
                }
                .listRowSeparator(.hidden)
                .onChange(of: appData.UserData.kfd) {_ in appData.save()}
            }
            Section(header: Text("Extras").foregroundColor(.accentColor)) {
                Toggle("Translate Prefs On Install", isOn: $appData.UserData.translateoninstall)
                    .onChange(of: appData.UserData.translateoninstall) { _ in
                        appData.save()
                    }.listRowBackground(Color.clear)
                Toggle("Use BuiltIn File Picker", isOn: $appData.UserData.PureKFDFilePicker)
                    .onChange(of: appData.UserData.PureKFDFilePicker) { _ in
                        appData.save()
                    }.listRowBackground(Color.clear)
                Toggle("Developer Mode", isOn: $appData.UserData.dev)
                    .onChange(of: appData.UserData.dev) { _ in
                        appData.save()
                    }.listRowBackground(Color.clear)
                NavigationLink(destination: IconSelectorView(), label: {
                    Text("Change Icon")
                }).listRowBackground(Color.clear)
                NavigationLink(destination: ExtrasView(selectedColor: $selectedColor, selectedColorString: $selectedColorString), label: {
                    Text("Other Extras")
                }).listRowBackground(Color.clear)
            }
            .listRowBackground(Color.clear)
            CreditView()
                .listRowBackground(Color.clear)
        }.navigationBarTitle("Settings", displayMode: .large)
    }
}

@available(iOS 15.0, *)
struct CreditView: View {
    var body: some View {
        Section(header: Text("Credits").foregroundColor(.accentColor)) {
            CreditRow(name: "Lrdsnow", role: "Developer", link: URL(string: "https://github.com/Lrdsnow")).foregroundStyle(.purple)
            CreditRow(name: "leminlimez", role: "Springboard Color Manager", link: URL(string: "https://github.com/leminlimez")).foregroundStyle(.yellow)
            CreditRow(name: "icons8", role: "Plumpy Icons", link: URL(string: "https://icons8.com")).foregroundStyle(.green)
            CreditRow(name: "emmikat", role: "M1/M2 Fixes", link: URL(string: "https://github.com/emmikat")).foregroundStyle(.green)
            CreditRow(name: "dhinakg", role: "M1/M2 Fixes", link: URL(string: "https://github.com/dhinakg")).foregroundStyle(.green)
            CreditRow(name: "lilmayofuksu", role: "M1/M2 Fixes", link: URL(string: "https://github.com/lilmayofuksu")).foregroundStyle(.green)
            CreditRow(name: "noxwell", role: "M1/M2 Fixes", link: URL(string: "https://github.com/noxwell")).foregroundStyle(.green)
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

    let iconSections: [String: [String]] = [
        "Grade A+": ["AppIcon1", "AppIcon11", "AppIconOG", "AppIcon12"],
        "Good!": ["AppIcon14", "AppIcon15", "AppIcon9", "AppIcon10"],
        "Decent":["AppIcon13", "AppIcon8", "AppIcon7"],
        "Others": ["AppIcon2", "AppIcon3", "AppIcon4", "AppIcon5", "AppIcon6"],
    ]

    let sectionOrder = ["Grade A+", "Good!", "Decent", "Others"]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
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
                                        print(iconName)
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
            }
        }.navigationTitle("Icons")
    }

    private func setAppIcon(_ iconName: String) {
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            } else {
                selectedIconName = iconName
                print("App icon changed successfully to: \(iconName)")
            }
        }
    }
}

struct ExtrasView: View {
    @EnvironmentObject var appData: AppData
    @Binding var selectedColor: Color
    @Binding var selectedColorString: String
    var body: some View {
        Form {
            Section(header: Text("Design").foregroundColor(.accentColor)) {
                Toggle(isOn: $appData.UserData.allowlight, label: {
                    Text("Allow Light Mode")
                }).onChange(of: appData.UserData.allowlight) { _ in
                    appData.save()
                }
                ColorPicker("Accent Color", selection: $selectedColor)
                    .onChange(of: selectedColor) { newValue in
                        selectedColorString = newValue.toHex()
                        UserDefaults.standard.set(selectedColorString, forKey: "accentColor")
                        refreshView(appData: appData)
                    }
            }
            .listRowBackground(Color.clear)
            Section(header: Text("App Data").foregroundColor(.accentColor)) {
                Button(action: {
                    appData.RepoData = SavedRepoData(urls: [])
                    appData.repoSections = [:]
                    appData.save()
                }, label: {Text("Clear Repo Data")}).listRowBackground(Color.clear)
                Button(action: {
                    appData.UserData = SavedUserData()
                    appData.save()
                }, label: {Text("Clear User Data")}).listRowBackground(Color.clear)
                Button(action: {
                    UserDefaults.standard.set("", forKey: "accentColor")
                    refreshView(appData: appData)
                }, label: {Text("Clear Accent Color")}).listRowBackground(Color.clear)
                Spacer()
                Button(action: {
                    BackupManager().exportBackup()
                }, label: {Text("Backup Data")}).listRowBackground(Color.clear)
                Spacer()
                
            }.listRowBackground(Color.clear)
        }.navigationBarTitle("Extras", displayMode: .large)
    }
}
