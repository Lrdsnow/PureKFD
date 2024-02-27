//
//  Tweak.swift
//  PureKFD
//
//  Created by Lrdsnow on 12/22/23.
//

import Foundation
import SwiftUI
import SwiftKFD
import SwiftKFD_objc

func smart_kopen(appData: AppData) -> Int {
    // Get Exploit
    let exploit_method = getDeviceInfo(appData: appData).0
    let kfddata = getDeviceInfo(appData: appData).1
    
    // KFD Stuff
    if exploit_method == 0 && !appData.kopened {
        let exploit_result = do_kopen(UInt64(kfddata.puaf_pages), UInt64(kfddata.puaf_method), UInt64(kfddata.kread_method), UInt64(kfddata.kwrite_method), appData.UserData.kfd.use_static_headroom ? -1 : size_t(kfddata.static_headroom))
        if exploit_result == 0 {
            return -1
        }
        fix_exploit()
        appData.kopened = true
    }
    
    return exploit_method
}

struct DeviceInfo {
    var major: Int = 0
    var sub: Int = 0
    var minor: Int = 0
    var beta: Bool = false
    var build_number: String = "0"
    var modelIdentifier: String = "Unknown Device"
    var lowend: Bool = false
}

var tested_jb = false
var jailbroken = false

func getDeviceInfo(appData: AppData?, _ ignoreOverride: Bool = false) -> (Int, SavedKFDData, Bool, DeviceInfo) {
    var exploit_method = -1
    var kfddata = SavedKFDData(puaf_pages: 3072, puaf_method: 2, kread_method: 1, kwrite_method: 1)
    var deviceInfo = DeviceInfo()
    var lowend = false
    var ts = false
#if targetEnvironment(simulator)
    if !(appData?.UserData.override_exploit_method ?? false) || ignoreOverride {
        exploit_method = 2
        appData?.UserData.exploit_method = 2
    } else {
        exploit_method = appData?.UserData.exploit_method ?? exploit_method
        kfddata = appData?.UserData.kfd ?? kfddata
    }
    let systemVersion = UIDevice.current.systemVersion
    let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }
    if versionComponents.count >= 2 {
        let major = versionComponents[0]
        let sub = versionComponents[1]
        let minor = versionComponents.count >= 3 ? versionComponents[2] : 0
        deviceInfo = DeviceInfo(major: major,
                                sub: sub,
                                minor: minor,
                                beta: false,
                                build_number: "0",
                                modelIdentifier: "Simulator",
                                lowend: false)
    }
#else
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
        
        deviceInfo = DeviceInfo(major: major,
                                sub: sub,
                                minor: minor,
                                beta: beta,
                                build_number: build_number,
                                modelIdentifier: modelIdentifier,
                                lowend: lowend)
        
        if !(appData?.UserData.override_exploit_method ?? false) || ignoreOverride {
            if !tested_jb {
                if jbclient_process_checkin(nil, nil, nil) != -1 {
                    jailbroken = true
                }
                tested_jb = true
            }
            if jailbroken {
                exploit_method = 3
            } else {
                if (major == 14) ||
                    (major == 15 && (sub <= 6 || (sub <= 7 && minor <= 1))) ||
                    (major == 16 && sub <= 1) {
                    exploit_method = 1
                } else if (major == 16 && sub >= 2) && !lowend {
                    exploit_method = 0
                } else if ((try? FileManager.default.contentsOfDirectory(atPath: "/usr/bin")) != nil) {
                    exploit_method = 2
                }
            }
        } else {
            exploit_method = appData?.UserData.exploit_method ?? exploit_method
            kfddata = appData?.UserData.kfd ?? kfddata
        }
        
        //            log("Device Info:")
        //            log(modelIdentifier)
        //            log(build_number)
        //            log("iOS \(major).\(sub).\(minor)")
    }
    appData?.UserData.exploit_method = exploit_method
    appData?.UserData.kfd = kfddata
    ts = hasEntitlement("com.apple.private.security.no-sandbox" as CFString)
