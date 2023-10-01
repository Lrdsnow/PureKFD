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
    var exploit_method = 0
    var override_exploit_method = false
    var kfd = SavedKFDData()
    var respringMode = 0
    var customback = false
    var navbarblur = true
    var allowlight = false
    var dev = false
    var allowroot = false
    var translateoninstall = true
    var defaultPkgCreatorType = "picasso"
    var purekfdFilePicker = true
    // Dummy values
    var refresh = false
}

struct SavedKFDData: Codable, Equatable {
    var puaf_pages = 2048
    var puaf_pages_index = 7
    var puaf_method = 1
    var kread_method = 1
    var kwrite_method = 1
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
        // Flux Repos
//        URL(string: "https://raw.githubusercontent.com/Broco8Dev/Flux/main/RepositoryManagement/Repos.json")!,
        // JB Repos
//        URL(string: "https://raw.githubusercontent.com/34306/34306.github.io/master/Release")!,
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
        URL(string: "https://misakarepojson.pages.dev/repo.json")!,
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
        URL(string: "https://raw.githubusercontent.com/HackZy01/misio/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/tyler10290/MisakaRepoBackup/main/repo.json")!,
        URL(string: "https://raw.githubusercontent.com/hanabiADHD/DekotasMirror/main/dekotas.json")!,
    ]
}
