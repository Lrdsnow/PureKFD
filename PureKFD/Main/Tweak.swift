import Foundation
import SwiftUI

func getDeviceInfo(appData: AppData?) -> (Int, SavedKFDData, (Int, Int, Int, Bool, String, String), Bool) {
    var exploit_method = -1
    var kfddata = SavedKFDData(puaf_pages: 3072, puaf_method: 1, kread_method: 1, kwrite_method: 1)
    var version = (0, 0, 0, false, "0", "Unknown Device")
    var lowend = false
    #if targetEnvironment(simulator)
    exploit_method = 2
    appData?.UserData.exploit_method = 2
    let systemVersion = UIDevice.current.systemVersion
    let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }
    if versionComponents.count >= 2 {
        let major = versionComponents[0]
        let sub = versionComponents[1]
        let minor = versionComponents.count >= 3 ? versionComponents[2] : 0
        version = (major, sub, minor, false, "0", "Simulator")
    }
    #else
    if !(appData?.UserData.override_exploit_method ?? false) {
        let systemVersion = UIDevice.current.systemVersion
        let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }
        if versionComponents.count >= 2 {
            let major = versionComponents[0]
            let sub = versionComponents[1]
            let minor = versionComponents.count >= 3 ? versionComponents[2] : 0
            
            // Check for beta and get model and <A12 check
            let systemAttributes = NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")
            let build_number = systemAttributes?["ProductBuildVersion"] as? String ?? "0"
            let beta = build_number.count > 6
            let gestAltCache = NSDictionary(contentsOfFile: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist")
            let cacheExtras: [String: Any] = gestAltCache?["CacheExtra"] as? [String: Any] ?? [:]
            let modelIdentifier = cacheExtras["0+nc/Udy4WNG8S+Q7a/s1A"] as? String ?? cacheExtras["h9jDsbgj7xIVeIQ8S3/X3Q"] as? String ?? "Unknown Device"
            if modelIdentifier != "Unknown Device" && modelIdentifier.contains("iPhone") {
                let gen_array = modelIdentifier.replacingOccurrences(of: "iPhone", with: "").split(separator: ",")
                if let gen = Int(gen_array[0]) {
                    if gen <= 10 {
                        lowend = true
                    }
                }
            }
            //
            
            version = (major, sub, minor, beta, build_number, modelIdentifier)
            
            if (major == 14) ||
                (major == 15 && (sub <= 6 || (sub <= 7 && minor <= 1))) ||
                (major == 16 && sub <= 1) {
                exploit_method = 1
            } else if (major == 16 && sub >= 2 && sub <= 6) && !(sub == 6 && build_number != "20G5026e") && !lowend {
                exploit_method = 0
            } else if ((try? FileManager.default.contentsOfDirectory(atPath: "/var/jb")) != nil) {
                exploit_method = 3
            } else if ((try? FileManager.default.contentsOfDirectory(atPath: "/usr/bin")) != nil) {
                exploit_method = 2
            }
            
//            print("Device Info:")
//            print(modelIdentifier)
//            print(build_number)
//            print("iOS \(major).\(sub).\(minor)")
        }
    } else {
        exploit_method = appData?.UserData.exploit_method ?? exploit_method
        kfddata = appData?.UserData.kfd ?? kfddata
    }
    appData?.UserData.exploit_method = exploit_method
    appData?.UserData.kfd = kfddata
    #endif
//    print(kfddata)
    return (exploit_method, kfddata, version, lowend)
}

func applyTweaks(appData: AppData) {
    // Get Exploit
    let exploit_method = getDeviceInfo(appData: appData).0
    let kfddata = getDeviceInfo(appData: appData).1
    
    // KFD Stuff
    if exploit_method == 0 && !appData.kopened {
        let exploit_result = do_kopen(UInt64(kfddata.puaf_pages), UInt64(kfddata.puaf_method), UInt64(kfddata.kread_method), UInt64(kfddata.kwrite_method))
        if exploit_result == 0 {
            return
        }
        fix_exploit()
    }
    
    // Jailbreak Stuff
    if exploit_method == 2 || exploit_method == 3 {
        get_root()
    }
    
    let true_exploit_method = exploit_method
    Task {
        await UIApplication.shared.alert(title: "Applying...", body: "Please wait", animated: false, withButton: false)
        var tweakErrors: [String] = []
        await asyncApplyTweaks(true_exploit_method, &tweakErrors, appData: appData)
        await UIApplication.shared.dismissAlert(animated: false)
        if appData.UserData.dev {
            if !tweakErrors.isEmpty {
                let errorList = tweakErrors.joined(separator: "\n")
                await UIApplication.shared.alert(title: "Tweak Errors", body: errorList, animated: false, withButton: true)
            }
        }
        if true_exploit_method == 0 {
            print("Closing Kernel")
            do_kclose()
        }
    }
}

