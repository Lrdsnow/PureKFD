//
//  Main.swift
//  purekfd
//
//  Created by Lrdsnow on 6/26/24.
//

// PureKFD is NOT yet ready for use

import UIKit
import SwiftUI

@main
struct purekfdApp: App {
    @StateObject private var appData = AppData()
    @StateObject private var repoHandler = RepoHandler()
    
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
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var repoHandler: RepoHandler
    @State private var installing = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FeaturedView()
                    .tabItem({Label("Featured", systemImage: "star.fill")})
                    .tag(0)
                BrowseView()
                    .tabItem({Label("Browse", systemImage: "square.grid.2x2")})
                    .tag(1)
                InstalledView(installing: $installing)
                    .tabItem({Label("Installed", systemImage: "square.and.arrow.down")})
                    .tag(2)
            }
        }.onChange(of: selectedTab) { newValue in
            if installing {
                selectedTab = 2
            }
        }.onAppear() {
            log("Running on an \(DeviceInfo.modelName) (\(DeviceInfo.cpu)) running \(DeviceInfo.osString) \(DeviceInfo.version) (\(DeviceInfo.build))")
        }
    }
}

