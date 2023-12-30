//
//  DetailedPackageView.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/10/23.
//

import SwiftUI
import SDWebImageSwiftUI
import MarqueeText
import TextFieldAlert
import Foundation
import Zip
import libpurekfd

struct PackagePreviewView: View {
    let package: Package
    var body: some View {
        ZStack {
            // Banner Image
            if package.banner != nil {
                if let bannerURL = package.banner, let url = URL(string: bannerURL.absoluteString), UIApplication.shared.canOpenURL(url) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: 240)
                        .clipped()
                }
            }
            Rectangle().frame(width: 318, height: 118).blur(radius: 100).cornerRadius(20).foregroundColor(.gray).padding(.leading, 10)
            // Package Info
            HStack {
                if let iconURL = package.icon, let url = URL(string: iconURL.absoluteString), UIApplication.shared.canOpenURL(url) {
                    WebImage(url: url)
                        .resizable()
                        .placeholder(Image("pkg_icon").renderingMode(.template).resizable())
                        .scaledToFit()
                        .frame(width: 118, height: 118)
                        .cornerRadius(20)
                        .padding(.leading)
                        .contextMenu(menuItems: {
                            Button(action: {
                                let pasteboard = UIPasteboard.general
                                pasteboard.string = url.absoluteString
                            }) {
                                Text("Copy Image URL")
                                Image("copy_icon").renderingMode(.template)
                            }
                        })
                } else {
                    Image("pkg_icon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .cornerRadius(10)
                        .padding(.leading)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(package.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("By \(package.author) v\(String(package.version ?? ""))" + (package.path?.isFileURL ?? false ? " (local)" : ""))
                        .font(.subheadline)
                        .foregroundColor(Color.accentColor.opacity(0.7))
                        .lineLimit(1)
                    
                    MarqueeText(
                        text: package.desc,
                        font: UIFont.preferredFont(forTextStyle: .body),
                        leftFade: 16,
                        rightFade: 16,
                        startDelay: 3
                    )
                }
            }.padding(.leading, 10)
        }
    }
}

