//
//  Settings.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/1/23.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings
    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    private let puafMethodOptions = ["physpuppet", "smith"]
    private let kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    private let kwriteMethodOptions = ["dup", "sem_open"]
    private let RespringOptions = ["Backboard Respring", "Frontboard Respring"]
    private let ExploitOptions = ["KFD", "MDC", "TrollStore"]
    var body: some View {
        Form {
            Section(header: Text("Main Settings").foregroundColor(.purple)) {
                Toggle(isOn: $userSettings.enforce_exploit_method) {
                    Text("Override Exploit Method").font(.headline).foregroundColor(.purple)
                }.tint(.purple).foregroundColor(.purple)
                if userSettings.enforce_exploit_method {
                    Picker("Exploit:", selection: $userSettings.exploit_method) {
                        ForEach(0 ..< ExploitOptions.count, id: \.self) {
                            Text(String(self.ExploitOptions[$0]))
                        }
                    }.tint(.purple).foregroundColor(.purple)
                }
            }.listRowBackground(Color.clear)
            if userSettings.exploit_method == 0 && userSettings.enforce_exploit_method {
                Section(header: Text("Exploit Settings").foregroundColor(.purple)) {
                    Picker("puaf pages:", selection: $userSettings.puafPagesIndex) {
                        ForEach(0 ..< puafPagesOptions.count, id: \.self) {
                            Text(String(self.puafPagesOptions[$0]))
                        }
                    }.tint(.purple).foregroundColor(.purple)
                    
                    Picker("puaf method:", selection: $userSettings.puafMethod) {
                        ForEach(0 ..< puafMethodOptions.count, id: \.self) {
                            Text(self.puafMethodOptions[$0])
                        }
                    }.tint(.purple).foregroundColor(.purple)
                    
                    Picker("kread method:", selection: $userSettings.kreadMethod) {
                        ForEach(0 ..< kreadMethodOptions.count, id: \.self) {
                            Text(self.kreadMethodOptions[$0])
                        }
                    }.tint(.purple).foregroundColor(.purple)
                    
                    Picker("kwrite method:", selection: $userSettings.kwriteMethod) {
                        ForEach(0 ..< kwriteMethodOptions.count, id: \.self) {
                            Text(self.kwriteMethodOptions[$0])
                        }
                    }.tint(.purple).foregroundColor(.purple)
                }.listRowBackground(Color.clear)
            }
            if userSettings.exploit_method == 1 && userSettings.enforce_exploit_method {
                Section(header: Text("Exploit Settings").foregroundColor(.purple)) {
                    Toggle(isOn: $userSettings.mdc_unsandbox) {
                        Text("Unsandbox").font(.headline).foregroundColor(.purple)
                    }.tint(.purple).foregroundColor(.purple)
                }.listRowBackground(Color.clear)
            }
            Section(header: Text("Change Icon").foregroundColor(.purple)) {
                IconSelectorView()
            }.listRowBackground(Color.clear)
        }.navigationBarTitle("Settings", displayMode: .inline)
    }
}

struct IconSelectorView: View {
    @State private var selectedIconName: String? = nil

    let iconNames = ["AppIconOG", "AppIcon1", "AppIcon2"]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(iconNames, id: \.self) { iconName in
                    Button(action: {
                        setAppIcon(iconName)
                    }) {
                        Image(uiImage: UIImage(named: iconName) ?? UIImage())
                            .renderingMode(.original)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue, lineWidth: selectedIconName == iconName ? 2 : 0)
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

class UserSettings: ObservableObject {
    @Published var autoRespring: Bool {
        didSet {
            UserDefaults.standard.set(autoRespring, forKey: "autoRespring")
        }
    }
    @Published var dev: Bool {
        didSet {
            UserDefaults.standard.set(dev, forKey: "dev")
        }
    }
    @Published var exploit_method: Int {
        didSet {
            UserDefaults.standard.set(exploit_method, forKey: "exploit_method")
        }
    }
    @Published var enforce_exploit_method: Bool {
        didSet {
            UserDefaults.standard.set(enforce_exploit_method, forKey: "enforce_exploit_method")
        }
    }
    @Published var mdc_unsandbox: Bool {
        didSet {
            UserDefaults.standard.set(enforce_exploit_method, forKey: "enforce_exploit_method")
        }
    }
    @Published var puafPagesIndex: Int {
        didSet {
            UserDefaults.standard.set(puafPagesIndex, forKey: "puafPagesIndex")
        }
    }
    @Published var puafMethod: Int {
        didSet {
            UserDefaults.standard.set(puafMethod, forKey: "puafMethod")
        }
    }
    @Published var kreadMethod: Int {
        didSet {
            UserDefaults.standard.set(kreadMethod, forKey: "kreadMethod")
        }
    }
    @Published var kwriteMethod: Int {
        didSet {
            UserDefaults.standard.set(kwriteMethod, forKey: "kwriteMethod")
        }
    }
    @Published var puafPages: Int {
        didSet {
            UserDefaults.standard.set(puafPages, forKey: "puafPages")
        }
    }
    @Published var RespringMode: Int {
        didSet {
            UserDefaults.standard.set(RespringMode, forKey: "RespringMode")
        }
    }

    init() {
        self.autoRespring = UserDefaults.standard.bool(forKey: "autoRespring")
        self.dev = UserDefaults.standard.bool(forKey: "dev")
        self.exploit_method = UserDefaults.standard.integer(forKey: "exploit_method")
        self.enforce_exploit_method = UserDefaults.standard.bool(forKey: "enforce_exploit_method")
        self.mdc_unsandbox = UserDefaults.standard.bool(forKey: "mdc_unsandbox")
        self.puafPagesIndex = UserDefaults.standard.integer(forKey: "puafPagesIndex")
        self.puafMethod = UserDefaults.standard.integer(forKey: "puafMethod")
        self.kreadMethod = UserDefaults.standard.integer(forKey: "kreadMethod")
        self.kwriteMethod = UserDefaults.standard.integer(forKey: "kwriteMethod")
        self.puafPages = UserDefaults.standard.integer(forKey: "puafPages")
        self.RespringMode = UserDefaults.standard.integer(forKey: "RespringMode")
        if UserDefaults.standard.object(forKey: "puafPagesIndex") == nil {
            self.puafPagesIndex = 7
        }
        if UserDefaults.standard.object(forKey: "puafPages") == nil {
            self.puafPages = 0
        }
        if UserDefaults.standard.object(forKey: "puafMethod") == nil {
            self.puafMethod = 1
        }
        if UserDefaults.standard.object(forKey: "kreadMethod") == nil {
            self.kreadMethod = 1
        }
        if UserDefaults.standard.object(forKey: "kwriteMethod") == nil {
            self.kwriteMethod = 1
        }
        if UserDefaults.standard.object(forKey: "RespringMode") == nil {
            self.RespringMode = 0
        }
    }
}
