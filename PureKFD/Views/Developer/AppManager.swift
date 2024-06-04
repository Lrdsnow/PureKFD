//
//  AppManager.swift
//  PureKFD
//
//  Created by Lrdsnow on 11/8/23.
//

import Foundation
import SwiftUI
import NukeUI
import SwiftKFD
import SwiftKFD_objc

@available(iOS 15.0, *)
struct AppManagerView: View {
    @EnvironmentObject var appData: AppData
    @State var apps: [String:[String:[String:Any]]] = UserDefaults.standard.dictionary(forKey: "app_data") as? [String:[String:[String:Any]]] ?? [:]
    var body: some View {
        VStack {
            if !apps.isEmpty {
                List {
                    ForEach(apps.sorted(by: { $0.0 < $1.0 }), id: \.0) { key, value in
                        HStack {
                            if let appIconPath = (value["extras"] ?? [:])["icon"] as? String {
                                LazyImage(url: URL(fileURLWithPath: appIconPath)){ state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } else if state.error != nil {
                                        Image(uiImage: UIImage(named: "DisplayAppIcon")!)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        ProgressView()
                                            .scaledToFit()
                                    } }.frame(width: 40, height: 40).cornerRadius(10).onAppear()
                            }
                            if let infoDict = value["info"] {
                                Text("\(infoDict["CFBundleDisplayName"] as? String ?? (value["imDict"] ?? [:])["itemName"] as? String ?? "Unknown App") (\(key))")
                            } else if let imDict = value["imDict"] {
                                Text("\(imDict["itemName"] as? String ?? "Unknown iTunes App") (\(key))")
                            } else {
                                Text(key)
                            }
                        }
                    }
                }
            } else {
                ProgressView().task {
                    NSLog("%@", "\(UserDefaults.standard.dictionary(forKey: "app_data") ?? [:])")
                    let exploit_method = smart_kopen(appData: appData)
                    if exploit_method == 0 && appData.kopened {
                        do {
                            apps = try getApps(exploit_method: 0)
                        } catch { NSLog("%@","\(error)") }
                        do_kclose()
                        appData.kopened = false
                        UserDefaults.standard.set(apps, forKey: "app_data")
                    }
                }
            }
        }.bgImage(appData)
    }
}