struct PackageDetailView: View {
    let package: Package
    let appData: AppData
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) var openURL
    @State private var downloadProgress: CGFloat = 0.0
    @State private var isDownloading = false
    @State private var isExtracting = false
    @State private var isInstalled = false
    @State private var downloadFailed = false
    @State private var showAlert = false
    @State private var hasBanner = false
    @State private var alertMessage = ""
    @State private var refreshed = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Banner Image
                HStack() {
                    if package.banner != nil {
                        if let bannerURL = package.banner, let url = URL(string: bannerURL.absoluteString), UIApplication.shared.canOpenURL(url) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width-30, height: 180)
                                .shadow(color: Color.black.opacity(0.7), radius: 5, x: 3, y: 5)
                            //.clipped()
                                .cornerRadius(15)
                            
                                .onAppear() {
                                    hasBanner = true
                                }
                                .contextMenu(menuItems: {
                                    Button(action: {
                                        let pasteboard = UIPasteboard.general
                                        pasteboard.string = url.absoluteString
                                    }) {
                                        Text("Copy Image URL")
                                        Image("copy_icon").renderingMode(.template)
                                    }
                                })
                        }
                    }
                }.padding(.horizontal)
                
                // Package Info
                HStack {
                    if let iconURL = package.icon, let url = URL(string: iconURL.absoluteString), UIApplication.shared.canOpenURL(url) {
                        WebImage(url: url)
                            .resizable()
                            .placeholder(Image("pkg_icon").renderingMode(.template).resizable())
                            .scaledToFit()
                            .frame(width: 118, height: 118)
                            .cornerRadius(20)
                            .padding(.leading)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                            .contextMenu(menuItems: {
                                Button(action: {
                                    let pasteboard = UIPasteboard.general
                                    pasteboard.string = url.absoluteString
                                }) {
                                    Text("Copy Image URL")
                                    Image("copy_icon").renderingMode(.template)
                                }
                            })
                    } else {
                        Image("pkg_icon")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                            .padding(.leading)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(package.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        
                        Text("By \(package.author) v\(String(package.version ?? ""))" + (package.path?.isFileURL ?? false ? " (local)" : ""))
                            .font(.subheadline)
                            .foregroundColor(Color.accentColor.opacity(0.7))
                            .lineLimit(1)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        
                        MarqueeText(
                            text: package.desc,
                            font: UIFont.preferredFont(forTextStyle: .body),
                            leftFade: 16,
                            rightFade: 16,
                            startDelay: 3
                        ).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        
                        Spacer()
                        
                        Button(action: {
                            if package.installtype == "shortcut" {
                                openURL(package.path ?? URL(fileURLWithPath: "none"))
                            } else if package.installtype == "jb" {
                                UIApplication.shared.alert(title: "Unsupported", body: "for now...", animated: false, withButton: true)
                            } else {
                                if !isDownloading && !isInstalled {
                                    isDownloading = true
                                    downloadPackage(pkg: package)
                                }
                            }
                        }) {
                            ZStack {
                                Text(isInstalled ? "Installed" : isDownloading ? "\(Int(downloadProgress * 100))%" : isExtracting ? "Extracting" : downloadFailed ? "Error" : (package.installtype == "shortcut") ? "Open" : "Install")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: isInstalled || isExtracting ? 100 : 80, height: 30)
                                    .background(isDownloading || isInstalled || isExtracting || downloadFailed ? Color.accentColor.opacity(0.7) : Color.accentColor)
                                    .cornerRadius(20)
                            }
                        }.shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2).onAppear() {isInstalled = isPackageInstalled(package.bundleID)}.contextMenu(menuItems: {
                            if package.pkgtype == "misaka" && !isInstalled {
                                ForEach(package.versions?.keys.sorted() ?? [], id: \.self) { versionKey in
                                    if let release = package.versions?[versionKey] {
                                        Button(action: {
                                            if !isDownloading && !isInstalled && !isPackageInstalled(package.bundleID) {
                                                isDownloading = true
                                                downloadPackage(pkg: package, SpecifyRelease: release)
                                            }
                                        }) {
                                            Text("Install v\(versionKey)")
                                            Image("download_icon").renderingMode(.template)
                                        }
                                    }
                                }
                            }
                            if isInstalled {
                                Button(action: {
                                    purgePackage(package.bundleID)
                                    isInstalled = false
                                }) {
                                    Text("Delete Package")
                                    Image("trash_icon").renderingMode(.template)
                                }.foregroundColor(.red)
                            }
                        })

                    }
                    .padding()
                }
                
                if !(package.longdesc == nil || package.longdesc == "") {
                    Text("Description")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    Text(package.longdesc ?? "")
                        .padding(.horizontal)
                        .font(.body)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                }
                
                Rectangle()
                    .frame(height: 0.1)
                    .foregroundColor(Color.clear)
                
                // Screenshots
                if let screenshots = package.screenshots, !screenshots.isEmpty {
                    Text("Preview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(screenshots, id: \.self) { screenshotURL in
                                if let url = URL(string: screenshotURL!.absoluteString), UIApplication.shared.canOpenURL(url) {
                                    WebImage(url: url)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 185, height: 400)
                                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                                        .cornerRadius(10)
                                        .contextMenu(menuItems: {
                                            Button(action: {
                                                let pasteboard = UIPasteboard.general
                                                pasteboard.string = url.absoluteString
                                            }) {
                                                Text("Copy Image URL")
                                                Image("copy_icon").renderingMode(.template)
                                            }
                                        })
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }.alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Download Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear() {
//            if package.accent != nil,
//               refreshed == false {
//                let ogaccent = UserDefaults.standard.string(forKey: "accentColor")
//                UserDefaults.standard.set(package.accent, forKey: "accentColor")
//                refreshed = true
//                refreshView(appData: appData)
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    UserDefaults.standard.set(ogaccent, forKey: "accentColor")
//                }
//            }
        }
        .onDisappear() {
            refreshView(appData: appData)
        }.bgImage(appData)
        .navigationBarTitle("", displayMode: .inline)
    }
    
    func downloadPackage(pkg: Package, SpecifyRelease: String? = nil) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let tempDirectory = documentsDirectory.appendingPathComponent("temp", isDirectory: true)
        isDownloading = true
        
        log("download")
        
        // Create the temp directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            alertMessage = "Failed to create temp directory: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        var path = pkg.path
        
        if SpecifyRelease != nil {
            path = URL(string: SpecifyRelease ?? "")
        }
        
        if !(path?.isFileURL ?? false) {
            downloadFileFromURL(path) { error, progress, path  in
                if let error = error {
                    alertMessage = "Failed to download the package: \(error.localizedDescription)"
                    showAlert = true
                    isDownloading = false
                } else {
                    downloadProgress = progress
                    if progress >= 1.1 {
                        isDownloading = false
                        isExtracting = true
                        let error = installPackage(pkg: package, path: path ?? URL(string: "file:///")!, appData: appData)
                        try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("temp"))
                        if error == nil {
                            isInstalled = true
                            isExtracting = false
                        } else {
                            alertMessage = "Failed to install the package: \(String(describing: error!.localizedDescription))"
                            showAlert = true
                            isExtracting = false
                            downloadFailed = true
                        }
                    }
                }
            }
        } else {
            isDownloading = false
            isExtracting = true
            let error = installPackage(pkg: package, path: path!, appData: appData)
            if error == nil {
                isInstalled = true
                isExtracting = false
            } else {
                alertMessage = "Failed to install the package: \(String(describing: error!.localizedDescription))"
                showAlert = true
                isExtracting = false
                downloadFailed = true
            }
        }
    }

    class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
        var completion: ((Error?, CGFloat, URL?) -> Void)?
        var destinationURL: URL?

        init(destinationURL: URL?, completion: ((Error?, CGFloat, URL?) -> Void)?) {
            self.destinationURL = destinationURL
            self.completion = completion
        }
            
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                self.completion?(nil, progress, nil)
            }
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            do {
                if let destinationURL = self.destinationURL {
                    try FileManager.default.moveItem(at: location, to: destinationURL)
                    completion?(nil, 1.1, destinationURL)
                } else {
                    let error = NSError(domain: "YourAppDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Destination URL is nil"])
                    completion?(error, 0.0, nil)
                }
            } catch {
                completion?(error, 0.0, nil)
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error {
                completion?(error, 0.0, nil)
            }
        }
    }
    
    func downloadFileFromURL(_ url: URL?, target: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("temp", isDirectory: true), completion: @escaping (Error?, CGFloat, URL?) -> Void) {
        guard let downloadURL = url else {
            let error = NSError(domain: "YourAppDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(error, 0.0, nil)
            return
        }
        
        let destinationURL = target.appendingPathComponent(downloadURL.lastPathComponent.appending(".zip"))
        let session = URLSession(configuration: .default, delegate: DownloadDelegate(destinationURL: destinationURL, completion: completion), delegateQueue: nil)
        let downloadTask = session.downloadTask(with: downloadURL)
        
        downloadTask.resume()
    }
}

