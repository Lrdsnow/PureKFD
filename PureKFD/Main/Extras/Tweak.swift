import Foundation
import SwiftUI

func getExploitMethod(appData: AppData) -> (Int, SavedKFDData) {
    var exploit_method = -1
    var kfddata = SavedKFDData(puaf_pages: 2048, puaf_method: 1, kread_method: 1, kwrite_method: 1)
    if !appData.UserData.override_exploit_method {
        let systemVersion = UIDevice.current.systemVersion
        let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }
        if versionComponents.count >= 2 {
            let major = versionComponents[0]
            let minor = versionComponents[1]
            
            if (major == 14 && minor <= 7) ||
                (major == 15 && minor <= 7) ||
                (major == 16 && minor <= 1) {
                exploit_method = 1
            } else if (major == 16 && minor >= 2 && minor <= 6) {
                exploit_method = 0
            }
        }
    } else {
        exploit_method = appData.UserData.exploit_method
        kfddata = appData.UserData.kfd
    }
    appData.UserData.exploit_method = exploit_method
    appData.UserData.kfd = kfddata
    return (exploit_method, kfddata)
}

func applyTweaks(appData: AppData) {
    // Get Exploit
    var exploit_method = getExploitMethod(appData: appData).0
    var kfddata = getExploitMethod(appData: appData).1
    
    // KFD Stuff
    if exploit_method == 0 && !appData.kopened {
        let exploit_result = do_kopen(UInt64(kfddata.puaf_pages), UInt64(kfddata.puaf_method), UInt64(kfddata.kread_method), UInt64(kfddata.kwrite_method))
        if exploit_result == 0 {
            return
        }
        fix_exploit()
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
            let itemName = itemURL.lastPathComponent

            if isDirectory.boolValue {
                do {
                    let subContents = try fileManager.contentsOfDirectory(at: itemURL, includingPropertiesForKeys: nil, options: [])
                    for subItemURL in subContents {
                        try await processItem(at: subItemURL, relativeTo: baseURL)
                    }
                } catch {
                    writeErrors.append("\(error)")
                }
            } else {
                let relativePath = replaceBeforeAndSubstring(in: itemURL.path, targetSubstring: "/Overwrite", with: "").misakaOperations(pkgpath: pkgpath, exploit_method: exploit_method)
                do {
                    if !relativePath.contains(".plist") {
                        if exploit_method == 0 { // KFD
                            try await overwriteWithFileImpl(replacementURL: itemURL, pathToTargetFile: relativePath)
                        } else if exploit_method == 1 { // MDC
                            try await MDC.overwriteFile(at: relativePath, with: readFileAsData(atURL: itemURL)!)
                        } else if exploit_method == 3 { // Rootless
                            try await readFileAsData(atURL: itemURL)!.write(to: URL(fileURLWithPath: "/var/jb/"+relativePath))
                        } else { // Rootful
                            try await readFileAsData(atURL: itemURL)!.write(to: URL(fileURLWithPath: relativePath))
                        }
                    }
                } catch {
                    if relativePath.hasPrefix("/var/mobile/Containers/Data/Application") {
                        if exploit_method == 0 {
                            let fileManager = FileManager.default
                            let path = URL.documents.appendingPathComponent("mounted")
                            let folderpath = URL(fileURLWithPath: relativePath).deletingLastPathComponent().path
                            var writepath = path.appendingPathComponent(relativePath.components(separatedBy: "/").last ?? "")
                            
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
                        if exploit_method == 0 {
                            let fileManager = FileManager.default
                            let path = URL.documents.appendingPathComponent("mounted").appendingPathComponent(URL(fileURLWithPath: relativePath).deletingLastPathComponent().path.replacingOccurrences(of: "/var/mobile/Documents/", with: ""))
                            let basefolder = URL.documents.appendingPathComponent("mounted").appendingPathComponent(URL(fileURLWithPath: relativePath).deletingLastPathComponent().path.replacingOccurrences(of: "/var/mobile/Documents/", with: "").components(separatedBy: "/").first ?? "")
                            let filepath = URL.documents.appendingPathComponent("mounted").appendingPathComponent(URL(fileURLWithPath: relativePath).path.replacingOccurrences(of: "/var/mobile/Documents/", with: ""))
                            
                            let vdata = createFolderAndRedirect2("/var/mobile/Documents")
                            
                            do {
                                do {
                                    try FileManager.default.removeItem(atPath: path.path)
                                } catch {print(error)}
                                do {
                                    try FileManager.default.removeItem(atPath: basefolder.path)
                                } catch {print(error)}
                                do {
                                    try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
                                } catch {
                                    print(error)
                                    writeErrors.append("\(error)")
                                }
                                print(filepath.path)
                                try await readFileAsData(atURL: itemURL)!.write(to: filepath)
                            } catch {
                                print(error)
                                writeErrors.append("\(error)")
                            }
                            
                            UnRedirectAndRemoveFolder2(vdata)
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

    try await processItem(at: sourceFolderURL, relativeTo: sourceFolderURL)
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

            let mutablecPathtoTargetFile = UnsafeMutablePointer<Int8>(mutating: cPathtoTargetFile)

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
            ResSet16(hight, width)
        case "panic":
            do_kopen(0, 0, 0, 0)
        case "replacing":
            let frompath = operation["replacementFileName"] as? String ?? ""
            var frompathurl: URL
            if operation["replacementFileBundled"] as? Bool ?? false {
                frompathurl = pkgpath.appendingPathComponent(frompath)
            } else {
                frompathurl = URL(string: frompath) ?? URL(string: "file:///")!
            }
            do {
                try await overwriteWithFileImpl(replacementURL: frompathurl, pathToTargetFile: operation["originPath"] as? String ?? "")
            } catch {}
        case "removing":
            let originPath = operation["originPath"] as? String ?? ""
            funVnodeHide(strdup(originPath))
        case "subtype":
            let subtype = save["subtype"] as? Int ?? 2532//2796
            DynamicKFD(Int32(subtype))
        case "springboardColor":
            let springboardElement = SpringboardColorManager.convertStringToSpringboardType(operation["springboardElement"] as? String ?? "")!
            let colorVariableName: String = operation["colorVariableName"] as? String ?? "color"
            let blurVariableName: String = operation["blurVariableName"] as? String ?? "blur"
            if let color = UIColor(hex: save[colorVariableName] as? String ?? "") {
                let blur = save[blurVariableName] as? Int ?? Int(save[blurVariableName] as? String ?? "1") ?? 1
                do {
                    try SpringboardColorManager.createColor(forType: springboardElement, color: CIColor(color: color), blur: blur, asTemp: false)
                    for _ in 1...5 {
                        try await SpringboardColorManager.applyColor(forType: springboardElement, exploit_method: getExploitMethod(appData: appData).0)
                    }
                } catch {}
            }
        default:
            print("Unsupported Tweak:", operationType)
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
                if ("\(save[variableName] as? Int ?? 0)" == "1") && ("\(variableValue)" == "YES") || ("\(save[variableName] as? Int ?? 1)" == "0") && ("\(variableValue)" == "NO") || ("\(save[variableName] as? String ?? "\(UUID())")" == "\(variableValue)") {
                    path = path.replacingOccurrences(of: item, with: fileName)
                }
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

func getDataDir(bundleID: String, exploit_method: Int) throws -> URL {
    let fm = FileManager.default
    var returnedurl = URL(string: "none")
    let mounted = URL.documents.appendingPathComponent("mounted").path
    var dirlist = [""]
    var savedAppDataPaths = UserDefaults.standard.dictionary(forKey: "appdatapaths") as? [String: String] ?? [:]
    
    if exploit_method == 0 {
        if let path = savedAppDataPaths[bundleID] as? String {
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
                        print(mmDict["MCMMetadataIdentifier"])
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
