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

    func save() {
        if let encodedData = try? JSONEncoder().encode(RepoData) {
            UserDefaults.standard.set(encodedData, forKey: "appData")
        }
        if let encodedData = try? JSONEncoder().encode(UserData) {
            UserDefaults.standard.set(encodedData, forKey: "userAppData")
        }
    }

    func load() {
        if let encodedData = UserDefaults.standard.data(forKey: "appData"),
           let decodedData = try? JSONDecoder().decode(SavedRepoData.self, from: encodedData) {
            RepoData = decodedData
        }
        if let encodedData = UserDefaults.standard.data(forKey: "userAppData"),
           let decodedData = try? JSONDecoder().decode(SavedUserData.self, from: encodedData) {
            UserData = decodedData
        }
    }
    
    static let shared = AppData()
}

struct SavedRepoData: Codable {
    var urls: [URL] = defaulturls().urls
}

struct SavedUserData: Codable {
    var exploit_method = 0 // For Overriding the Exploit Method
    var install_method = 0 // Install Method
    var override_exploit_method = false // For Overriding the Exploit Method
    var kfd = SavedKFDData() // For Overriding the Exploit Method
    var respringMode = 0 // [frontboard, backboard] Sets the respring type
    var customback = false // Shows a cool circle back button
    var allowlight = false // Allows Light Mode (not normally allowed)
    var dev = true // Developer Mode!
    var translateoninstall = true // Translate Prefs on install
    var defaultPkgCreatorType = "picasso" // eta s0n
    var PureKFDFilePicker = true // Use built in file picker
    var filters = SavedFilters() // Filters packages
    var lastCopiedFile = "" // Clipboard for the file manager
    // Dummy values
    var refresh = false // This just gets toggled on or off to refresh the view
}

struct SavedFilters: Codable, Equatable {
    var kfd = false // Hides kfd/mdc tweaks (enabled automatically when no exploit is found)
    var ipa = false // Hides apps
    var jb = false // Hides jb tweaks (enabled automatically when no exploit is found)
    var shortcuts = false // Hides shortcuts
}

struct SavedKFDData: Codable, Equatable {
    var puaf_pages = 4096 // Puaf Pages (pls dont change this unless you have less then 4gb of ram, it should be 3072)
    var puaf_pages_index = 8 // Puaf Pages (pls dont change this unless you have less then 4gb of ram, it should be 8)
    var puaf_method = 1 // Physpuppet or Smith (smith works for all)
    var kread_method = 1 // kqueue_workloop_ctl or sem_open (sem_open works for all)
    var kwrite_method = 1 // dup or sem_open (sem_open works for all)
}

struct defaulturls {
    let urls: [URL] = [
        // PureKFD Repos
        URL(string: "https://raw.githubusercontent.com/Lrdsnow/lrdsnows-repo/main/PureKFDv4/purerepo.json")!,
        URL(string: "https://raw.githubusercontent.com/Dreel0akl/poopypoopermaybeworking/master/Essentials/manifest.json")!,
        URL(string: "https://raw.githubusercontent.com/dora727/KaedeFriedDora/master/Essentials/manifest.json")!,
        // Picasso Repos
        URL(string: "https://raw.githubusercontent.com/circularsprojects/circles-repo/main/manifest.json")!,
        URL(string: "https://raw.githubusercontent.com/sourcelocation/Picasso-test-repo/main/manifest.json")!,
        URL(string: "https://bomberfish.ca/PicassoRepos/Essentials/manifest.json")!,
        // Cowabunga Explore Repos:
        //URL(string: "https://raw.githubusercontent.com/leminlimez/Cowabunga-explore-repo/main/cc-themes.json")!,
        //URL(string: "https://raw.githubusercontent.com/leminlimez/Cowabunga-explore-repo/main/icon-themes.json")!,
        URL(string: "https://raw.githubusercontent.com/leminlimez/Cowabunga-explore-repo/main/lock-themes.json")!,
        //URL(string: "https://raw.githubusercontent.com/leminlimez/Cowabunga-explore-repo/main/passcode-themes.json")!,
        // Flux Repos
        //URL(string: "https://purekfd.pages.dev/pureflux/fluxrepo.json")!,
        // Altstore Repos
        //URL(string: "https://ipa.cypwn.xyz/cypwn.json")!,
        //URL(string: "https://skadz.online/repo")!,
        //URL(string: "https://quarksources.github.io/dist/quantumsource.min.json")!,
        //URL(string: "https://cdn.altstore.io/file/altstore/apps.json")!,
        // Scarlet Repos
        //URL(string: "https://raw.githubusercontent.com/azu0609/repo/main/scarlet_repo.json")!,
        // Esign Repos
        //URL(string: "https://raw.githubusercontent.com/iwishkem/iwishkem.github.io/main/esign.json")!,
        // JB Repos
        //URL(string: "https://raw.githubusercontent.com/34306/34306.github.io/master/Release")!,
//        URL(string: "https://havoc.app/Release")!,
//        URL(string: "https://repo.alexia.lol/Release")!,
//        URL(string: "https://repo.anamy.gay/Release")!,
//        URL(string: "https://repo.chariz.com/Release")!,
//        URL(string: "https://cokepokes.github.io/Release")!,
//        URL(string: "https://repo.cypwn.xyz/Release")!,
//        URL(string: "https://ginsu.dev/repo/Release")!,
//        URL(string: "https://hacx.org/repo/Release")!,
//        URL(string: "https://havoc.app/Release")!,
//        URL(string: "https://julioverne.github.io/Release")!,
//        URL(string: "https://repo.packix.com/Release")!,
//        URL(string: "https://paisseon.github.io/Release")!,
//        URL(string: "https://repo.palera.in/Release")!,
        // Misaka Repos
        URL(string: "http://phucdo-repo.pages.dev/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/shimajiron/Misaka_Network/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/34306/iPA/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/roeegh/Puck/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/hanabiADHD/nbxyRepo/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/huligang/coolwcat/main/repo.json")!,
        URL(string: "https://yangjiii.tech/file/Repo/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/leminlimez/leminrepo/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/ichitaso/misaka/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/chimaha/misakarepo/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/sugiuta/repo-mdc/master/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/Fomri/fomrirepo/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/EPOS05/EPOSbox/main/misaka.json")!,
        URL(string: "https://raw.githubusercontent.com/tdquang266/MDC/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/kloytofyexploiter/Misaka-repo_MRX/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/HackZy01/aurora/main/pure.json")!,
        URL(string: "https://raw.githubusercontent.com/tyler10290/MisakaRepoBackup/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/hanabiADHD/DekotasMirror/main/dekotas.json")!,
    ]
}
