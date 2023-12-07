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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
                .onOpenURL { url in
                    switch url.pathExtension {
                    case "PureKFDbackup":
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            do {
                                try backupManager.importBackup(url, appdata: appData)
                                UIApplication.shared.alert(title: "Success", body: "Successfully restored backup", animated: false, withButton: true)
                            } catch {
                                UIApplication.shared.alert(title: "Error", body: error.localizedDescription, animated: false, withButton: true)
                            }
                        }
                    case "purekfd", "misaka", "picasso":
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
                            print(url.absoluteString)
                        }
                    }
                }.sheet(isPresented: $isPackageDetailViewPresented) {
                    ZStack {
                        if colorScheme == .light {
                            Color.black.edgesIgnoringSafeArea(.all)
                        } else {
                            Color.white.edgesIgnoringSafeArea(.all)
                        }
                        PackageDetailView(package: selectedPackage ?? Package(name: "Nil", bundleID: "nil", author: "Nil", version: "Nil", desc: "Nil", longdesc: "", icon: URL(string: ""), accent: nil, screenshots: [], banner: nil, previewbg: nil, install_actions: [], uninstall_actions: [], url: nil, pkgtype: "unknown"), appData: appData)
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
            .accentColor(Color(UIColor(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "") ?? UIColor.systemPurple))
            .clearBackground()
            .environmentObject(appData)
            .onAppear {
                let controller = UIHostingController(rootView: self)
                let subview = controller.view!
                subview.isOpaque = false
                subview.backgroundColor = .clear
                
                appData.load()
                // Unsandbox
                #if targetEnvironment(simulator)
                #else
                if getDeviceInfo(appData: appData).0 == 1 {
//                    grant_wallpaper_access() { error in
//                        if (error != nil) {
//                            UIApplication.shared.alert(title: "Access Error", body: "Error: \(String(describing: error!.localizedDescription))\nPlease close the app and retry.")
//                        }
//                    }
                    grant_full_disk_access() { error in
                        if (error != nil) {
                            UIApplication.shared.alert(title: "Access Error", body: "Error: \(String(describing: error!.localizedDescription))\nPlease close the app and retry.")
                        }
                    }
                }
                #endif
            }
            .if(!appData.UserData.allowlight) { view in
                view.preferredColorScheme(.dark)
            }
    }
}

// Main View

struct MainView: View {
    @EnvironmentObject var appData: AppData
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            if #available(iOS 15.0, *) {
                HomeView()
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
                            Image("dev_icon")
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
        }
    }
}

//
