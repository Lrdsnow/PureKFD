//
//  TweakCreator.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/24/23.
//

import Foundation
import SwiftUI
import UIKit
import Zip
import UniformTypeIdentifiers

@available(iOS 15.0, *)
struct TweakCreatorView: View {
    var body: some View {
        CreatorView()
    }
}

@available(iOS 15.0, *)
struct CreatorView: View {
    @State private var packageInfo: [String: String] = [
        "version": "1.0",
        "author": "",
        "name": "",
        "bundleID": ""
    ]
    @EnvironmentObject var appData: AppData
    @State private var pkgtype: String = "PureKFD"
    @State private var version: String = "1.0"
    @State private var author: String = "Package Author"
    @State private var name: String = "Package Name"
    @State private var bundleID: String = "pkg.bundle.id"
    
    @State private var generatingpackage: Bool = false
    
    @State private var tweaks: [[String: Any]] = []
    @State private var filesToCopy: [String] = []
    
    var body: some View {
        List {
            Section(header: Text("Package Info")) {
//                Picker("Type", selection: $appData.UserData.defaultPkgCreatorType) {
//                    Text("PureKFD Extended").tag("PureKFD")
//                    Text("Picasso Compat").tag("picasso")
//                }.cornerRadius(10)
//                    .pickerStyle(.segmented)
//                    .colorMultiply(Color.accentColor)
//                    .onChange(of: appData.UserData.defaultPkgCreatorType, perform: {_ in
//                        appData.save()
//                    })
                HStack {
                    Text("Version: ")
                    Spacer()
                    TextField("Version", text: $version)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Author: ")
                    Spacer()
                    TextField("Author", text: $author)
                        .padding(.horizontal)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Name: ")
                    Spacer()
                    TextField("Name", text: $name)
                        .padding(.horizontal)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Bundle ID: ")
                    Spacer()
                    TextField("Bundle ID", text: $bundleID)
                        .padding(.horizontal)
                        .multilineTextAlignment(.trailing)
                }
            }.listRowBackground(Color.accentColor.opacity(0.2))
            
            Section(header: Text("Operations")) {
                ForEach(tweaks.indices, id: \.self) { index in
                    TweakRow(tweaks: $tweaks, tweak: $tweaks[index], filesToCopy: $filesToCopy, tweakIndex: index, bundleID: bundleID).padding()
                }
                Button(action: addTweak) {
                    Text("Add Operation")
                }
            }.listRowBackground(Color.accentColor.opacity(0.2))
            if appData.UserData.defaultPkgCreatorType == "PureKFD" {
                Section(header: Text("Preferences")) {
                    NavigationLink(destination: PrefCreator(), label: {Text("Create PureKFD Prefs")})
                }.listRowBackground(Color.accentColor.opacity(0.2))
            }
            HStack {
                Spacer()
                Button(action: {finishPackage(true)}) {
                    Text("Install Tweak")
                        .padding(.vertical, 8)
                        .cornerRadius(8)
                }.buttonStyle(.bordered).disabled(generatingpackage)
                Spacer()
                Button(action: {finishPackage(false)}) {
                    Text("Generate Package")
                        .padding(.vertical, 8)
                        .cornerRadius(8)
                }.buttonStyle(.bordered).disabled(generatingpackage)
                Spacer()
            }.clearListRowBackground()
        }.listStyle(.insetGrouped).navigationBarTitle("Tweak Creator", displayMode: .large)
    }
    
    func addTweak() {
        tweaks.append([
            "type": "replacing",
            "replacementFileBundled": true,
            "replacementFileName": "",
            "originPath": ""
        ])
    }
    
