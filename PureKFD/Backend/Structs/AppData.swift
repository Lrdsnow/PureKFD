//
//  AppData.swift
//  purekfd
//
//  Created by Lrdsnow on 6/28/24.
//

import Foundation
import SwiftUI

public class AppData: ObservableObject {
    @Published var repos: [Repo] = []
    @Published var pkgs: [Package] = []
    @Published var featured: [Featured] = []
    @Published var installed_pkgs: [Package] = []
    @Published var available_updates: [Package] = []
    @Published var queued_pkgs: [(Package, Double, Error?)] = [] // to install, to uninstall
    
    // Exploit stuff
    @AppStorage("selectedExploit") var selectedExploit = 0
    @AppStorage("FilterPackages") var filterPackages = true
    @AppStorage("savedExploitSettings") var savedSettings: [String: String] = [:]
    
    static let shared = AppData()
}
