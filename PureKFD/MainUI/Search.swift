//
//  Search.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/1/23.
//

import Foundation
import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Package] = []

    var body: some View {
        VStack(spacing: 0) {
            TextField("", text: $searchText)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search Packages").foregroundColor(.purple.opacity(0.7))
                }
                .padding(7)
                .background(Color.clear)
                .foregroundColor(Color.purple)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.purple, lineWidth: 1)
                )
                .padding(.horizontal, 15)
                .disableAutocorrection(true)
                .onChange(of: searchText) { newValue in
                    searchResults = PackageManager.shared.searchPackages(with: newValue)
            }
            
            List(searchResults) { package in
                NavigationLink(destination: PackageDetailView(package: package)) {
                    PackageRow(package: package)
                }.listRowBackground(Color.clear)
            }
        }
    }
}