#endif
    //    log(kfddata)
    return (exploit_method, kfddata, ts, deviceInfo)
}

func getDirFiles(_ directoryPath: String) -> [String] {
    var filesArray: [String] = []
    let fileManager = FileManager.default
    if let enumerator = fileManager.enumerator(atPath: directoryPath) {
        for case let file as String in enumerator {
            let fullPath = (directoryPath as NSString).appendingPathComponent(file)
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
                if !isDirectory.boolValue {
                    filesArray.append(fullPath)
                }
            }
        }
    }

    return filesArray
}

enum TweakType {
    case json
    case overwrite
    case unknown
}

func getTweakType(_ pkgpath: URL) -> TweakType {
    let file = FileManager.default
    if file.fileExists(atPath: pkgpath.appendingPathComponent("Overwrite").path) {
        return .overwrite
    } else if file.fileExists(atPath: pkgpath.appendingPathComponent("tweak.json").path) {
        return .json
    } else {
        return .unknown
    }
}

func updateApplyStatus(_ appData: AppData, _ pkgid: String, _ message: String, _ percentage: Double) {
    appData.applyStatus[pkgid] = ApplyStatus(message: message, percentage: percentage)
}

func applyTweaks(appData: AppData) {
    try? Data().write(to: URL.documents.appendingPathComponent("apply.lock"))
    let exploit_method = smart_kopen(appData: appData)
    for pkg in getInstalledPackages() {
        if !(pkg.disabled ?? false) {
            do {
                updateApplyStatus(appData, pkg.bundleID, "Applying...", 0)
                let pkgpath = URL.documents.appendingPathComponent("installed/\(pkg.bundleID)")
                let tweakType = getTweakType(pkgpath)
                if tweakType == .overwrite {
                    try applyOverwriteTweak(pkg, exploit_method, appData)
                } else if tweakType == .json {
                    try applyJSONTweak(pkg, appData)
                } else {
                    throw "Unknown tweak type!"
                }
            } catch {
                updateApplyStatus(appData, pkg.bundleID, "Error: \(error.localizedDescription)", 100)
            }
        }
    }
    if exploit_method == 0 {
        do_kclose()
    }
    try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("apply.lock"))
}

func processBinary(_ filePath: String, _ targetPath: String, _ pkgpath: URL) -> String {
    do {
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        if let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            var save: [String: Any] = [:]
            if let savepath = FileManager.default.contents(atPath: pkgpath.appendingPathComponent("save.json").path),
               let savedict = try? JSONSerialization.jsonObject(with: savepath, options: []) {
                save = savedict as? [String: Any] ?? [:]
            }
            var binaryData = try Data(contentsOf: URL(fileURLWithPath:targetPath))
            for (offset, replacement) in jsonDictionary["Overwrite"] as? [String:String] ?? [:] {
                log("OFFSET", offset)
                log("REPLACEMENT", (save[replacement] as? String)?.replacingOccurrences(of: "#", with: "") ?? "N/A")
                if let offset = Int(offset), let replacementData = Data(hex: (save[replacement] as? String)?.replacingOccurrences(of: "#", with: "") as? String ?? "") {
                    binaryData.replaceSubrange(offset..<offset + replacementData.count, with: replacementData)
                }
            }
            let tempfile = URL.documents.appendingPathComponent("temp/bin-\(UUID())")
            try binaryData.write(to: tempfile)
            return tempfile.path
        }
    } catch {
        log("%@", "\(error)")
    }
    return ""
}

func verifyFile(_ fileURL1: URL, _ fileURL2: URL) -> Bool {
    do {
        let data1 = try Data(contentsOf: fileURL1)
        let data2 = try Data(contentsOf: fileURL2)
        return data1 == data2
    } catch {
        return false
    }
}