    func finishPackage(_ install: Bool) {
        if !generatingpackage {
            generatingpackage = true
            var destURL: URL? = nil
            // Create Package
            do {
                packageInfo["version"] = version
                packageInfo["author"] = author
                packageInfo["name"] = name
                packageInfo["bundleID"] = bundleID
                
                // Create info.json and tweak.json
                let infoData = try JSONSerialization.data(withJSONObject: packageInfo)
                let tweakData = try JSONSerialization.data(withJSONObject: ["operations": tweaks, "spec": "1.0"])
                
                // Create URLs for temporary files
                let pkgpath = FileManager.default.temporaryDirectory.appendingPathComponent("\(bundleID)")
                try FileManager.default.createDirectory(at: pkgpath, withIntermediateDirectories: true)
                let infoURL = pkgpath.appendingPathComponent("info.json")
                let tweakURL = pkgpath.appendingPathComponent("tweak.json")
                
                // Write data to temporary files
                try infoData.write(to: infoURL)
                try tweakData.write(to: tweakURL)
                
                // Copy assets
                for asset in filesToCopy {
                    do {
                        try FileManager.default.copyItem(at: URL(fileURLWithPath: asset), to: pkgpath.appendingPathComponent(asset.components(separatedBy: "/").last ?? ""))
                    } catch {
                        print("File Failed to copy!!!: \(asset) to \(pkgpath.appendingPathComponent(asset.components(separatedBy: "/").last ?? "").path)")
                    }
                }
                
                // Create a zip file
                let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(bundleID).PureKFD")
                try Zip.zipFiles(paths: [pkgpath], zipFilePath: zipURL, password: nil, progress: nil)
                
                // Move the zip file to app documents
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                destURL = documentsURL.appendingPathComponent("\(bundleID).PureKFD")
                try FileManager.default.moveItem(at: zipURL, to: destURL!)
                
                // Delete temp files
                try FileManager.default.removeItem(at: infoURL)
                try FileManager.default.removeItem(at: tweakURL)
            } catch {
                print("Error: \(error)")
            }
            // Install/Share
            if !install {
                let av = UIActivityViewController(activityItems: [destURL], applicationActivities: nil)
                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
            } else {
                let tempFileURL = URL.documents.appendingPathComponent("temp.zip")
                do {
                    try FileManager.default.moveItem(at: destURL ?? URL(fileURLWithPath: ""), to: tempFileURL)
                } catch {}
                let results = installPackage(pkg: Package(name: name, bundleID: bundleID, author: author, desc: "", longdesc: nil, accent: nil, screenshots: nil, banner: nil, previewbg: nil, install_actions: [], uninstall_actions: [], url: nil, pkgtype: "PureKFD"), path: tempFileURL, appData: appData)
                if results?.localizedDescription == nil {
                    UIApplication.shared.alert(title: "Success", body: "Package Installed", animated: false, withButton: true)
                } else {
                    UIApplication.shared.alert(title: "Error", body: results?.localizedDescription ?? "", animated: false, withButton: true)
                }
                do {
                    try FileManager.default.removeItem(at: tempFileURL)
                } catch {}
            }
            cleanTemp()
            generatingpackage = false
        }
    }
}

@available(iOS 15.0, *)
struct TweakRow: View {
    @Binding var tweaks: [[String: Any]]
    @Binding var tweak: [String: Any]
    @Binding var filesToCopy: [String]
    @State var tweakIndex: Int
    @State var bundleID: String
    @State private var pickedFilePath: String = "/"
    @State private var toFilePicker = true
    @State private var toPickedFilePath = ""
    @State private var toPickedFileFullPath = ""
    
