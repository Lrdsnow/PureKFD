//
//  Main.swift
//  purekfd
//
//  Created by Lrdsnow on 6/26/24.
//

import UIKit
import SwiftUI
import CoreGraphics

@main
struct purekfdApp: App {
    @StateObject private var appData = AppData()
    @StateObject private var repoHandler = RepoHandler()
    @StateObject private var saveEnv = SaveEnv()
    @State private var font: Font? = nil
    @AppStorage("accentColor") private var accentColor: Color = Color(hex: "#D4A7FC")!
    
    init() {
        setenv("USBMUXD_SOCKET_ADDRESS", "127.0.0.1:60215", 1)
        UserDefaults.standard.register(defaults: ["useAvgImageColors" : true])
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().separatorColor = .clear
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
                .environmentObject(repoHandler)
                .accentColor(accentColor)
                .preferredColorScheme(.dark)
                .onAppear() {
                    ExploitHandler.unsandbox(appData.selectedExploit)
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var repoHandler: RepoHandler
    @State private var installing = false
    @State private var selectedTab = 0
    @AppStorage("accentColor") private var accentColor: Color = Color(hex: "#D4A7FC")!
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FeaturedView(selectedTab: $selectedTab)
                    .tabItem({Label("Featured", systemImage: "star.fill")})
                    .tag(0)
                    .accentColor(accentColor)
                BrowseView()
                    .tabItem({Label("Browse", systemImage: "square.grid.2x2")})
                    .tag(1)
                    .accentColor(accentColor)
                InstalledView(installing: $installing)
                    .tabItem({Label("Installed", systemImage: "square.and.arrow.down")})
                    .tag(2)
                    .accentColor(accentColor)
            }.environment(\.horizontalSizeClass, .compact)
        }.onChange(of: selectedTab) { newValue in
            if installing {
                selectedTab = 2
            }
        }.onAppear() {
            log("[i] \(DeviceInfo.modelName) (\(DeviceInfo.cpu)) on \(DeviceInfo.osString) \(DeviceInfo.version) (\(DeviceInfo.build))")
            if !appData.hasSetExploit {
                appData.selectedExploit = ExploitHandler.getBestExploitForDevice() ?? 0
                appData.hasSetExploit = true
            }
            updateInstalledTweaks(appData)
            repoHandler.updateRepos(appData)
        }.onOpenURL(perform: { url in
            if url.pathExtension == "mobiledevicepairing" {
                let loading = showLoadingPopup()
                url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                let fm = FileManager.default
                let importedURL = URL.documents.appendingPathComponent("imported")
                let pairingFileURL = importedURL.appendingPathComponent("PairingFile")
                try? fm.createDirectory(at: importedURL, withIntermediateDirectories: true)
                try? fm.removeItem(at: pairingFileURL)
                try? fm.copyItem(at: url, to: pairingFileURL)
                DispatchQueue.main.async {
                    loading.dismiss(animated: true) {
                        showPopup("Success", "Imported Pairing File Successfully")
                    }
                }
            }
        })
    }
}
