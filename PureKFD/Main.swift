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
                    case "purekfd":
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            selectedPackage = viewModel.openFile(url, appdata: appData)
                            if selectedPackage != nil {
                                isPackageDetailViewPresented = true
                            } else {
                                UIApplication.shared.alert(title: "Error", body: "Unknown error occured", withButton: true)
                            }
                        }
                    case "misaka":
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            selectedPackage = viewModel.openFile(url, appdata: appData)
                            if selectedPackage != nil {
                                isPackageDetailViewPresented = true
                            } else {
                                UIApplication.shared.alert(title: "Error", body: "Unknown error occured", withButton: true)
                            }
                        }
                    case "picasso":
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            selectedPackage = viewModel.openFile(url, appdata: appData)
                            if selectedPackage != nil {
                                isPackageDetailViewPresented = true
                            } else {
                                UIApplication.shared.alert(title: "Error", body: "Unknown error occured", withButton: true)
                            }
                        }
                    default:
                        print(url.absoluteString)
                        if url.absoluteString.contains("purekfd://") {
                            selectedPackage = findPackageViaBundleID(url.absoluteString.replacingOccurrences(of: "purekfd://", with: ""), appdata: appData)
                            if selectedPackage != nil {
                                isPackageDetailViewPresented = true
                            } else {
                                UIApplication.shared.alert(title: "Error", body: "Unknown error occured", withButton: true)
                            }
                        } else {
                            break
                        }
                    }
                }
                .sheet(isPresented: $isPackageDetailViewPresented) {
                    ZStack {
                        if colorScheme == .light {
                            Color.black.edgesIgnoringSafeArea(.all)
                        } else {
                            Color.white.edgesIgnoringSafeArea(.all)
                        }
                        PackageDetailView(package: selectedPackage ?? Package(name: "Nil", bundleID: "nil", author: "Nil", version: "Nil", desc: "Nil", longdesc: "", icon: URL(string: ""), accent: nil, screenshots: [], banner: nil, previewbg: nil, url: nil, pkgtype: "unknown", purekfd: nil, misaka: nil, picasso: nil), appData: appData).padding()
                            .listStyle(.plain)
                            .foregroundStyle(Color.accentColor)
                            .tint(Color.accentColor)
                            .background(Color.clear)
                    }
                }
                
        }
    }
    
}

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        MainView()
            .listStyle(.plain)
            .accentColor(Color(UIColor(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "") ?? UIColor.systemPurple))
            .foregroundStyle(Color.accentColor)
            .tint(Color.accentColor)
            .background(Color.clear)
            .environmentObject(appData)
            .onAppear {
                appData.load()
                // NavBar Blur
                if !appData.UserData.navbarblur {
                    UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                    UINavigationBar.appearance().shadowImage = UIImage()
                    UINavigationBar.appearance().isTranslucent = true
                    UINavigationBar.appearance().tintColor = .clear
                    UINavigationBar.appearance().backgroundColor = .clear
                }
                // Unsandbox
                if getExploitMethod(appData: appData).0 == 1 {
                    grant_full_disk_access() { error in
                        if (error != nil) {
                            UIApplication.shared.alert(title: "Access Error", body: "Error: \(String(describing: error!.localizedDescription))\nPlease close the app and retry.")
                        }
                    }
                }
            }
            .if(!appData.UserData.allowlight) { view in
                view.preferredColorScheme(.dark)
            }
    }
}

// Main View

struct MainView: View {
    @EnvironmentObject var appData: AppData
    var body: some View {
        
        TabView {
            HomeView()
                .tabItem {
                    Image("home_icon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                    Text("Home")
                }
            BrowseView()
                .tabItem {
                    Image("browse_icon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                    Text("Browse")
                }
            InstalledView()
                .tabItem {
                    Image("installed_icon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                    Text("Installed")
                }
            SearchView()
                .tabItem {
                    Image("search_icon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                    Text("Search")
                }
            if appData.UserData.dev {
                DeveloperView()
                    .tabItem {
                        Image("dev_icon")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                        Text("Developer")
                }
            }
        }
    }
}

//