    var body: some View {
        Group {
            HStack {
                VStack(alignment: .center) {
                    Picker("Type", selection: Binding<String>(
                        get: {
                            self.tweak["type"] as? String ?? ""
                        },
                        set: { newValue in
                            self.tweak["type"] = newValue
                        }
                    )) {
                        Text("Replacing").tag("replacing")
                        Text("Removing").tag("removing")
                        //Text("Lock").tag("lock")
                    }.cornerRadius(10)
                        .pickerStyle(.segmented)
                        .colorMultiply(Color.accentColor)
                }
                Button(action: deleteTweak) {
                    Image("trash_icon")
                        .renderingMode(.template)
                        .padding(5)
                        .foregroundColor(.red)
                        .background(Color.red.opacity(0.4))
                        .cornerRadius(10)
                }
            }.padding(.vertical, -10)
            
            if tweak["type"] as? String == "replacing" {
                Toggle("Replacement File Bundled", isOn: Binding<Bool>(
                    get: {
                        self.tweak["replacementFileBundled"] as! Bool == true
                    },
                    set: { newValue in
                        self.tweak["replacementFileBundled"] = newValue ? true : false
                        if !newValue {
                            self.pickedFilePath = ""
                        }
                    }
                )).padding(.vertical, -15)
                
                if tweak["replacementFileBundled"] as! Bool == true {
                    HStack {
                        @State var pickedFileFullPath = ""
                        AutoFilePickerView(pickedFilePath: $pickedFilePath, pickedFileFullPath: $pickedFileFullPath, type: [.font], label: "Select Replacement File", bundleID: bundleID)
                            .onChange(of: pickedFileFullPath, perform: {_ in
                                filesToCopy.append(pickedFileFullPath)
                            })
                    }.padding(.vertical, -10)
                } else {
                    TextField("Replacement File Name", text: Binding<String>(
                        get: {
                            self.tweak["replacementFileName"] as? String ?? ""
                        },
                        set: { newValue in
                            self.tweak["replacementFileName"] = newValue
                        }
                    ))
                }
                Group {
                    if toFilePicker {
                        HStack {
                            PureFilePickerView(pickedFilePath: $toPickedFilePath, pickedFileFullPath: $toPickedFileFullPath, label: "Select Target File", bundleID: bundleID, currentFullPath: "").onChange(of: toPickedFileFullPath, perform: {newValue in
                                self.tweak["originPath"] = newValue
                            }).onChange(of: (self.tweak["originPath"] as? String), perform: {newValue in
                                toPickedFileFullPath = newValue ?? ""
                                toPickedFilePath = newValue?.components(separatedBy: "/").last ?? ""
                            })
                        }
                    } else {
                        TextField("Path to Target File", text: Binding<String>(
                            get: {
                                self.tweak["originPath"] as? String ?? ""
                            },
                            set: { newValue in
                                self.tweak["originPath"] = newValue
                            }
                        ))
                    }
                }.padding(.vertical, -10).contextMenu(menuItems: {
                    Button(action: {
                        toFilePicker.toggle()
                    }) {
                        Text(toFilePicker ? "Manual Path Input" : "File Picker Path Input")
                        Image("gear_icon").renderingMode(.template)
                    }
                    Button(action: {
                        self.tweak["originPath"] = "/System/Library/Fonts/CoreUI/SFUI.ttf"
                    }) {
                        Text("System Font")
                        Image("edit_icon").renderingMode(.template)
                    }
                    Button(action: {
                        self.tweak["originPath"] = "/System/Library/Fonts/Watch/ADTTime.ttc"
                    }) {
                        Text("Clock Font")
                        Image("edit_icon").renderingMode(.template)
                    }
                })
            } else if tweak["type"] as? String == "removing" {
                Group {
                    if toFilePicker {
                        HStack {
                            PureFilePickerView(pickedFilePath: $toPickedFilePath, pickedFileFullPath: $toPickedFileFullPath, label: "Select Target File", bundleID: bundleID, currentFullPath: "").onChange(of: toPickedFileFullPath, perform: {newValue in
                                self.tweak["originPath"] = newValue
                            }).onChange(of: (self.tweak["originPath"] as? String), perform: {newValue in
                                toPickedFileFullPath = newValue ?? ""
                                toPickedFilePath = newValue?.components(separatedBy: "/").last ?? ""
                            })
                        }
                    } else {
                        TextField("Path to Target File", text: Binding<String>(
                            get: {
                                self.tweak["originPath"] as? String ?? ""
                            },
                            set: { newValue in
                                self.tweak["originPath"] = newValue
                            }
                        ))
                    }
                }.padding(.vertical, -10).contextMenu(menuItems: {
                    Button(action: {
                        toFilePicker.toggle()
                    }) {
                        Text(toFilePicker ? "Manual Path Input" : "File Picker Path Input")
                        Image("gear_icon").renderingMode(.template)
                    }
                })
            } else if tweak["type"] as? String == "lock" {
                Text("PureKFD Only!")
                    .padding(.vertical, -10)
                ForEach(0..<40, id: \.self) { index in
                    HStack {
                        @State var pickedFileFullPath = ""
                        AutoFilePickerView(pickedFilePath: $pickedFilePath, pickedFileFullPath: $pickedFileFullPath, type: [.font], label: "Select Lock Frame \(index + 1):", bundleID: bundleID)
                            .onChange(of: pickedFileFullPath, perform: {_ in
                                filesToCopy.append(pickedFileFullPath)
                            })
                    }.padding(.vertical, -10)
                }
            }
        }.onChange(of: pickedFilePath, perform: {newValue in
            self.tweak["replacementFileName"] = newValue
        })
    }
    
    func deleteTweak() {
        tweaks.remove(at: tweakIndex)
    }
}