func applyOverwriteTweak(_ pkg: Package, _ exploit_method: Int, _ appData: AppData, _ Try: Int = 0) throws {
    let pkgpath = URL.documents.appendingPathComponent("installed/\(pkg.bundleID)")
    let files = getDirFiles(pkgpath.appendingPathComponent("Overwrite").path)
    var targets: [String:String] = [:]
    var sources: [String:String] = [:]
    var failed_files: [String] = []
    var percentage: Double = 0.0
    for file in files {
        var source = file
        var target = file
        if let range = target.range(of: "/Overwrite") {
            target = String(target[range.upperBound...]).legacyencryptedOperations(pkgpath: pkgpath, exploit_method: 2)
        }
        if URL(fileURLWithPath: target).lastPathComponent.hasPrefix("?pure_binary.") {
            source = processBinary(source, target, pkgpath)
            target = target.replacingOccurrences(of: "?pure_binary.", with: "")
        }
        let sourceURL = URL(fileURLWithPath: source)
        percentage += 90.0 / Double(files.count)
        targets[file] = target
        sources[file] = source
        do {
            if !((target.contains("/var") && hasEntitlement("com.apple.app-sandbox.read-write" as CFString)) || exploit_method == 2) {
                if (exploit_method == 0 || exploit_method == 3) {
                    try overwriteWithFileImpl(replacementURL: sourceURL, pathToTargetFile: target)
                } else if exploit_method == 1 {
                    try MDC.overwriteFile(at: target, with: readFileAsData(atURL: sourceURL)!)
                }
            } else {
                try? FileManager.default.createDirectory(at: URL(fileURLWithPath: target).deletingLastPathComponent(), withIntermediateDirectories: true)
                try readFileAsData(atURL: sourceURL)!.write(to: URL(fileURLWithPath: target))
            }
            updateApplyStatus(appData, pkg.bundleID, "Overwrote \(target)!\(failed_files.count > 0 ? " (\(failed_files.count) failures)" : "")", percentage)
        } catch {
            log("Error writing to file \(target): \(error.localizedDescription)")
            failed_files.append(file)
            updateApplyStatus(appData, pkg.bundleID, "Failed to overwrite \(target)!!!\(failed_files.count > 0 ? " (\(failed_files.count) failures)" : "")", percentage)
        }
    }
    if appData.UserData.verifyApply {
        for file in files {
            percentage += 10.0 / Double(files.count)
            if !(failed_files.contains(file)) {
                let target = URL(fileURLWithPath:targets[file] ?? "")
                let source = URL(fileURLWithPath:sources[file] ?? "")
                updateApplyStatus(appData, pkg.bundleID, "Verifying \(target.path)...", percentage)
                if verifyFile(source, target) {
                    updateApplyStatus(appData, pkg.bundleID, "\(target.path) is all good!", percentage)
                } else {
                    if Try <= 5 {
                        try? applyOverwriteTweak(pkg, exploit_method, appData, Try+1)
                    } else {
                        throw "Verification Failed!"
                    }
                }
            }
        }
    }
    if failed_files.count == files.count {
        throw "All files failed to write!"
    } else {
        updateApplyStatus(appData, pkg.bundleID, "Applied Tweak!\(failed_files.count > 0 ? " (with \(failed_files.count) failures)" : "")", 100)
    }
}