func asyncApplyTweaks(_ exploit_method: Int, _ writeErrors: inout [String], appData: AppData) async {
    // Apply Packages
    for pkg in getInstalledPackages() {
        if !(pkg.disabled ?? false) {
            let pkgpath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("installed/\(pkg.bundleID)")
            let overwriteFolderPath = pkgpath.appendingPathComponent("Overwrite")
            if FileManager.default.fileExists(atPath: overwriteFolderPath.path) {
                await overwriteMisaka(sourceFolderURL: overwriteFolderPath, pkgpath: pkgpath, exploit_method: exploit_method, writeErrors: &writeErrors)
            } else {
                do {
                    try await runTweakOperations(getTweaksData(pkgpath.appendingPathComponent("tweak.json")), pkgpath: pkgpath, appData: appData)
                } catch {
                    writeErrors.append("\(pkg.bundleID): \(error)")
                }
            }
        }
    }
    print("All Done")
}

func overwriteMisaka(sourceFolderURL: URL, pkgpath: URL, exploit_method: Int, writeErrors: inout [String]) async {
    let fileManager = FileManager.default

    func processItem(at itemURL: URL, relativeTo baseURL: URL) async {
        var isDirectory: ObjCBool = false

        if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory) {
            _ = itemURL.lastPathComponent

            if isDirectory.boolValue {
                do {
                    let subContents = try fileManager.contentsOfDirectory(at: itemURL, includingPropertiesForKeys: nil, options: [])
                    for subItemURL in subContents {
                        await processItem(at: subItemURL, relativeTo: baseURL)
                    }
                } catch {
                    writeErrors.append("\(error)")
                }
            } else {
                let relativePath = replaceBeforeAndSubstring(in: itemURL.path, targetSubstring: "/Overwrite", with: "").misakaOperations(pkgpath: pkgpath, exploit_method: exploit_method)
                do {
                    if !URL(fileURLWithPath: relativePath).lastPathComponent.hasPrefix("?pure_binary.") {
                        if exploit_method == 0 { // KFD
                            _ = try await overwriteWithFileImpl(replacementURL: itemURL, pathToTargetFile: relativePath)
                        } else if exploit_method == 1 { // MDC
                            try await MDC.overwriteFile(at: relativePath, with: readFileAsData(atURL: itemURL)!)
                        } else if exploit_method == 3 { // Rootless
                            try await readFileAsData(atURL: itemURL)!.write(to: URL(fileURLWithPath: "/var/jb/"+relativePath))
                        } else { // Rootful
                            try await readFileAsData(atURL: itemURL)!.write(to: URL(fileURLWithPath: relativePath))
                        }
                    } else {
                        print("\nPURE BINARY INIT\n")
                        do {
                            let path = relativePath.replacingOccurrences(of: "?pure_binary.", with: "")
                            // Read the JSON data containing replacements
                            let jsonData = try Data(contentsOf: itemURL)
                            if let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                                
                                var save: [String: Any] = [:]
                                if let savepath = FileManager.default.contents(atPath: pkgpath.appendingPathComponent("save.json").path),
                                   let savedict = try? JSONSerialization.jsonObject(with: savepath, options: []) {
                                    save = savedict as? [String: Any] ?? [:]
                                }
                                
                                // Open the binary file for reading and writing
                                var binaryData = try Data(contentsOf: URL(fileURLWithPath:path))
                                
                                // Apply the replacements to the binary data
                                for (offset, replacement) in jsonDictionary["Overwrite"] as? [String:String] ?? [:] {
                                    print("OFFSET", offset)
                                    print("REPLACEMENT", (save[replacement] as? String)?.replacingOccurrences(of: "#", with: "") ?? "N/A")
                                    if let offset = Int(offset), let replacementData = Data(hex: (save[replacement] as? String)?.replacingOccurrences(of: "#", with: "") as? String ?? "") {
                                        binaryData.replaceSubrange(offset..<offset + replacementData.count, with: replacementData)
                                    }
                                }
                                
                                // Write the modified binary data back to the file
                                try binaryData.write(to: URL.documents.appendingPathComponent("temp"))
                                if exploit_method == 0 { // KFD
                                    _ = try await overwriteWithFileImpl(replacementURL: URL.documents.appendingPathComponent("temp"), pathToTargetFile: path)
                                } else if exploit_method == 1 { // MDC
                                    try await MDC.overwriteFile(at: path, with: readFileAsData(atURL: URL.documents.appendingPathComponent("temp"))!)
                                } else if exploit_method == 3 { // Rootless
                                    try await readFileAsData(atURL: URL.documents.appendingPathComponent("temp"))!.write(to: URL(fileURLWithPath: "/var/jb/"+path))
                                } else { // Rootful
                                    try await readFileAsData(atURL: URL.documents.appendingPathComponent("temp"))!.write(to: URL(fileURLWithPath: path))
                                }
                                do{try fileManager.removeItem(at: URL.documents.appendingPathComponent("temp"))}catch{}
                            }
                        } catch {
                            print(error)
                        }
                        print("\nPURE BINARY FINISHED\n")
                    }
                } catch {
                    if relativePath.hasPrefix("/var/mobile/Containers/Data/Application") {
                        if exploit_method == 0 {
                            _ = FileManager.default
                            let path = URL.documents.appendingPathComponent("mounted")
                            _ = URL(fileURLWithPath: relativePath).deletingLastPathComponent().path
                            _ = path.appendingPathComponent(relativePath.components(separatedBy: "/").last ?? "")
                            
                            //let vdata = createFolderAndRedirect2(folderpath)
                            
                            do {
                                if sandbox_escape_can_i_access_file(strdup(relativePath), 0) {
                                    funVnodeOverwriteFileUnlimitSize(strdup(relativePath), strdup(itemURL.path))
                                } else {
                                    throw "Permission Denied"
                                }
                            } catch {
                                print(error)
                                writeErrors.append("\(error)")
                            }
                            
                            //UnRedirectAndRemoveFolder2(vdata)
                        } else if exploit_method == 1 {
                            do {
                                try FileManager.default.createDirectory(at: URL(fileURLWithPath: relativePath).deletingLastPathComponent(), withIntermediateDirectories: true)
                                do {
                                    try FileManager.default.removeItem(atPath: relativePath)
                                } catch {}
                                try await readFileAsData(atURL: itemURL)!.write(to: URL(fileURLWithPath: relativePath))
                            } catch {
                                writeErrors.append("\(error)")
                            }
                        }
                    } else if relativePath.hasPrefix("/var/mobile/Documents") {
                        print("(rdir) relativepath",relativePath)
                        if exploit_method == 0 && ((try? (FileManager.default.contentsOfDirectory(atPath: "/var"))) == nil) {
                            let fileManager = FileManager.default
                            let pathfromdocs = URL(fileURLWithPath: relativePath).deletingLastPathComponent().path.replacingOccurrences(of: "/var/mobile/Documents/", with: "")
                            let filename = URL(fileURLWithPath: relativePath).lastPathComponent
                            
                            let partsofpath = pathfromdocs.components(separatedBy: "/")
                            var rdirparts = ""
                            
                            let doc_vdata = createFolderAndRedirect2("/var/mobile/Documents/")
                            do {
                                if let part = partsofpath.first {
                                    try fileManager.removeItem(atPath: "/var/mobile/Documents/"+part)
                                }
                            } catch {}
                            UnRedirectAndRemoveFolder2(doc_vdata)
                            
                            for part in partsofpath {
                                let vdata = createFolderAndRedirect2("/var/mobile/Documents/"+rdirparts)
                                rdirparts += part
                                if vdata != UInt64.max {
                                    do {
                                        try fileManager.createDirectory(at: URL.documents.appendingPathComponent("mounted/\(part)"), withIntermediateDirectories: true)
                                    } catch {print(error)}
                                    UnRedirectAndRemoveFolder2(vdata)
                                } else {
                                    print("(rdir) Failed to redirect")
                                }
                            }
                            
                            print("(rdir) writing to", URL.documents.appendingPathComponent(filename).path, "(\(relativePath))")
                            let vdata = createFolderAndRedirect2(URL(fileURLWithPath: relativePath).deletingLastPathComponent().path)
                            if vdata != UInt64.max {
                                do {
                                    try await readFileAsData(atURL: itemURL)!.write(to: URL.documents.appendingPathComponent("mounted/\(filename)"))
                                    print("(rdir) successfully wrote to", URL.documents.appendingPathComponent("mounted/\(filename)").path, "(\(relativePath))")
                                } catch {print(error)}
                                UnRedirectAndRemoveFolder2(vdata)
                            } else {
                                print("(rdir) Failed to redirect")
                            }
                            
//                            do {
//                                do {
//                                    try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
//                                } catch {
//                                    print(error)
//                                    writeErrors.append("\(error)")
//                                }
//                                print(filepath.path)
//                                try await readFileAsData(atURL: itemURL)!.write(to: filepath)
//                            } catch {
//                                print(error)
//                                writeErrors.append("\(error)")
//                            }
                            
                        } else {
                            do {
                                try FileManager.default.createDirectory(at: URL(fileURLWithPath: relativePath).deletingLastPathComponent(), withIntermediateDirectories: true)
                                do {
                                    try FileManager.default.removeItem(atPath: relativePath)
                                } catch {}
                                try await readFileAsData(atURL: itemURL)!.write(to: URL(fileURLWithPath: relativePath))
                            } catch {
                                writeErrors.append("\(error)")
                            }
                        }
                    }
                }
            }
        } else {
            writeErrors.append("\(itemURL) does not exist.")
        }
    }

    await processItem(at: sourceFolderURL, relativeTo: sourceFolderURL)
}

