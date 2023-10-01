//
//  Home.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var featuredPackages: [Featured] = []
    @Published var packageList: [Package] = []

    func shufflePackages(appData: AppData) {
        featuredPackages = Array(getFeaturedPackageList(appdata: appData).shuffled().prefix(5))
        packageList = Array(getPackageList(appdata: appData, filters: [.hasIcon, .hasScreenshots, .hasBanner]).shuffled().prefix(10))
    }
}

struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @StateObject var viewModel = HomeViewModel()
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            List {
                // Featured Packages
                if !viewModel.featuredPackages.isEmpty {
                    FeaturedPackagesView(featuredPackages: viewModel.featuredPackages, homeView: true)
                        .padding(.horizontal, -12)
                        .padding(.bottom, -35)
                        .listRowSeparator(.hidden)
                } else {
                    PlaceholderFeaturedView()
                        .padding(.horizontal, -12)
                        .padding(.bottom, -35)
                        .listRowSeparator(.hidden)
                }
                
                Section("Need Ideas?") {
                    if !viewModel.packageList.isEmpty {
                        ForEach(viewModel.packageList) { package in
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
                    } else {
                        PlaceholderPackageListView()
                            .listRowSeparator(.hidden)
                    }
                }
                
                Text("PureKFD v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0")").frame(maxWidth: .infinity, alignment: .center).opacity(0.7).font(.footnote).listRowSeparator(.hidden)
            }
            .navigationTitle("Home")
            .navigationBarItems(trailing: gearButton)
            .refreshable {
                isLoading = true
                refreshView(appData: appData)
                Task {
                    await fetchRepos()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        appData.refreshedRepos = true
                        viewModel.shufflePackages(appData: appData)
                        isLoading = false
                    }
                }
            }
            .task() {
                refreshView(appData: appData)
                if !appData.refreshedRepos {
                    await fetchRepos()
                    Task {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            appData.refreshedRepos = true
                            viewModel.shufflePackages(appData: appData)
                            isLoading = false
                        }
                    }
                }
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationViewStyle(.stack)
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
        appData.repoSections = [:]
        await getRepos(appdata: appData) { repo in
            DispatchQueue.main.async {
                let repoType = repo.repotype
                if var existingRepos = appData.repoSections[repoType] {
                    if let existingRepoIndex = existingRepos.firstIndex(where: { $0.url == repo.url }) {
                        existingRepos[existingRepoIndex] = repo
                    } else {
                        existingRepos.append(repo)
                    }
                    appData.repoSections[repoType] = existingRepos
                } else {
                    appData.repoSections[repoType] = [repo]
                }
            }
        }
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

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var selectedColorString: String = "#FFFFFF"
    @State private var selectedColor: Color = (Color(UIColor(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "") ?? UIColor.systemPurple) )
    
    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    private let puafMethodOptions = ["physpuppet", "smith"]
    private let kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    private let kwriteMethodOptions = ["dup", "sem_open"]
    private let respringOptions = ["Frontboard", "Backboard"]
    private let exploitOptions = ["KFD", "MDC", "Rootful (JB)", "Rootless (JB)"]
    
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
                Toggle("Use BuiltIn File Picker", isOn: $appData.UserData.purekfdFilePicker)
                    .onChange(of: appData.UserData.purekfdFilePicker) { _ in
                        appData.save()
                    }.listRowBackground(Color.clear)
                Toggle("Developer Mode", isOn: $appData.UserData.dev)
                    .onChange(of: appData.UserData.dev) { _ in
                        appData.save()
                    }.listRowBackground(Color.clear)
                if appData.UserData.dev {
                    Toggle(isOn: $appData.UserData.allowroot, label: {
                        Text("\"Unsandbox\"")
                    }).onChange(of: appData.UserData.allowroot) { _ in
                        appData.save()
                    }.listRowBackground(Color.clear)
                }
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

struct CreditView: View {
    var body: some View {
        Section(header: Text("Credits").foregroundColor(.accentColor)) {
            CreditRow(name: "Lrdsnow", role: "Developer", link: URL(string: "https://github.com/Lrdsnow")).foregroundStyle(.purple)
            CreditRow(name: "leminlimez", role: "Springboard Color Manager", link: URL(string: "https://github.com/leminlimez")).foregroundStyle(.yellow)
            CreditRow(name: "icons8", role: "Plumpy Icons", link: URL(string: "https://icons8.com")).foregroundStyle(.green)
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
                Toggle(isOn: $appData.UserData.navbarblur, label: {
                    Text("Navigation Bar Blur")
                }).onChange(of: appData.UserData.navbarblur) { _ in
                    appData.save()
                    if !appData.UserData.navbarblur {
                        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                        UINavigationBar.appearance().shadowImage = UIImage()
                        UINavigationBar.appearance().isTranslucent = true
                        UINavigationBar.appearance().tintColor = .clear
                        UINavigationBar.appearance().backgroundColor = .clear
                    }
                    refreshView(appData: appData)
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
