//
//  Installed.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import SwiftUI
import SwiftKFD_objc

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
    @State private var packages: [String:[Package]] = [:]
    
    @State private var showDetailView = false
    @State private var CurrentPackage = Package(name: "Nil", bundleID: "nil", author: "Nil", version: "Nil", desc: "Nil", longdesc: "", icon: URL(string: ""), accent: nil, screenshots: [], banner: nil, previewbg: nil, category: "Misc", install_actions: [], uninstall_actions: [], url: nil, pkgtype: "unknown")
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    VStack {
                        HStack(alignment: .center) {
                            if appData.queued.isEmpty {
                                Button(action: {applyTweaks(appData: appData)}, label: {HStack { Spacer(); Image("apply_icon").renderingMode(.template); Text("Apply"); Spacer(); }})
                                    .padding(.vertical, 5).buttonStyle(.borderedProminent).tint(.accentColor.opacity(0.2))
                            } else {
                                Button(action: {
                                    Task {
                                        Task {
                                            for qpkg in appData.queued {
                                                let pkgd = PackageDetailView(package: qpkg, appData: appData)
                                                pkgd.downloadPackage(pkg: qpkg)
                                            }
                                        }
                                        Task {
                                            appData.queued = []
                                            packages = [:]
                                            Task {
                                                await updatePackages()
                                            }
                                        }
                                    }
                                }, label: {HStack { Spacer(); Image("download_icon").renderingMode(.template); Text("Install Queued"); Spacer()}})
                                .padding(.vertical, 5).buttonStyle(.borderedProminent).tint(.accentColor.opacity(0.2))
                            }
                            if appData.queued.isEmpty {
                                Button(action: {
                                    if(appData.UserData.respringMode == 0)
                                    {restartFrontboard()}
                                    else if (appData.UserData.respringMode == 1) {restartBackboard()}
                                    else if (appData.UserData.respringMode == 2) {userspaceReboot()}
                                }, label: {HStack { Spacer(); Image("reload_icon").renderingMode(.template); Text("Respring"); Spacer()}})
                                .padding(.vertical, 5)
                                .contextMenu(menuItems: {
                                    Button(action: {restartFrontboard()}, label: {Text("Frontboard Respring"); Image("reload_icon").renderingMode(.template)})
                                    Button(action: {restartBackboard()}, label: {Text("Backboard Respring"); Image("reload_icon").renderingMode(.template)})
                                }).buttonStyle(.borderedProminent).tint(.accentColor.opacity(0.2))
                            } else {
                                Button(action: {appData.queued = []; packages = [:]; Task { await updatePackages()}}, label: {HStack { Spacer(); Image("cancel_icon").renderingMode(.template); Text("Cancel"); Spacer()}})
                                    .padding(.vertical, 5).buttonStyle(.borderedProminent).tint(.accentColor.opacity(0.2))
                            }
                        }
                        if appData.UserData.dev {
                            CustomNavigationLink(destination: {DeveloperView()}, label: {HStack { Spacer(); Image("plus_icon").renderingMode(.template); Text("Extras"); Spacer() }})
                        }
                    }.padding(.horizontal).listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                    
                    let package_keys = Array(packages.keys)
                    ForEach(package_keys, id: \.self) { sub_packageKey in
                        Section(header: Text(sub_packageKey)) {
                            ForEach(packages[sub_packageKey]!, id: \.id) { package in
                                if package.hasprefs ?? false, #available(iOS 15.0, *) {
                                    NavigationLink(destination: PrefView(pkg: package)) {
                                        InstalledPkgRow(package: package, installedView: self)
                                    }
                                } else {
                                    InstalledPkgRow(package: package, installedView: self)
                                }
                            }
                        }.listRowBackground(Color.clear)
                    }
                }
                // isActive triggers
                if #available(iOS 15.0, *) {
                    NavigationLink(destination: PackageDetailView(package: CurrentPackage, appData: appData), isActive: $showDetailView) {}
                }
                //
            }
            .onAppear() {
                haptic()
                Task { await updatePackages() }
            }
            .navigationTitle("Installed")
            .bgImage(appData)
        }.navigationViewStyle(.stack)
    }
    
    private struct InstalledPkgRow: View {
        @State var package: Package
        @State var installedView: InstalledView
        @EnvironmentObject var appData: AppData
        var body: some View {
            VStack {
                PkgRow(pkgname: package.name, pkgauthor: package.author, pkgiconURL: package.icon, pkg: package, installedPackageView: true)
                    .contextMenu {
                        if findPackageViaBundleID(package.bundleID, appdata: appData) != nil {
                            Button(action: {
                                installedView.CurrentPackage = package
                                installedView.showDetailView = true
                            }) {
                                Text("Show Details")
                                Image("pkg_icon").renderingMode(.template)
                            }
                        }
                        Button(action: {
                            let pasteboard = UIPasteboard.general
                            pasteboard.string = package.bundleID
                        }) {
                            Text("Copy Bundle ID")
                            Image("copy_icon").renderingMode(.template)
                        }
                        Button(action: {
                            var temppkg = package
                            if temppkg.disabled != nil {
                                temppkg.disabled?.toggle()
                            } else {
                                temppkg.disabled = true
                            }
                            temppkg.saveAsJSON()
                            Task { await installedView.updatePackages() }
                        }) {
                            Text(package.disabled ?? false ? "Enable Package" : "Disable Package")
                            Image(package.disabled ?? false ? "app_icon" : "disabled_app_icon").renderingMode(.template)
                        }
                        if FileManager.default.fileExists(atPath: URL.documents.appendingPathComponent("installed/\(package.bundleID)/save.json").path) {
                            Button() {
                                do {
                                    try FileManager.default.removeItem(at: URL.documents.appendingPathComponent("installed/\(package.bundleID)/save.json"))
                                } catch {}
                            } label: {
                                Text("Clear Package Data")
                                Image("trash_icon").renderingMode(.template)
                            }.foregroundColor(.red)
                        }
                        Button() {
                            purgePackage(package.bundleID)
                            Task { await installedView.updatePackages() }
                        } label: {
                            Text("Delete Package")
                            Image("trash_icon").renderingMode(.template)
                        }.foregroundColor(.red)
                    }
                if let status = appData.applyStatus[package.bundleID] {
                    LoadingBarView(status: status).padding(.top)
                }
            }
        }
    }
    
    private struct LoadingBarView: View {
        let status: ApplyStatus
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("Apply Status: \(status.message)")
                ProgressView(value: Double(status.percentage) / 100.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 2)
            }
            .foregroundColor(.secondary)
            .padding(.vertical, 5)
        }
    }
        
    private func updatePackages() async {
        if !appData.queued.isEmpty {
            packages["Queued"] = appData.queued
        }
        packages["Installed"] = getInstalledPackages().sorted(by: { $0.name < $1.name })
    }
}