func readFileAsData(atURL url: URL) async throws -> Data? {
    do {
        let fileData = try Data(contentsOf: url)
        return fileData
    } catch {
        print("Error reading file: \(error)")
        throw error
    }
}

func replaceBeforeAndSubstring(in input: String, targetSubstring: String, with replacement: String) -> String {
    if let range = input.range(of: targetSubstring) {
        let contentAfter = input[range.upperBound...]
        
        return replacement + contentAfter
    }
    return input
}

func overwriteWithFileImpl(replacementURL: URL, pathToTargetFile: String) async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
        Task {
            let cPathtoTargetFile = pathToTargetFile.withCString { ptr in
                return strdup(ptr)
            }

            _ = UnsafeMutablePointer<Int8>(mutating: cPathtoTargetFile)

            let cFileURL = replacementURL.path.withCString { ptr in
                return strdup(ptr)
            }
            let mutablecFileURL = UnsafeMutablePointer<Int8>(mutating: cFileURL)

            DispatchQueue.global().async {
                let result = funVnodeOverwrite2(cPathtoTargetFile, mutablecFileURL)

                if result == 0 {
                    continuation.resume(returning: "Success")
                } else {
                    continuation.resume(throwing: "Failed To Overwrite File")
                }
            }
        }
    }
}

