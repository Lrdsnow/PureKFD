//
//  Main.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import UIKit
import SwiftUI
import Darwin

// Setup
@main
struct PureKFDBinary {
    static func main() {
        if (getuid() != 0) {
            PureKFDApp.main();
        } else {
             exit(RootHelperMain());
        }
        
    }
}

struct PureKFDApp: App {
    @StateObject private var appData = AppData()
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = ViewModel()
    @StateObject private var backupManager = BackupManager()
    @State private var isPackageDetailViewPresented = false
    @State private var selectedPackage: Package?
    
    init() {
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.accentColor.opacity(0.4))
        UITabBar.appearance().tintColor = UIColor(Color.accentColor)
        UITableViewCell.appearance().backgroundColor = .clear
        UITableView.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
                .onOpenURL { url in
                    if url.scheme == "purekfd" && url.host == "github-oauth-callback" {
                    } else {
                        switch url.pathExtension {
                        case "purekfdbackup":
                            if url.startAccessingSecurityScopedResource() {
                                defer { url.stopAccessingSecurityScopedResource() }
                                do {
                                    try backupManager.importBackup(url, appdata: appData)
                                    UIApplication.shared.alert(title: "Success", body: "Successfully restored backup", animated: false, withButton: true)
                                } catch {
                                    UIApplication.shared.alert(title: "Error", body: error.localizedDescription, animated: false, withButton: true)
                                }
                            }
                        case "purekfd", "picasso":
                            if url.startAccessingSecurityScopedResource() {
                                defer { url.stopAccessingSecurityScopedResource() }
                                selectedPackage = viewModel.openFile(url, appdata: appData)
                                if selectedPackage != nil {
                                    isPackageDetailViewPresented = true
                                } else {
                                    UIApplication.shared.alert(title: "Error", body: "Unknown error occurred", withButton: true)
                                }
                            }
                        default:
                            if url.absoluteString.contains("purekfd://") {
                                selectedPackage = findPackageViaBundleID(url.absoluteString.replacingOccurrences(of: "purekfd://", with: ""), appdata: appData)
                                if selectedPackage != nil {
                                    isPackageDetailViewPresented = true
                                } else {
                                    UIApplication.shared.alert(title: "Error", body: "Unknown error occurred", withButton: true)
                                }
                            } else {
                                NSLog("%@", url.absoluteString)
                            }
                        }
                    }
                }.sheet(isPresented: $isPackageDetailViewPresented) {
                    ZStack {
                        if colorScheme == .light {
                            Color.black.edgesIgnoringSafeArea(.all)
                        } else {
                            Color.white.edgesIgnoringSafeArea(.all)
                        }
                        PackageDetailView(package: selectedPackage ?? Package(name: "Nil", bundleID: "nil", author: "Nil", version: "Nil", desc: "Nil", longdesc: "", icon: URL(string: ""), accent: nil, screenshots: [], banner: nil, previewbg: nil, category: "Misc", install_actions: [], uninstall_actions: [], url: nil, pkgtype: "unknown"), appData: appData)
                            .padding()
                            .plainList()
                            .mainViewTweaks()
                            .clearBackground()
                    }
                }
        }
    }
    
}

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        MainView()
            .mainViewTweaks()
            .plainList()
            .accentColor(Color(UIColor(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "") ?? UIColor(hex: "#E3CCF8")!))
            .clearBackground()
            .environmentObject(appData)
            .onAppear {
                let controller = UIHostingController(rootView: self)
                let subview = controller.view!
                subview.isOpaque = false
                subview.backgroundColor = .clear
                
                appData.load()
                if let accent_row_uicolor = UIColor(hex: appData.UserData.savedAppColors.accent) {
                    appData.appColors.accent = Color(accent_row_uicolor)
                }
                if let author_row_uicolor = UIColor(hex: appData.UserData.savedAppColors.author) {
                    appData.appColors.author = Color(author_row_uicolor)
                }
                if let background_row_uicolor = UIColor(hex: appData.UserData.savedAppColors.background) {
                    appData.appColors.background = Color(background_row_uicolor)
                }
                if let description_row_uicolor = UIColor(hex: appData.UserData.savedAppColors.description) {
                    appData.appColors.description = Color(description_row_uicolor)
                }
                if let name_row_uicolor = UIColor(hex: appData.UserData.savedAppColors.name) {
                    appData.appColors.name = Color(name_row_uicolor)
                }
                // Unsandbox
                #if targetEnvironment(simulator)
                #else
                if getDeviceInfo(appData: appData, true).0 == 1 && ((try? (FileManager.default.contentsOfDirectory(atPath: "/var"))) == nil) {
                    grant_full_disk_access() { error in
                        if (error != nil) {
                            UIApplication.shared.alert(title: "Access Error", body: "Error: \(String(describing: error!.localizedDescription))\nPlease close the app and retry.")
                        }
                    }
                }

                // Sorry Nick Chan i'll add this back in later
//                if (!hasEntitlement("com.apple.developer.kernel.increased-memory-limit" as CFString)
//                    && appData.UserData.hideMissingEntitlementWarning != true) {
//                    let OKAction = UIAlertAction(title: "OK",
//                                         style: .default) { (action) in
//                     // Do nothing
//                    }
//                    let DontShowMeAgainAction = UIAlertAction(title: "Don't show me again",
//                                                              style: .default) { (action) in
//                        appData.UserData.hideMissingEntitlementWarning = true;
//                        appData.save();
//                    }
//                    let alert = UIAlertController(title: "Missing entitlement",
//                             message: "Your sideloading tool is incorrectly removing the increased memory limit entitlement. KFD reliability might suffer.",
//                             preferredStyle: .alert)
//                    alert.addAction(OKAction);
//                    alert.addAction(DontShowMeAgainAction);
//                    UIApplication.shared.present(alert: alert);
//                }
                #endif
                try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("temp")) // clear temp
            }
            .if(!appData.UserData.allowlight) { view in
                view.preferredColorScheme(.dark)
            }
    }
}

