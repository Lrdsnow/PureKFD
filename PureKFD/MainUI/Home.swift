//
//  Home.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/1/23.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @StateObject private var userSettings = UserSettings()
    @State private var isFileBrowserAlertPresented = false
    @State private var showFileBrowser = false
    @State private var inFileBrowser = false
    
    // KFD:
    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 197/255, green: 89/255, blue: 239/255, alpha: 1.0)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(red: 197/255, green: 89/255, blue: 239/255, alpha: 1.0)
        ]
    }
    
    func openFileBrowser() {
        if !userSettings.enforce_exploit_method {
            if checkiOSVersionRange() == .mdc {
                userSettings.exploit_method = 1
            } else if checkiOSVersionRange() == .kfd {
                userSettings.exploit_method = 0
            } else {
                userSettings.exploit_method = 2
            }
        }
        if userSettings.exploit_method == 0 {
            exploit(puaf_pages: UInt64(puafPagesOptions[userSettings.puafPagesIndex]), puaf_method: UInt64(userSettings.puafMethod), kread_method: UInt64(userSettings.kreadMethod), kwrite_method: UInt64(userSettings.kwriteMethod)) //kopen
            fix_exploit()
        }
        inFileBrowser = true
        showFileBrowser = true
    }
    
    var body: some View {
            Form {
//                Section(header: Text("General Options")) {
//                    ToggleSettingView(title: "Respring on Apply", isOn: $userSettings.autoRespring)
//                    ToggleSettingView(title: "Developer Mode", isOn: $userSettings.dev)
//                }
                
                Section(header: Text("Actions").foregroundColor(Color.purple)) {
                    Button(action: {
                        UIApplication.shared.alert(title: "Applying...", body: "Please wait", animated: false, withButton: false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            Task {
                                if !userSettings.enforce_exploit_method {
                                    if checkiOSVersionRange() == .mdc {
                                        userSettings.exploit_method = 1
                                    } else if checkiOSVersionRange() == .kfd {
                                        userSettings.exploit_method = 0
                                    } else {
                                        userSettings.exploit_method = 2
                                    }
                                }
                                
                                if !(userSettings.exploit_method == -1) {
                                    if userSettings.exploit_method == 0 {
                                        exploit(puaf_pages: UInt64(puafPagesOptions[userSettings.puafPagesIndex]), puaf_method: UInt64(userSettings.puafMethod), kread_method: UInt64(userSettings.kreadMethod), kwrite_method: UInt64(userSettings.kwriteMethod)) //kopen
                                        fix_exploit()
                                    }
                                    
                                    applyAllTweaks(exploit_method: userSettings.exploit_method)
                                    
                                    
                                    if userSettings.exploit_method == 0 {
                                        close_exploit() //kclose
                                    }
                                    
                                    UIApplication.shared.dismissAlert(animated: false)
                                    
//                                    if userSettings.autoRespring {
//                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                                            if RespringMode == 0 {
//                                                backboard_respring()
//                                            } else if RespringMode == 1 {
//                                                respring()
//                                            }
//                                        }
//                                    }
                                }
                            }
                        }
                    }) {
                        if userSettings.autoRespring {
                            Text("Apply")
                                .settingButtonStyle()
                        } else {
                            Text("Apply")
                                .settingButtonStyle()
                        }
                    }
                    
                    Button(action: {
                        respring()
                    }) {
                        Text("Respring")
                            .settingButtonStyle()
                    }
                    
                    Button(action: {
                        backboard_respring()
                    }) {
                        Text("Backboard Respring")
                            .settingButtonStyle()
                    }
                    
                    Button(action: {
                        full_respring()
                    }) {
                        Text("Combined Respring")
                            .settingButtonStyle()
                    }
                }.listRowBackground(Color.clear)
                Section(header:
                                Text("Notice")
                                    .foregroundColor(Color.purple)
                            ) {
                                Text("Version: 3.5\n\nNotes: Misaka package support is in its early stages\n\nUsage: Install a package, Hit apply & then hit respring")
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.purple, lineWidth: 2)
                                    )
                                    .foregroundColor(Color.purple)
                                    .listRowBackground(Color.clear)
                            }
                Section(header:
                                Text("Debug Info")
                                    .foregroundColor(Color.purple)
                            ) {
                                Text("Exploit Method: \(userSettings.exploit_method)")
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.purple, lineWidth: 2)
                                    )
                                    .foregroundColor(Color.purple)
                                    .listRowBackground(Color.clear)
                            }
            }
            .onAppear {
                if inFileBrowser {
                    if userSettings.exploit_method == 0 {
                        do_kclose()
                    }
                    inFileBrowser = false
                }
            }
            .alert(isPresented: $isFileBrowserAlertPresented) {
                        Alert(
                            title: Text("Warning"),
                            message: Text("This action may trigger an exploit!"),
                            primaryButton: .default(Text("Continue")) {
                                openFileBrowser()
                            },
                            secondaryButton: .cancel()
                        )
            }
            .navigationBarItems(
                trailing: HStack {
                    NavigationLink(destination: FileBrowser(exploit_method: $userSettings.exploit_method).navigationBarTitle("PureKFD - File Browser", displayMode: .large), isActive: $showFileBrowser) {
                        EmptyView()
                    }
                    Button(action: {isFileBrowserAlertPresented=true}) {
                        Image(systemName: "folder")
                            .font(.system(size: 20))
                            .tint(.purple)
                    }
                    NavigationLink(destination: LogView().navigationBarTitle("PureKFD - Logs", displayMode: .large)) {
                        Image(systemName: "terminal")
                            .font(.system(size: 20))
                            .tint(.purple)
                    }
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .tint(.purple)
                    }
                }
            )
    }
}

struct ToggleSettingView: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 20) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.purple)
                    .imageScale(.large)
                    .tint(.purple)
                Text(title).font(.headline).foregroundColor(.purple)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .foregroundColor(.purple)
        .tint(.purple)
    }
}

enum iOSVersionRange {
    case mdc
    case kfd
    case other
}

func checkiOSVersionRange() -> iOSVersionRange {
    let systemVersion = UIDevice.current.systemVersion
    let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }

    if versionComponents.count >= 2 {
        let major = versionComponents[0]
        let minor = versionComponents[1]

        if (major == 14 && minor >= 0 && minor <= 7) ||
           (major == 15 && minor >= 0 && minor <= 7) ||
           (major == 16 && minor >= 0 && minor <= 1) {
            return .mdc
        } else if (major == 16 && minor >= 2 && minor <= 5) ||
                  (major == 16 && minor == 6) {
            return .kfd
        }
    }

    return .other
}