func installPackage(pkg: Package, path: URL, appData: AppData) -> Error? {
    if FileManager.default.fileExists(atPath: path.path) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let installedDirectory = documentsDirectory.appendingPathComponent("installed", isDirectory: true)
        let pkgdir = installedDirectory.appendingPathComponent(pkg.bundleID)
        let tempDirectory = documentsDirectory.appendingPathComponent("temp", isDirectory: true)
        let error = extractPackage(path).0
        
        // Create the installed directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: installedDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return NSError(domain: "YourDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Failed to create installed directory: \(error.localizedDescription)"])
        }
        
        if error == nil {
            if FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("extracted").path) {
                do {
                    let extractedContents = try FileManager.default.contentsOfDirectory(at: tempDirectory.appendingPathComponent("extracted"), includingPropertiesForKeys: nil, options: [])
                    let filteredContents = extractedContents.filter { !$0.lastPathComponent.hasPrefix("_") }
                    if let foldername = filteredContents.first {
                        // Setup
                        try FileManager.default.moveItem(at: foldername, to: pkgdir)
                        let encoder = JSONEncoder()
                        let fileURL = pkgdir.appendingPathComponent("info.json")
                        if FileManager.default.fileExists(atPath: fileURL.path) {try FileManager.default.removeItem(atPath: fileURL.path)}
                        // Read Package & Save Info
                        var package = pkg
                        var preftype = "none"
                        if FileManager.default.fileExists(atPath: pkgdir.appendingPathComponent("config.plist").path) {package.hasprefs = true; preftype="misaka"}
                        if FileManager.default.fileExists(atPath: pkgdir.appendingPathComponent("config.json").path) {package.hasprefs = true; preftype="purekfd"}
                        if FileManager.default.fileExists(atPath: pkgdir.appendingPathComponent("prefs.json").path) {
                            let jsonData = try Data(contentsOf: pkgdir.appendingPathComponent("prefs.json"))
                            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                               let preferences = jsonObject["preferences"] as? [Any],
                               !preferences.isEmpty {
                                package.hasprefs = true
                                preftype="picasso"
                            }
                        }
                        if package.hasprefs ?? false && appData.UserData.translateoninstall {
                            translatePrefs(preftype, pkgpath: pkgdir)
                        }
                        let jsonData = try encoder.encode(package)
                        try jsonData.write(to: fileURL)
                        try FileManager.default.removeItem(at: tempDirectory.appendingPathComponent("extracted"))
                    } else {
                        return NSError(domain: "YourDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred on extract! (extracted folder empty)"])
                    }
                    do {try FileManager.default.removeItem(at: tempDirectory)} catch {}
                    do {try FileManager.default.removeItem(at: documentsDirectory.appendingPathComponent("Misaka"))} catch {}
                    cleanTemp()
                    return nil
                } catch {
                    return NSError(domain: "YourDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Error while accessing extracted folder contents: \(error.localizedDescription)"])
                }
            } else {
                return NSError(domain: "YourDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred on extract! (extracted folder not found)"])
            }
        } else {
            return error
        }
    } else {
        return NSError(domain: "YourDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Downloaded file does not exist"])
    }
}