// Main View

struct MainView: View {
    @EnvironmentObject var appData: AppData
    @State private var showSetup = false
    @State private var showSetup_Design = false
    @State private var showSetup_Exploit = false
    @State private var showSetup_Finalize = false
    @State private var selectedTab: Int = 0
    // Setup
    @State private var downloadingRepos = false
    @State private var downloadingRepos_Status = (0, 0)
    // Updated Check
    @State private var updated = false
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            if #available(iOS 15.0, *) {
                HomeView(showSetup: $showSetup, updated: $updated, mainView: self)
                    .tabItem {
                        Image("home_icon")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {haptic()}
                        Text("Home")
                    }.tag(0)
            }
            BrowseView()
                .tabItem {
                    Image("browse_icon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .onTapGesture {haptic()}
                    Text("Browse")
                }.tag(1)
            InstalledView()
                .tabItem {
                    Image("installed_icon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .onTapGesture {haptic()}
                    Text("Installed")
                }.tag(2)
            if #available(iOS 15.0, *) {
                SearchView()
                    .tabItem {
                        Image("search_icon")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {haptic()}
                        Text("Search")
                    }.tag(3)
                if appData.UserData.dev {
                    DeveloperView()
                        .tabItem {
                            Image("tabbar_dev_icon")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                            Text("Developer")
                        }.tag(4)
                }
            }
        }.onAppear() {
            if appData.reloading_browse {
                selectedTab = 1
            }
            if !FileManager.default.fileExists(atPath: URL.documents.appendingPathComponent("config/setup_done").path) {
                showSetup = true
                updateRepos()
            }
            updated = pkfdUpdated()
        }.sheet(isPresented: $showSetup) {
            NavigationView {
                SetupView(showSetup: $showSetup, showSetup_Design: $showSetup_Design, downloadingRepos: $downloadingRepos, downloadingRepos_Status: $downloadingRepos_Status).blurredBG()
            }.interactiveDismissDisabled().blurredBG()
        }.sheet(isPresented: $showSetup_Design) {
            NavigationView {
                SetupView_Design(showSetup_Design: $showSetup_Design, showSetup_Exploit: $showSetup_Exploit, downloadingRepos: $downloadingRepos, downloadingRepos_Status: $downloadingRepos_Status, showDownloadingRepos: .constant(true), appColors: $appData.appColors).blurredBG()
            }.interactiveDismissDisabled().blurredBG()
        }.sheet(isPresented: $showSetup_Exploit) {
            NavigationView {
                SetupView_Exploit(showSetup_Exploit: $showSetup_Exploit, showSetup_Finalize: $showSetup_Finalize, downloadingRepos: $downloadingRepos, downloadingRepos_Status: $downloadingRepos_Status, showDownloadingRepos: .constant(true), settings: false, appData: _appData).blurredBG()
            }.interactiveDismissDisabled().blurredBG()
        }.sheet(isPresented: $showSetup_Finalize) {
            NavigationView {
                SetupView_Finalize(showSetup_Finalize: $showSetup_Finalize, downloadingRepos: $downloadingRepos, downloadingRepos_Status: $downloadingRepos_Status, appColors: $appData.appColors, mainView: self, appData: _appData).blurredBG()
            }.interactiveDismissDisabled().blurredBG()
        }
    }
    
    func updateRepos() {
        Task {
            downloadingRepos = true
            var repourls = SavedRepoData()
            repourls.urls += appData.RepoData.urls
            let repoCount = repourls.urls.count
            downloadingRepos_Status = (0, repoCount)
            let repoCacheDir = URL.documents.appendingPathComponent("config/repoCache")
            if FileManager.default.fileExists(atPath: repoCacheDir.path) {
                try? FileManager.default.removeItem(at: repoCacheDir)
            }
            try? FileManager.default.createDirectory(at: repoCacheDir, withIntermediateDirectories: true)
            await getRepos(appdata: appData, completion: { repo in
                if repo.name != "Unkown" {
                    downloadingRepos_Status.0 += 1
                    let jsonEncoder = JSONEncoder()
                    do {
                        let jsonData = try jsonEncoder.encode(repo)
                        do {
                            try jsonData.write(to: repoCacheDir.appendingPathComponent("\(repo.name).json"))
                        } catch {
                            log("Error saving repo data: \(error)")
                        }
                    } catch {
                        log("Error encoding repo: \(error)")
                    }
                } else {
                    log("\(repo.desc)")
                }
            })
            downloadingRepos = false
        }
    }
}

//