// Picasso/PureKFD

func getTweaksData(_ fileURL: URL) throws -> [String: Any] {
    do {
        let jsonData = try Data(contentsOf: fileURL)
        if let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            return jsonDictionary
        }
    } catch {
        print("Error loading JSON data: \(error)")
        throw error
    }
    return [:]
}

func runTweakOperations(_ tweakOperations: [String: Any], pkgpath: URL, appData: AppData) async {
    let operations = tweakOperations["operations"] as? [[String: Any]]
    
    var save: [String: Any] = [:]
    
    if let savepath = FileManager.default.contents(atPath: pkgpath.appendingPathComponent("save.json").path),
       let savedict = try? JSONSerialization.jsonObject(with: savepath, options: []) {
        save = savedict as? [String: Any] ?? [:]
    }

    for operation in operations ?? [] {
        let operationType = operation["type"] as? String

        switch operationType {
        case "resset":
            let hight = Int(save["hight"] as? String ?? "2796") ?? 2796
            let width = Int(save["width"] as? String ?? "1290") ?? 1290
            if getDeviceInfo(appData: appData).0 == 0 {
                ResSet16(hight, width)
            } else if getDeviceInfo(appData: appData).0 == 1 {
                MDC.setResolution(height: hight, width: width)
            }
        case "panic":
            do_kopen(0, 0, 0, 0)
        case "remove3app":
            if getDeviceInfo(appData: appData).0 == 1 {
                //patch_installd()
            }
        case "replacing":
            let frompath = operation["replacementFileName"] as? String ?? ""
            var frompathurl: URL
            if operation["replacementFileBundled"] as? Bool ?? false {
                frompathurl = pkgpath.appendingPathComponent(frompath)
            } else {
                frompathurl = URL(string: frompath) ?? URL(string: "file:///")!
            }
            do {
                if getDeviceInfo(appData: appData).0 == 0 {
                    _ = try await overwriteWithFileImpl(replacementURL: frompathurl, pathToTargetFile: operation["originPath"] as? String ?? "")
                } else if getDeviceInfo(appData: appData).0 == 1 {
                    try MDC.overwriteFile(at: operation["originPath"] as? String ?? "", with: Data(contentsOf: frompathurl))
                }
            } catch {}
        case "removing":
            let originPath = operation["originPath"] as? String ?? ""
            if getDeviceInfo(appData: appData).0 == 0 {
                funVnodeHide(strdup(originPath))
            } else {
                do {
                    try MDC.overwriteFile(at: originPath, with: Data())
                } catch {}
            }
        case "subtype":
            let subtype = save["subtype"] as? Int ?? 2532//2796
            if getDeviceInfo(appData: appData).0 == 0 {
                DynamicKFD(Int32(subtype))
            }
        case "springboardColor":
            let springboardElement = SpringboardColorManager.convertStringToSpringboardType(operation["springboardElement"] as? String ?? "")!
            let colorVariableName: String = operation["colorVariableName"] as? String ?? "color"
            let blurVariableName: String = operation["blurVariableName"] as? String ?? "blur"
            if let color = UIColor(hex: save[colorVariableName] as? String ?? "") {
                let blur = save[blurVariableName] as? Int ?? Int(save[blurVariableName] as? String ?? "1") ?? 1
                do {
                    try SpringboardColorManager.createColor(forType: springboardElement, color: CIColor(color: color), blur: blur, asTemp: false)
                    for _ in 1...5 {
                        await SpringboardColorManager.applyColor(forType: springboardElement, exploit_method: getDeviceInfo(appData: appData).0)
                    }
                } catch {}
            }
        default:
            print("Unsupported Tweak:", operationType ?? "")
        }
    }
}