// Importing packages:
class ViewModel: ObservableObject {
    @Published var data: String = ""
    
    func openFile(_ url: URL, appdata: AppData) -> Package? {
        var ret: Package? = nil
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let tempDirectory = documentsDirectory.appendingPathComponent("temp", isDirectory: true)
        let importedDirectory = documentsDirectory.appendingPathComponent("imported", isDirectory: true)
        let target = importedDirectory.appendingPathComponent(url.lastPathComponent).appendingPathExtension("zip")
        
        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {}
        
        do {
            try FileManager.default.createDirectory(at: importedDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {}
        if let downloadedURL = downloadFile(from: url, to: target) {
            ret = extractPackage(downloadedURL, readPackageInfo: true, appdata: appdata, checkPkgList: true).1
        }
        
        do {
            try FileManager.default.removeItem(at: tempDirectory)
        } catch {}
        
        ret?.path = URL(fileURLWithPath: target.path)
        return ret
    }
    
    private func downloadFile(from url: URL, to destinationURL: URL) -> URL? {
        let semaphore = DispatchSemaphore(value: 0)
        
        var downloadedURL: URL?
        
        URLSession.shared.downloadTask(with: url) { (tempURL, _, _) in
            if let tempURL = tempURL {
                do {
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    downloadedURL = destinationURL
                } catch {
                    log("%@", "Error moving downloaded file: \(error)")
                }
            }
            semaphore.signal()
        }.resume()
        
        semaphore.wait()
        
        return downloadedURL
    }
}

// I'll fix this later
class BackupManager: ObservableObject {
    func importBackup(_ url: URL, appdata: AppData) throws {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backupPath = documentsDirectory.appendingPathComponent("temp_purekfdbackup.zip")
        do {try FileManager.default.copyItem(atPath: url.path, toPath: backupPath.path)} catch {}
        if unzip(Data_zip: backupPath, Extract: documentsDirectory) == false {
            do {try FileManager.default.removeItem(at: backupPath)} catch {}
            throw "Failed to extract"
        }
        do {try FileManager.default.removeItem(at: backupPath)} catch {}
    }
    func exportBackup() {
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("backup.purekfdbackup")
        do {
            try Zip.zipFiles(paths: getContentsOfFolder(folderURL: URL.documents) ?? [], zipFilePath: zipURL, password: nil, progress: nil)
            let av = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
        } catch {
            UIApplication.shared.alert(title: "Error", body: "Unknown error occured", withButton: true)
        }
    }
}

func extractPackage(_ url: URL, readPackageInfo: Bool = false, appdata: AppData? = nil, checkPkgList: Bool = false) -> (Error?, Package?) {
    let fileManager = FileManager.default
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let tempDirectory = documentsDirectory.appendingPathComponent("temp", isDirectory: true)
    let extractedDir = tempDirectory.appendingPathComponent("extracted")
    
    do {
        try fileManager.createDirectory(at: extractedDir, withIntermediateDirectories: true, attributes: nil)
    } catch {
        log("%@", "Error creating directory: \(error.localizedDescription)")
        return (error, nil)
    }
    
    if !unzip(Data_zip: url, Extract: extractedDir) {
        return (NSError(domain: "YourDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Failed To Extract"]), nil)
    }
    
    // Read Package (For Local Packages)
    if readPackageInfo {
        let infoJsonURL = extractedDir
            .appendingPathComponent(url.lastPathComponent.removingFileExtensions(2))
            .appendingPathComponent("info.json")
        
        do {
            let data = try Data(contentsOf: infoJsonURL)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                var package = Package(
                    name: "Name",
                    bundleID: "id",
                    author: "Author",
                    version: "1.0",
                    desc: "",
                    longdesc: "",
                    icon: URL(string: ""),
                    accent: nil,
                    screenshots: [],
                    banner: nil,
                    previewbg: nil, 
                    category: "Misc",
                    install_actions: [],
                    uninstall_actions: [],
                    url: nil,
                    repo: nil,
                    pkgtype: "purekfd"
                )
                if let json = json {
                    if let name = json["name"] as? String {
                        package.name = name
                    }
                    if let bundleID = json["bundleID"] as? String {
                        package.bundleID = bundleID
                    }
                    if let author = json["author"] as? String {
                        package.author = author
                    }
                    if let version = json["version"] as? String {
                        package.version = version
                    }
                }

                if checkPkgList {
                    let packageList = getPackageList(appdata: appdata!)
                if var existingPackage = packageList.first(where: { $0.bundleID == package.bundleID }) {
                    existingPackage.path = url
                    return (nil, existingPackage)
                }
            }

            return (nil, package)
        } catch {
            if !FileManager.default.fileExists(atPath: extractedDir.appendingPathComponent(url.lastPathComponent.removingFileExtensions(2)).appendingPathComponent("Overwrite").path) {
                log("%@", "Error reading info.json or decoding package: \(error.localizedDescription)")
                return (error, nil)
            } else {
                return (nil, Package(name: "Misaka Package", bundleID: "\(UUID())", author: "Unknown", desc: "Unknown", longdesc: nil, accent: nil, screenshots: nil, banner: nil, previewbg: nil, category: "Misc", install_actions: [], uninstall_actions: [], url: nil, pkgtype: "misaka"))
            }
        }
    }

    return (nil, nil)
}

func translatePrefs(_ preftype: String, pkgpath: URL) {
    let tofile = pkgpath.appendingPathComponent("config.json")
    if preftype == "picasso" {
        if let picassoPrefData = FileManager.default.contents(atPath: pkgpath.appendingPathComponent("prefs.json").path),
           let picassoPrefDict = try? JSONSerialization.jsonObject(with: picassoPrefData, options: []),
           let jsonDictionary = translatePicassoPrefs(picassoData: picassoPrefDict as? [String : [[String : Any]]] ?? [:]),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: [.prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            do {
                try jsonString.write(toFile: tofile.path, atomically: true, encoding: .utf8)
                log("%@", "Data saved to file: \(pkgpath.path)")
            } catch {
                log("%@", "Error saving data to file: \(error)")
            }
        }
    } else if preftype == "misaka" {
        if let plistData = FileManager.default.contents(atPath: pkgpath.appendingPathComponent("config.plist").path),
            let jsonDictionary = translateMisakaPrefs(plistData: plistData),
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            do {
                try jsonString.write(toFile: tofile.path, atomically: true, encoding: .utf8)
                log("%@", "Data saved to file: \(pkgpath.path)")
            } catch {
                log("%@", "Error saving data to file: \(error)")
            }
        }
    }
}