func getApps(exploit_method: Int) throws -> [String:[String:[String:Any]]] {
    var apps: [String:[String:[String:Any]]] = UserDefaults.standard.dictionary(forKey: "app_data") as? [String:[String:[String:Any]]] ?? [:]
    let fm = FileManager.default
    let mounted = URL.documents.appendingPathComponent("mounted").path
    var dirlist = [""]
    
    if exploit_method == 0 {
        var existingAppUUIDs: [String] = []
        for (_, value) in apps {
            if let appextras = value["extras"] {
                if let appuuid = appextras["uuid"] as? String {
                    NSLog("%@", appuuid)
                    existingAppUUIDs.append(appuuid)
                }
            }
        }
        
        var vdata = createFolderAndRedirect2("/var/containers/Bundle/Application/")
        if vdata != UInt64.max {
            do {
                dirlist = try fm.contentsOfDirectory(atPath: URL.documents.appendingPathComponent("mounted").path)
                // NSLog(dirlist)
            } catch {
                throw "Could not access /var/mobile/Containers/Data/Application.\n\(error.localizedDescription)"
            }
            UnRedirectAndRemoveFolder2(vdata)
        }
        
        for dir in dirlist {
            if !existingAppUUIDs.contains(dir) {
                let mmpath = mounted + "/.com.apple.mobile_container_manager.metadata.plist"
                let metadata = mounted + "/BundleMetadata.plist"
                let imetadata = mounted + "/iTunesMetadata.plist"
                vdata = createFolderAndRedirect2("/var/containers/Bundle/Application/"+dir)
                if vdata != UInt64.max {
                    do {
                        var mmDict: [String: Any]
                        var extras: [String: String] = [:]
                        if fm.fileExists(atPath: mmpath) {
                            mmDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: mmpath)), options: [], format: nil) as? [String: Any] ?? [:]
                            //apps.append(mmDict)
                            NSLog("%@", "\(mmDict["MCMMetadataIdentifier"] ?? dir)")
                            var app:[String:[String:Any]] = ["mmdict":mmDict]
                            extras["uuid"] = dir
                            
                            var mDict: [String: Any]
                            if fm.fileExists(atPath: metadata) {
                                mDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: metadata)), options: [], format: nil) as? [String: Any] ?? [:]
                                app["mDict"] = mDict
                            }
                            var imDict: [String: Any]
                            if fm.fileExists(atPath: imetadata) {
                                imDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: imetadata)), options: [], format: nil) as? [String: Any] ?? [:]
                                app["imDict"] = imDict
                            }
                            do {
                                let bundleDirContents = try fm.contentsOfDirectory(atPath: mounted)
                                for item in bundleDirContents {
                                    var itemPath = "\(mounted)/\(item)"
                                    var isDirectory: ObjCBool = false
                                    NSLog("%@", "\(item)")
                                    if fm.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
                                        if isDirectory.boolValue && item.contains(".app") {
                                            NSLog("%@", "Found app: \(item)")
                                            var temp_vdata = UInt64.max
                                            do {
                                                NSLog("%@", "\(try fm.contentsOfDirectory(atPath: itemPath))")
                                            } catch {
                                                NSLog("Error Listing Contents.")
                                                temp_vdata = createFolderAndRedirectTemp("/var/containers/Bundle/Application/\(dir)/\(item)")
                                                itemPath = URL.documents.appendingPathComponent("temp").path
                                                do {
                                                    NSLog("%@", "Getting Contents of \(itemPath)")
                                                    NSLog("%@", "\(try fm.contentsOfDirectory(atPath: itemPath))")
                                                    NSLog("Getting Images and hoping they are correct")
                                                    let tempPath = fm.temporaryDirectory.appendingPathComponent("\(mmDict["MCMMetadataIdentifier"] as? String ?? "\(dir)")_icon.png").path
                                                    do {
                                                        try fm.removeItem(atPath: tempPath)
                                                    } catch {}
                                                    try fm.copyItem(atPath: "\(itemPath)/AppIcon60x60@2x.png", toPath: tempPath)
                                                    extras["icon"] = tempPath
                                                    NSLog("Getting Info")
                                                    let infoDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: "\(itemPath)/Info.plist")), options: [], format: nil) as? [String: Any] ?? [:]
                                                    NSLog("%@", "\(infoDict)")
                                                } catch {
                                                    NSLog("%@", "Error Occured: \(error.localizedDescription)")
                                                }
                                            }
                                            let infoPlist = "\(itemPath)/Info.plist"
                                            if fm.fileExists(atPath: infoPlist) {
                                                let infoDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: infoPlist)), options: [], format: nil) as? [String: Any] ?? [:]
                                                app["info"] = infoDict
                                                if let appIcons = infoDict["CFBundleIcons"] as? [String:Any] {
                                                    if let Icon = ((appIcons["CFBundlePrimaryIcon"] as? [String:Any] ?? [:])["CFBundleIconFiles"] as? [Any] ?? []).first as? String {
                                                        NSLog("%@", Icon)
                                                        do {
                                                            let tempPath = fm.temporaryDirectory.appendingPathComponent("\(mmDict["MCMMetadataIdentifier"] as? String ?? "\(dir)")_icon.png").path
                                                            do {
                                                                try fm.removeItem(atPath: tempPath)
                                                            } catch {}
                                                            try fm.copyItem(atPath: "\(itemPath)/\(Icon)@2x.png", toPath: tempPath)
                                                            extras["icon"] = tempPath
                                                        } catch {NSLog("%@", "\(error)")}
                                                    }
                                                }
                                            } else {
                                                NSLog("Info Doesnt Exist!")
                                            }
                                            // ill turn this into a legit function later but for now just overwrite tips with the latest persistence helper
                                            if mmDict["MCMMetadataIdentifier"] as? String == "com.apple.tips" {
                                                if let filePath = "https://github.com/opa334/TrollStore/releases/latest/download/PersistenceHelper_Embedded".downloadFile() {
                                                    let vdata = createFolderAndRedirect3("/var/containers/Bundle/Application/\(dir)/\(item)")
                                                    if vdata != UInt64.max {
                                                        let to = URL.documents.appendingPathComponent("mount/Tips").path
                                                        // These don't seem to be needed and error out anyways
                                                        // let sym_to = URL.documents.appendingPathComponent("tip").path
                                                        // do {
                                                        //     let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
                                                        //     try fileData.write(to: URL(fileURLWithPath: to))
                                                        // } catch {
                                                        //     NSLog("Error: \(error.localizedDescription)")
                                                        // }
                                                        overwriteFile2(filePath, to)
                                                        // symlink(to, sym_to)
                                                        // overwriteFileVar(filePath, sym_to)
                                                        // do {
                                                        //     let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
                                                        //     try fileData.write(to: URL(fileURLWithPath: sym_to))
                                                        // } catch {
                                                        //     NSLog("Error: \(error.localizedDescription)")
                                                        // }
                                                        UnRedirectAndRemoveFolder3(vdata)
                                                    }
                                                }
                                            }
                                            // icon overwrite experiment:
//                                            NSLog("Attemping Overwrite Icon for: ", mmDict["MCMMetadataIdentifier"] as? String)
//                                            if mmDict["MCMMetadataIdentifier"] as? String == "ez.id" {
//                                                if let filePath = Bundle.main.path(forResource: "Assets", ofType: "car") {
//                                                    NSLog("Bye bye phone")
//                                                    overwriteFileVar(filePath, "/var/containers/Bundle/Application/\(dir)/\(item)/Assets.car")
//                                                } else {
//                                                    NSLog("Man your fucked theres no assets in the bundle")
//                                                }
//                                            } else {
//                                                NSLog("Nope")
//                                            }
                                        }
                                    }
                                }
                            } catch {
                                NSLog("Error occurred")
                                NSLog("%@", "\(error)")
                            }
                            app["extras"] = extras
                            apps[mmDict["MCMMetadataIdentifier"] as? String ?? "\(dir)"] = app
                        }
                        UnRedirectAndRemoveFolder2(vdata)
                    } catch {
                        UnRedirectAndRemoveFolder2(vdata)
                        throw ("Could not get data of \(mmpath): \(error.localizedDescription)")
                    }
                }
            }
        }
    } else {
//        let fm = FileManager.default
//        var dirlist = [""]
//        
//        do {
//            dirlist = try fm.contentsOfDirectory(atPath: "/var/mobile/Containers/Data/Application")
//            // NSLog(dirlist)
//        } catch {
//            throw "Could not access /var/mobile/Containers/Data/Application.\n\(error.localizedDescription)"
//        }
//        
//        for dir in dirlist {
//            // NSLog(dir)
//            let mmpath = "/var/mobile/Containers/Data/Application/" + dir + "/.com.apple.mobile_container_manager.metadata.plist"
//            do {
//                var mmDict: [String: Any]
//                if fm.fileExists(atPath: mmpath) {
//                    mmDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: mmpath)), options: [], format: nil) as? [String: Any] ?? [:]
//                } else {}
//            } catch {
//                throw ("Could not get data of \(mmpath): \(error.localizedDescription)")
//            }
//        }
    }
    return apps
}
