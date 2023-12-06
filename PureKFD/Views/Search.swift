//
//  Search.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appData: AppData
    @State private var searchText = ""
    
    var filteredPackages: [Package] {
        if searchText.isEmpty {
            return getPackageList(appdata: appData)
        } else {
            return getPackageList(appdata: appData)
                .filter { package in
                    return package.name.localizedCaseInsensitiveContains(searchText) || package.bundleID.localizedCaseInsensitiveContains(searchText)
                }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchText)
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                
                List(filteredPackages.sorted(by: { $0.name < $1.name })) { package in
                    NavigationLink(destination: PackageDetailView(package: package, appData: appData)) {
                        PkgRow(pkgname: package.name, pkgauthor: package.author, pkgiconURL: package.icon, pkg: package)
                    }
                    .mainViewTweaks()
                }
            }
            .onAppear {haptic()}
            .navigationTitle("Search")
        }
    }
}