extension String {
    func misakaOperations(pkgpath: URL, exploit_method: Int) -> String {
        var save: [String: Any] = [:]
        if let savepath = FileManager.default.contents(atPath: pkgpath.appendingPathComponent("save.json").path),
           let savedict = try? JSONSerialization.jsonObject(with: savepath, options: []) {
            save = savedict as? [String: Any] ?? [:]
        }
        var path = self
            .replacingOccurrences(of: "%Optional%", with: "")
            //.replacingOccurrences(of: "%Misaka_Binary%", with: "") // This is prob unsafe
            .replacingOccurrences(of: "%Misaka_Resize%", with: "")
            .replacingOccurrences(of: "%Misaka_Path{'SpringLang'}%", with: Locale.current.languageCode ?? "")
            .replacingOccurrences(of: "%Misaka_Path{'DeviceType'}%", with: (UIDevice.current.userInterfaceIdiom == .phone) ? "iphone" : "ipad")
        for item in path.components(separatedBy: "/") {
            if item.contains("Misaka_Segment") {
                let fileName = parseMisakaSegment(from: item)[0]
                let variableName = parseMisakaSegment(from: item)[1]
                let variableValue = parseMisakaSegment(from: item)[2]
                print(fileName, variableName, variableValue)
                if variableName == "iOSver" {
                    let deviceInfo = getDeviceInfo(appData: nil).2
                    if variableValue == "\(deviceInfo.0)" {
                        path = path.replacingOccurrences(of: item, with: fileName)
                    }
                }
                if ("\(save[variableName] as? Int ?? 0)" == "1") && ("\(variableValue)" == "YES") || ("\(save[variableName] as? Int ?? 1)" == "0") && ("\(variableValue)" == "NO") || ("\(save[variableName] as? String ?? "\(UUID())")" == "\(variableValue)") {
                    path = path.replacingOccurrences(of: item, with: fileName)
                }
                if "\(save[variableName] ?? 1)" == "\(variableValue)" {
                    path = path.replacingOccurrences(of: item, with: fileName)
                }
                path = path.replacingOccurrences(of: "%Misaka_Binary%", with: "?pure_binary.")
            }
            if item.contains("Misaka_AppUUID") {
                let bundleid = misakaOperationValues(from: item)[0]
                if misakaOperationValues(from: item)[1] == "Data" {
                    do {
                        path = try path.replacingOccurrences(of: "/var/mobile/Containers/Data/Application/"+item, with: getDataDir(bundleID: bundleid, exploit_method: exploit_method).path)
                    } catch {print("failed")}
                }
            }
        }
        return path
    }
}