func applyJSONTweak(_ pkg: Package, _ appData: AppData) throws {
    let pkgpath = URL.documents.appendingPathComponent("installed/\(pkg.bundleID)")
    let tweakOperations = try getTweaksData(pkgpath.appendingPathComponent("tweak.json"))
    let operations = tweakOperations["operations"] as? [[String: Any]]
    var failed_operations: [String] = []
    var percentage: Double = 0
    
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
                updateApplyStatus(appData, pkg.bundleID, "Set Resolution! (KFD)", percentage)
            } else if getDeviceInfo(appData: appData).0 == 1 {
                MDC.setResolution(height: hight, width: width)
                updateApplyStatus(appData, pkg.bundleID, "Set Resolution! (MDC)", percentage)
            } else {
                failed_operations.append(operationType ?? "invalid operation")
                updateApplyStatus(appData, pkg.bundleID, "Resolution Setter Unsupported!", percentage)
            }
        case "panic":
            do_kopen(0, 0, 0, 0, 0)
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
                    try overwriteWithFileImpl(replacementURL: frompathurl, pathToTargetFile: operation["originPath"] as? String ?? "")
                    updateApplyStatus(appData, pkg.bundleID, "Replaced file \(operation["originPath"] as? String ?? "")!", percentage)
                } else if getDeviceInfo(appData: appData).0 == 1 {
                    try MDC.overwriteFile(at: operation["originPath"] as? String ?? "", with: Data(contentsOf: frompathurl))
                    updateApplyStatus(appData, pkg.bundleID, "Replaced file \(operation["originPath"] as? String ?? "")!", percentage)
                }
            } catch {
                failed_operations.append(operationType ?? "invalid operation")
                updateApplyStatus(appData, pkg.bundleID, "Failed to replace \(operation["originPath"] as? String ?? "")!", percentage)
            }
        case "removing":
            let originPath = operation["originPath"] as? String ?? ""
            if getDeviceInfo(appData: appData).0 == 0 {
                funVnodeHide(strdup(originPath))
                updateApplyStatus(appData, pkg.bundleID, "Hid file \(originPath)!", percentage)
            } else {
                do {
                    try MDC.overwriteFile(at: originPath, with: Data())
                    updateApplyStatus(appData, pkg.bundleID, "Erased file \(originPath)!", percentage)
                } catch {
                    failed_operations.append(operationType ?? "invalid operation")
                    updateApplyStatus(appData, pkg.bundleID, "Failed to erase file \(originPath)!", percentage)
                }
            }
        case "subtype":
            let subtype = save["subtype"] as? Int ?? 2532//2796
            if getDeviceInfo(appData: appData).0 == 0 {
                DynamicKFD(Int32(subtype))
                updateApplyStatus(appData, pkg.bundleID, "Set subtype!", percentage)
            } else {
                failed_operations.append(operationType ?? "invalid operation")
                updateApplyStatus(appData, pkg.bundleID, "Subtype operation not supported!", percentage)
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
                        SpringboardColorManager.applyColor(forType: springboardElement, exploit_method: getDeviceInfo(appData: appData).0)
                    }
                    updateApplyStatus(appData, pkg.bundleID, "Applied Colors for \(springboardElement)!", percentage)
                } catch {
                    failed_operations.append(operationType ?? "invalid operation")
                    updateApplyStatus(appData, pkg.bundleID, "Failed to apply colors!", percentage)
                }
            }
        default:
            failed_operations.append(operationType ?? "invalid operation")
            log("Unsupported Tweak: \(operationType ?? "")")
            updateApplyStatus(appData, pkg.bundleID, "Unsupported Tweak: \(operationType ?? "")", percentage)
        }
    }
    updateApplyStatus(appData, pkg.bundleID, "Applied Tweak!\(failed_operations.count > 0 ? " (with \(failed_operations.count) failures)" : "")", 100)
}

func readFileAsData(atURL url: URL) throws -> Data? {
    do {
        let fileData = try Data(contentsOf: url)
        return fileData
    } catch {
        log("Error reading file: \(error)")
        throw error
    }
}

func overwriteWithFileImpl(replacementURL: URL, pathToTargetFile: String) throws {
    let cPathtoTargetFile = pathToTargetFile.withCString { ptr in
        return strdup(ptr)
    }
    
    _ = UnsafeMutablePointer<Int8>(mutating: cPathtoTargetFile)
    
    let cFileURL = replacementURL.path.withCString { ptr in
        return strdup(ptr)
    }
    let mutablecFileURL = UnsafeMutablePointer<Int8>(mutating: cFileURL)
    
    let result = funVnodeOverwrite2(cPathtoTargetFile, mutablecFileURL)
    
    usleep(100)
    
    if result != 0 {
        throw "Failed To Overwrite File"
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
        log("Error loading JSON data: \(error)")
        throw error
    }
    return [:]
}

