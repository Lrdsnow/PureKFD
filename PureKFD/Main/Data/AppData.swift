//
//  AppData.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import Foundation
import SwiftUI

class AppData: ObservableObject {
    @Published var RepoData = SavedRepoData()
    @Published var UserData = SavedUserData()
    @Published var refreshedRepos = false
    @Published var repoSections: [String: [Repo]] = [:]
    @Published var kopened = false
    @Published var queued: [Package] = []
    @Published var reloading_browse = false // wether or not browse is being reloaded
    @Published var bg: UIImage? = nil
    @Published var appColors: AppColors = AppColors()
    @Published var applyStatus: [String:ApplyStatus] = ["uwu.lrdsnow.test":ApplyStatus(message: "ui test...", percentage: 50)]

    func save() {
        do {
            // Create the config folder if not found
            let configDirectory = URL.documents.appendingPathComponent("config", isDirectory: true)
            if !FileManager.default.fileExists(atPath: configDirectory.path) {
                try FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            // save repodata
            var rdata = RepoData
            let default_urls = defaulturls()
            for url in default_urls.urls {
                rdata.urls = rdata.urls.filter { $0 != url }
            }
            let encodedRepoData = try JSONEncoder().encode(rdata)
            try encodedRepoData.write(to: configDirectory.appendingPathComponent("repoData.json"))
            // save userdata
            NSLog("%@", "userData: \(UserData)")
            let encodedUserData = try JSONEncoder().encode(UserData)
            try encodedUserData.write(to: configDirectory.appendingPathComponent("userData.json"))
        } catch {
            NSLog("%@", "Error saving data: \(error)")
        }
    }

    func load() {
        do {
            // load repodata
            let appDataPath = URL.documents.appendingPathComponent("config/repoData.json")
            if FileManager.default.fileExists(atPath: appDataPath.path) {
                let encodedData = try Data(contentsOf: appDataPath)
                let decodedData = try JSONDecoder().decode(SavedRepoData.self, from: encodedData)
                RepoData = decodedData
            }
            // load userdata
            let userAppDataPath = URL.documents.appendingPathComponent("config/userData.json")
            if FileManager.default.fileExists(atPath: userAppDataPath.path) {
                let encodedData = try Data(contentsOf: userAppDataPath)
                let decodedData = try JSONDecoder().decode(SavedUserData.self, from: encodedData)
                UserData = decodedData
            }
        } catch {
            NSLog("%@", "Error loading data: \(error)")
        }
    }

    
    static let shared = AppData()
}

struct ApplyStatus: Codable, Equatable {
    var message = "..."
    var percentage: Double = 0.0
}

struct SavedRepoData: Codable {
    var urls: [URL] = defaulturls().urls
}

struct SavedUserData: Codable {
    var exploit_method = 0 // For Overriding the Exploit Method
    var install_method = 0 // Install Method
    var override_exploit_method = true // For Overriding the Exploit Method
    var kfd = SavedKFDData() // For Overriding the Exploit Method
    var respringMode = 0 // [frontboard, backboard] Sets the respring type
    var customback = false // Shows a cool circle back button
    var allowlight = false // Allows Light Mode (not normally allowed)
    var hideMissingEntitlementWarning = false // Whether the user has hidden the notification about not having the increased memory limit entitlement
    var dev = true // Developer Mode!
    var translateoninstall = true // Translate Prefs on install
    var defaultPkgCreatorType = "picasso" // eta s0n
    var PureKFDFilePicker = true // Use built in file picker
    var filters = SavedFilters() // Filters packages
    var lastCopiedFile = "" // Clipboard for the file manager
    var savedAppColors = SavedAppColors()
    var betaRepos = false
    var ghToken: String? = nil
    var verifyApply = false
    // Dummy values
    var refresh = false // This just gets toggled on or off to refresh the view
}

struct SavedFilters: Codable, Equatable {
    var kfd = false // Hides kfd/mdc tweaks (enabled automatically when no exploit is found)
    var ipa = false // Hides apps
    var jb = false // Hides jb tweaks (enabled automatically when no exploit is found)
    var shortcuts = false // Hides shortcuts
}

struct SavedAppColors: Codable {
    var name: String = ""
    var author: String = ""
    var description: String = ""
    var background: String = ""
    var accent: String = ""
}

struct AppColors {
    var name: Color = Color.accentColor
    var author: Color = Color.accentColor.opacity(0.5)
    var description: Color = Color.accentColor.opacity(0.7)
    var background: Color = Color.clear
    var accent: Color = Color.accentColor
}

struct SavedKFDData: Codable, Equatable {
    var puaf_pages = 4096 // Puaf Pages (pls dont change this unless you have less then 4gb of ram, it should be 3072)
    var puaf_pages_index = 8 // Puaf Pages (pls dont change this unless you have less then 4gb of ram, it should be 8)
    var puaf_method = 2 // Physpuppet or Smith or Landa (smith works for all)
    var kread_method = 1 // kqueue_workloop_ctl or sem_open (sem_open works for all)
    var kwrite_method = 1 // dup or sem_open (sem_open works for all)
    var use_static_headroom = false // just dont use static headroom if the user doesnt wanna
    var static_headroom = 65536 // headroom for ram hogger
    var static_headroom_sel = 11 // headroom selection
}

struct defaulturls {
    let urls: [URL] = [
        // PureKFD Repos
        URL(string: "https://raw.githubusercontent.com/PureKFD/PureKFDRepo/main/bridge.json")!, // PureKFD Repo - Offical PureKFD Repo
        URL(string: "https://raw.githubusercontent.com/Dreel0akl/poopypoopermaybeworking/master/Essentials/manifest.json")!, // Poop Repo - Main Repo - Built for PureKFD
        URL(string: "https://raw.githubusercontent.com/dora727/KaedeFriedDora/master/bridge.json")!, // MeowRepo - Main & Beta Repo's - Built for PureKFD
        URL(string: "https://raw.githubusercontent.com/circularsprojects/circles-repo/main/purekfd.json")!, // Circular's Repo - Main Repo - Built for PureKFD
        URL(string: "https://raw.githubusercontent.com/EPOS05/EPOSbox/main/purekfd.json")!, // EPOS Box - Main Repo - Built for PureKFD
        URL(string: "https://raw.githubusercontent.com/34306/iPA/main/PureKFD/purekfd.json")!, // Huy's Repo - Main Repo - Built for PureKFD
        URL(string: "https://raw.githubusercontent.com/HackZy01/aurora/main/purekfd.json")!, // Aurora - Main Repo - Built for PureKFD
        URL(string: "https://raw.githubusercontent.com/YangJiiii/YangJiiii.github.io/main/file/Repo/purekfd.json")!, // YangJiii's Repo - Main Repo - Built for PureKFD
        URL(string: "https://raw.githubusercontent.com/dobabaophuc1706/misakarepo/main/purekfd.json")!, // Phuc Do's Repo - Main Repo - Built for PureKFD
        // Picasso Repos
        URL(string: "https://raw.githubusercontent.com/sourcelocation/Picasso-test-repo/main/manifest.json")!, // Beta Picasso Repo
        URL(string: "https://bomberfish.ca/PicassoRepos/Essentials/manifest.json")! // Main Picasso Repo
    ]
}