func getBundleID(path: String, uuid: String, exploit_method: Int) throws -> String {
    let fm = FileManager.default
    var returnedurl = URL(string: "none")
    let mounted = URL.documents.appendingPathComponent("mounted").path
    var savedAppDataPaths = UserDefaults.standard.dictionary(forKey: "appdatapaths") as? [String: String] ?? [:]
    
    if fm.fileExists(atPath: path+"/"+uuid+"/info.json") {
        do {
            let info = try JSONSerialization.jsonObject(with: try Data(contentsOf: URL(fileURLWithPath: path+"/"+uuid+"/info.json")), options: []) as? [String: Any]
            return "\(info?["name"] ?? "Unknown Tweak") (Tweak)"
        } catch {}
    }
    
    for savedBundleID in savedAppDataPaths {
        let datapath = savedBundleID.value
        if datapath.components(separatedBy: "/").last == uuid {
            return savedBundleID.key
        }
    }
    
    if exploit_method == 0 && ((try? (FileManager.default.contentsOfDirectory(atPath: "/var"))) == nil) {
        let mmpath = mounted + "/.com.apple.mobile_container_manager.metadata.plist"
        print(mmpath)
        let vdata = createFolderAndRedirectTemp(path+"/"+uuid)
        do {
            if vdata != UInt64.max {
                var mmDict: [String: Any]
                if fm.fileExists(atPath: mmpath) {
                    mmDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: mmpath)), options: [], format: nil) as? [String: Any] ?? [:]
                    print(mmDict["MCMMetadataIdentifier"] ?? "")
                    if let bundleID = mmDict["MCMMetadataIdentifier"] as? String {
                        returnedurl = URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/").appendingPathComponent(uuid)
                        savedAppDataPaths[bundleID] = returnedurl?.path
                        UserDefaults.standard.set(savedAppDataPaths, forKey: "appdatapaths")
                        UnRedirectAndRemoveFolderTemp(vdata)
                        return bundleID
                    }
                }
                UnRedirectAndRemoveFolderTemp(vdata)
            }
        } catch {
            if vdata != UInt64.max {
                UnRedirectAndRemoveFolderTemp(vdata)
            }
            throw ("Could not get data of \(mmpath): \(error.localizedDescription)")
        }
    } else {
        let fm = FileManager.default
        let mmpath = path + "/" + uuid + "/.com.apple.mobile_container_manager.metadata.plist"
        do {
            var mmDict: [String: Any]
            if fm.fileExists(atPath: mmpath) {
                mmDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: mmpath)), options: [], format: nil) as? [String: Any] ?? [:]
                print(mmDict["MCMMetadataIdentifier"] ?? "")
                if let bundleID = mmDict["MCMMetadataIdentifier"] as? String {
                    returnedurl = URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/").appendingPathComponent(uuid)
                    savedAppDataPaths[bundleID] = returnedurl?.path
                    UserDefaults.standard.set(savedAppDataPaths, forKey: "appdatapaths")
                    return bundleID
                }
            } else {}
        } catch {
            throw ("Could not get data of \(mmpath): \(error.localizedDescription)")
        }
    }
    
    if returnedurl == URL(string: "none") {
        throw "Error getting bundleID for app \(uuid)"
    }
    return ""
}

