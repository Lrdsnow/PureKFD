//
//  Installed.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import SwiftUI

extension Package {
    func saveAsJSON() {
        if let data = try? JSONEncoder().encode(self) {
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let folderURL = documentsDirectory.appendingPathComponent("installed").appendingPathComponent(bundleID)
                try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                let fileURL = folderURL.appendingPathComponent("info.json")
                try? data.write(to: fileURL)
            }
        }
    }
}

struct InstalledView: View {
    @EnvironmentObject var appData: AppData
    @State private var packages: [Package] = []
    
    @State private var showDetailView = false
    @State private var CurrentPackage = Package(name: "Nil", bundleID: "nil", author: "Nil", version: "Nil", desc: "Nil", longdesc: "", icon: URL(string: ""), accent: nil, screenshots: [], banner: nil, previewbg: nil, url: nil, pkgtype: "unknown", purekfd: nil, misaka: nil, picasso: nil)
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(alignment: .center) {
                    Spacer()
                    Button(action: {applyTweaks(appData: appData)}, label: {HStack { Image("apply_icon").renderingMode(.template); Text("Apply")}})
                        .padding(.horizontal).padding(.vertical, 5)
                    Spacer()
                    Button(action: {if(appData.UserData.respringMode == 0) {respring()} else {backboard_respring()}}, label: {HStack { Image("reload_icon").renderingMode(.template); Text("Respring")}})
                        .padding(.horizontal).padding(.vertical, 5)
                        .contextMenu(menuItems: {
                            Button(action: {respring()}, label: {Text("Frontboard Respring"); Image("reload_icon").renderingMode(.template)})
                            Button(action: {backboard_respring()}, label: {Text("Backboard Respring"); Image("reload_icon").renderingMode(.template)})
                        })
                    Spacer()
                }
                List {
                    ForEach($packages, id: \.id) { package in
                        if package.hasprefs.wrappedValue == true {
                            NavigationLink(destination: PrefView(pkg: package.wrappedValue)) {
                                PkgRow(pkgname: package.name.wrappedValue, pkgauthor: package.author.wrappedValue, pkgiconURL: package.icon.wrappedValue, pkg: package.wrappedValue, installedPackageView: true)
                                    .contextMenu {
                                        if findPackageViaBundleID(package.wrappedValue.bundleID, appdata: appData) != nil {
                                            Button(action: {
                                                CurrentPackage = package.wrappedValue
                                                showDetailView = true
                                            }) {
                                                Text("Show Details")
                                                Image("pkg_icon").renderingMode(.template)
                                            }
                                        }
                                        Button(action: {
                                            let pasteboard = UIPasteboard.general
                                            pasteboard.string = package.bundleID.wrappedValue
                                        }) {
                                            Text("Copy Bundle ID")
                                            Image("copy_icon").renderingMode(.template)
                                        }
                                        Button(action: {
                                            var temppkg = package.wrappedValue
                                            if temppkg.disabled != nil {
                                                temppkg.disabled?.toggle()
                                            } else {
                                                temppkg.disabled = true
                                            }
                                            temppkg.saveAsJSON()
                                            updatePackages()
                                        }) {
                                            Text(package.disabled.wrappedValue ?? false ? "Enable Package" : "Disable Package")
                                            Image(package.disabled.wrappedValue ?? false ? "app_icon" : "disabled_app_icon").renderingMode(.template)
                                        }
                                        if FileManager.default.fileExists(atPath: URL.documents.appendingPathComponent("installed/\(package.bundleID.wrappedValue)/save.json").path) {
                                            Button(role: .destructive) {
                                                do {
                                                    try FileManager.default.removeItem(at: URL.documents.appendingPathComponent("installed/\(package.bundleID.wrappedValue)/save.json"))
                                                } catch {}
                                            } label: {
                                                Text("Clear Package Data")
                                                Image("trash_icon").renderingMode(.template)
                                            }
                                        }
                                        Button(role: .destructive) {
                                            purgePackage(package.bundleID.wrappedValue)
                                            updatePackages()
                                        } label: {
                                            Text("Delete Package")
                                            Image("trash_icon").renderingMode(.template)
                                        }
                                    }
                            }
                        } else {
                            PkgRow(pkgname: package.name.wrappedValue, pkgauthor: package.author.wrappedValue, pkgiconURL: package.icon.wrappedValue, pkg: package.wrappedValue, installedPackageView: true)
                                .contextMenu {
                                    if findPackageViaBundleID(package.wrappedValue.bundleID, appdata: appData) != nil {
                                        Button(action: {
                                            CurrentPackage = package.wrappedValue
                                            showDetailView = true
                                        }) {
                                            Text("Show Details")
                                            Image("pkg_icon").renderingMode(.template)
                                        }
                                    }
                                    Button(action: {
                                        let pasteboard = UIPasteboard.general
                                        pasteboard.string = package.bundleID.wrappedValue
                                    }) {
                                        Text("Copy Bundle ID")
                                        Image("copy_icon").renderingMode(.template)
                                    }
                                    Button(action: {
                                        var temppkg = package.wrappedValue
                                        if temppkg.disabled != nil {
                                            temppkg.disabled?.toggle()
                                        } else {
                                            temppkg.disabled = true
                                        }
                                        temppkg.saveAsJSON()
                                        updatePackages()
                                    }) {
                                        Text(package.disabled.wrappedValue ?? false ? "Enable Package" : "Disable Package")
                                        Image(package.disabled.wrappedValue ?? false ? "app_icon" : "disabled_app_icon").renderingMode(.template)
                                    }
                                    Button(role: .destructive) {
                                        purgePackage(package.bundleID.wrappedValue)
                                        updatePackages()
                                    } label: {
                                        Text("Delete Package")
                                        Image("trash_icon").renderingMode(.template)
                                    }
                                }
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .onAppear() {
                    updatePackages()
                }
                // isActive triggers
                NavigationLink(destination: PackageDetailView(package: CurrentPackage, appData: appData), isActive: $showDetailView) {}
                //
            }
            .navigationTitle("Installed")
        }
        .navigationViewStyle(.stack)
    }
    
    private func updatePackages() {
        packages = getInstalledPackages().sorted(by: { $0.name < $1.name })
    }
}