@available(iOS 15.0, *)
struct AutoFilePickerView: View {
    @EnvironmentObject var appData: AppData
    @Binding var pickedFilePath: String
    @Binding var pickedFileFullPath: String
    @State var type: [UTType]
    @State var label: String
    @State var bundleID: String
    @State var filePickerPopOverTemp = false
    
    var body: some View {
        if appData.UserData.PureKFDFilePicker {
            PureFilePickerView(pickedFilePath: $pickedFilePath, pickedFileFullPath: $pickedFileFullPath, label: label, bundleID: bundleID)
        } else {
            Text(label)
            Spacer()
            FilePickerView(pickedFilePath: $pickedFilePath, type: type, bundleID: bundleID)
        }
    }
}

@available(iOS 15.0, *)
struct PureFilePickerView: View {
    @EnvironmentObject var appData: AppData
    @Binding var pickedFilePath: String
    @Binding var pickedFileFullPath: String
    @State var label: String
    @State var bundleID: String
    @State var filePickerPopOverTemp = false
    @State var currentFullPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path

    var body: some View {
        Group {
            Button(action: {
                filePickerPopOverTemp = true
            }) {
                HStack {
                    Text(label)
                    Spacer()
                    Text(pickedFilePath.components(separatedBy: "/").last ?? "")
                }
            }
            .sheet(isPresented: $filePickerPopOverTemp) {
                NavigationView {
                    FileBrowser(appData: appData, currentFullPath: currentFullPath, root: false, pickerpath: $pickedFilePath, popover: $filePickerPopOverTemp)
                        .listStyle(.insetGrouped)
                        .navigationTitle("File Picker")
                }.onDisappear {
                    filePickerPopOverTemp = false
                    pickedFileFullPath = pickedFilePath
                    let fileName = pickedFilePath.components(separatedBy: "/").last!
                    let assetsDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(bundleID)/assets")
                    do {
                        if FileManager.default.fileExists(atPath: assetsDirectoryURL.appendingPathComponent(fileName).path) {
                            try FileManager.default.removeItem(at: assetsDirectoryURL.appendingPathComponent(fileName))
                        }
                        do {
                            try FileManager.default.createDirectory(at: assetsDirectoryURL, withIntermediateDirectories: true)
                        } catch {}
                        let destinationURL = assetsDirectoryURL.appendingPathComponent(fileName)
                        try FileManager.default.copyItem(at: URL(fileURLWithPath: pickedFilePath), to: destinationURL)
                        pickedFilePath = "assets/\(fileName)"
                    } catch {
                        pickedFilePath = "Error"
                    }
                }
            }
        }
    }
}

struct FilePickerView: View {
    @Binding var pickedFilePath: String
    @State var type: [UTType]
    @State var bundleID: String
    @State var pickedFile: String = ""
    @State private var isFilePickerPresented: Bool = false
    
    var body: some View {
        HStack {
            Button(action: {
                self.isFilePickerPresented.toggle()
            }) {
                Text("\(pickedFile)")
            }
            .fileImporter(
                isPresented: $isFilePickerPresented,
                allowedContentTypes: type,
                allowsMultipleSelection: false
            ) { result in
                do {
                    if let selectedURLs = try? result.get() {
                        if let selectedURL = selectedURLs.first {
                            let fileName = selectedURL.lastPathComponent
                            let assetsDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(bundleID)/assets")
                            if selectedURL.startAccessingSecurityScopedResource() {
                                defer {
                                    selectedURL.stopAccessingSecurityScopedResource()
                                }
                                
                                if pickedFile != "" {
                                    do {
                                        try FileManager.default.removeItem(at: assetsDirectoryURL.appendingPathComponent(pickedFile))
                                    } catch {}
                                }
                                
                                try FileManager.default.createDirectory(at: assetsDirectoryURL, withIntermediateDirectories: true)
                                let destinationURL = assetsDirectoryURL.appendingPathComponent(fileName)
                                print(selectedURL)
                                print(destinationURL)
                                
                                try FileManager.default.copyItem(at: selectedURL, to: destinationURL)
                                pickedFilePath = "assets/\(fileName)"
                                pickedFile = "\(fileName)"
                            }
                        }
                    }
                } catch {
                    print("Error picking file: \(error)")
                    pickedFile = "Error"
                }
            }
        }
    }
}