func getDataDir(bundleID: String, exploit_method: Int) throws -> URL {
    let fm = FileManager.default
    var returnedurl = URL(string: "none")
    let mounted = URL.documents.appendingPathComponent("mounted").path
    var dirlist = [""]
    var savedAppDataPaths = UserDefaults.standard.dictionary(forKey: "appdatapaths") as? [String: String] ?? [:]
    
    if exploit_method == 0 && ((try? (FileManager.default.contentsOfDirectory(atPath: "/var"))) == nil) {
        if let path = savedAppDataPaths[bundleID] {
            returnedurl = URL(fileURLWithPath: path)
            return URL(fileURLWithPath: path)
        } else {
            var vdata = createFolderAndRedirect2("/var/mobile/Containers/Data/Application")
            
            do {
                dirlist = try fm.contentsOfDirectory(atPath: URL.documents.appendingPathComponent("mounted").path)
                // print(dirlist)
            } catch {
                throw "Could not access /var/mobile/Containers/Data/Application.\n\(error.localizedDescription)"
            }
            
            UnRedirectAndRemoveFolder2(vdata)
            
            for dir in dirlist {
                let mmpath = mounted + "/.com.apple.mobile_container_manager.metadata.plist"
                vdata = createFolderAndRedirect2("/var/mobile/Containers/Data/Application/"+dir)
                do {
                    var mmDict: [String: Any]
                    if fm.fileExists(atPath: mmpath) {
                        mmDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: mmpath)), options: [], format: nil) as? [String: Any] ?? [:]
                        print(mmDict["MCMMetadataIdentifier"] ?? "")
                        if mmDict["MCMMetadataIdentifier"] as! String == bundleID {
                            returnedurl = URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/").appendingPathComponent(dir)
                            savedAppDataPaths[bundleID] = returnedurl?.path
                            UserDefaults.standard.set(savedAppDataPaths, forKey: "appdatapaths")
                            UnRedirectAndRemoveFolder2(vdata)
                            return URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/").appendingPathComponent(dir)
                        }
                    }
                    UnRedirectAndRemoveFolder2(vdata)
                } catch {
                    UnRedirectAndRemoveFolder2(vdata)
                    throw ("Could not get data of \(mmpath): \(error.localizedDescription)")
                }
            }
        }
    } else {
        let fm = FileManager.default
        var dirlist = [""]
        
        do {
            dirlist = try fm.contentsOfDirectory(atPath: "/var/mobile/Containers/Data/Application")
            // print(dirlist)
        } catch {
            throw "Could not access /var/mobile/Containers/Data/Application.\n\(error.localizedDescription)"
        }
        
        for dir in dirlist {
            // print(dir)
            let mmpath = "/var/mobile/Containers/Data/Application/" + dir + "/.com.apple.mobile_container_manager.metadata.plist"
            // print(mmpath)
            do {
                var mmDict: [String: Any]
                if fm.fileExists(atPath: mmpath) {
                    mmDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: mmpath)), options: [], format: nil) as? [String: Any] ?? [:]
                    // print(mmDict as Any)
                    if mmDict["MCMMetadataIdentifier"] as! String == bundleID {
                        returnedurl = URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/").appendingPathComponent(dir)
                        savedAppDataPaths[bundleID] = returnedurl?.path
                        UserDefaults.standard.set(savedAppDataPaths, forKey: "appdatapaths")
                        return URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/").appendingPathComponent(dir)
                    }
                } else {}
            } catch {
                throw ("Could not get data of \(mmpath): \(error.localizedDescription)")
            }
        }
    }
    
    if returnedurl != URL(string: "none") {
        return returnedurl!
    } else {
        throw "Error getting data directory for app \(bundleID)"
    }
}

// Funni Misaka Parse stuff written by chatgpt

func misakaOperationValues(from inputString: String) -> [String] {
    var extractedValues = [String]()

    do {
        let regex = try NSRegularExpression(pattern: "'(.*?)'", options: [])
        let nsString = inputString as NSString
        let matches = regex.matches(in: inputString, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if let range = Range(match.range(at: 1), in: inputString) {
                let extractedValue = String(inputString[range])
                extractedValues.append(extractedValue)
            }
        }
    } catch {
        print("Error: \(error)")
    }

    return extractedValues
}

func parseMisakaSegment(from inputString: String) -> [String] {
    var extractedValues = [String]()

    do {
        let regex = try NSRegularExpression(pattern: "'(.*?)'", options: [])
        let nsString = inputString as NSString
        let matches = regex.matches(in: inputString, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if let range = Range(match.range(at: 1), in: inputString) {
                let extractedValue = String(inputString[range])
                extractedValues.append(extractedValue)
            }
        }
    } catch {
        print("Error: \(error)")
    }

    return extractedValues
}

extension Data {
    init?(hex: String) {
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
        let length = cleanHex.count / 2
        var data = Data(capacity: length)
        
        for i in 0..<length {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: i * 2)
            let end = cleanHex.index(start, offsetBy: 2)
            if let byte = UInt8(cleanHex[start..<end], radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
        }
        
        self = data
    }
}
