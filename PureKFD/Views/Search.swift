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
    @State private var selectedCategories: Set<String> = []

    var uniqueCategories: [String] {
        let allCategories = Set(getPackageList(appdata: appData).map { $0.category }).sorted()
        let selected = allCategories.filter { selectedCategories.contains($0) }
        let unselected = allCategories.filter { !selectedCategories.contains($0) }
        return selected + unselected
    }

    var filteredPackages: [Package] {
        var packages = getPackageList(appdata: appData)

        if !selectedCategories.isEmpty {
            packages = packages.filter { package in
                selectedCategories.contains(package.category)
            }
        }

        if !searchText.isEmpty {
            packages = packages.filter { package in
                return package.name.localizedCaseInsensitiveContains(searchText) || package.bundleID.localizedCaseInsensitiveContains(searchText)
            }
        }

        return packages
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchText)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal)
                    .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                    .padding(.vertical, 5)
                    .autocorrectionDisabled()
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.accentColor, lineWidth: 1)
                            .padding(.horizontal)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(uniqueCategories, id: \.self) { category in
                            Button(action: {
                                if selectedCategories.contains(category) {
                                    selectedCategories.remove(category)
                                } else {
                                    selectedCategories.insert(category)
                                }
                            }) {
                                Text(category)
                                    .foregroundColor(selectedCategories.contains(category) ? .white : .accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedCategories.contains(category) ? Color.accentColor : Color.clear)
                                    .overlay(
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .stroke(Color.accentColor, lineWidth: 2)
                                            )
                                    .cornerRadius(15)
                            }.shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        }
                    }
                    .padding(.horizontal)
                }

                List(filteredPackages.sorted(by: { $0.name < $1.name })) { package in
                    NavigationLink(destination: PackageDetailView(package: package, appData: appData)) {
                        PkgRow(pkgname: package.name, pkgauthor: package.author, pkgiconURL: package.icon, pkg: package)
                    }
                    .mainViewTweaks().listRowBackground(Color.clear)
                }
            }
            .bgImage(appData)
            .onAppear { haptic() }
            .navigationTitle("Search")
        }.navigationViewStyle(.stack)
    }
}



