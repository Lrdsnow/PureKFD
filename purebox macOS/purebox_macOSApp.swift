//
//  purekfd_macOSApp.swift
//  purekfd macOS
//
//  Created by Lrdsnow on 9/1/24.
//

import SwiftUI

@main
struct purekfd_macOSApp: App {
    @StateObject private var appData = AppData()
    
    init() {
        UserDefaults.standard.register(defaults: ["useAvgImageColors" : true])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
                .task {
                    guard let window = NSApplication.shared.windows.first else {
                        return;
                    }
                    window.titlebarAppearsTransparent = true;
                    window.titlebarSeparatorStyle = .none;
                    window.toolbarStyle = .unified;
                }
        }
        .commands {
            CommandMenu("Repos") {
                Button("Add Repo") {
                    print("Add Repo")
                }.keyboardShortcut("+")
            }
        }
    }
}