extension String {
    func legacyencryptedOperations(pkgpath: URL, exploit_method: Int) -> String {
        var save: [String: Any] = [:]
        if let savepath = FileManager.default.contents(atPath: pkgpath.appendingPathComponent("save.json").path),
           let savedict = try? JSONSerialization.jsonObject(with: savepath, options: []) {
            save = savedict as? [String: Any] ?? [:]
        }
        var path = self
            .replacingOccurrences(of: "%Optional%", with: "")
            .replacingOccurrences(of: "%Misaka_Resize%", with: "")
            .replacingOccurrences(of: "%Misaka_Path{'SpringLang'}%", with: Locale.current.languageCode ?? "")
            .replacingOccurrences(of: "%Misaka_Path{'DeviceType'}%", with: (UIDevice.current.userInterfaceIdiom == .phone) ? "iphone" : "ipad")
        for item in path.components(separatedBy: "/") {
            if item.contains("Misaka_Segment") {
                let fileName = parseLegacyEncryptedSegment(from: item)[0]
                let variableName = parseLegacyEncryptedSegment(from: item)[1]
                let variableValue = parseLegacyEncryptedSegment(from: item)[2]
                log("fileName: %@\nvariableName: %@\nvariableValue: %@", fileName, variableName, variableValue)
                if variableName == "iOSver" {
                    let deviceInfo = getDeviceInfo(appData: nil).3
                    if variableValue == "\(deviceInfo.major)" {
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
                let bundleid = legacyencryptedOperationValues(from: item)[0]
                if legacyencryptedOperationValues(from: item)[1] == "Data" {
                    do {
                        path = try path.replacingOccurrences(of: "/var/mobile/Containers/Data/Application/"+item, with: getDataDir(bundleID: bundleid, exploit_method: exploit_method).path)
                    } catch {log("failed")}
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
    
    if (exploit_method == 0 || exploit_method == 3) && ((try? (FileManager.default.contentsOfDirectory(atPath: "/var"))) == nil) {
        let mmpath = mounted + "/.com.apple.mobile_container_manager.metadata.plist"
        log("%@", mmpath)
        let vdata = createFolderAndRedirectTemp(path+"/"+uuid)
        do {
            if vdata != UInt64.max {
                var mmDict: [String: Any]
                if fm.fileExists(atPath: mmpath) {
                    mmDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: mmpath)), options: [], format: nil) as? [String: Any] ?? [:]
                    log("%@", "\(mmDict["MCMMetadataIdentifier"] ?? "")")
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
                log("%@", "\(mmDict["MCMMetadataIdentifier"] ?? "")")
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
    
    if (exploit_method == 0 || exploit_method == 3) && ((try? (FileManager.default.contentsOfDirectory(atPath: "/var"))) == nil) {
        if let path = savedAppDataPaths[bundleID] {
            returnedurl = URL(fileURLWithPath: path)
            return URL(fileURLWithPath: path)
        } else {
            var vdata = createFolderAndRedirect2("/var/mobile/Containers/Data/Application")
            
            do {
                dirlist = try fm.contentsOfDirectory(atPath: URL.documents.appendingPathComponent("mounted").path)
                // log(dirlist)
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
                        log("%@", "\(mmDict["MCMMetadataIdentifier"] ?? "")")
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
            // log(dirlist)
        } catch {
            throw "Could not access /var/mobile/Containers/Data/Application.\n\(error.localizedDescription)"
        }
        
        for dir in dirlist {
            // log(dir)
            let mmpath = "/var/mobile/Containers/Data/Application/" + dir + "/.com.apple.mobile_container_manager.metadata.plist"
            // log(mmpath)
            do {
                var mmDict: [String: Any]
                if fm.fileExists(atPath: mmpath) {
                    mmDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: mmpath)), options: [], format: nil) as? [String: Any] ?? [:]
                    // log(mmDict as Any)
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

// Funni LegacyEncrypted Parse stuff written by chatgpt

func legacyencryptedOperationValues(from inputString: String) -> [String] {
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
        log("Error: %@", "\(error)")
    }

    return extractedValues
}

func parseLegacyEncryptedSegment(from inputString: String) -> [String] {
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
        log("Error: %@", "\(error)")
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
