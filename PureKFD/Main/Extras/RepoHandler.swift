//
//  RepoHandler.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import SwiftUI
import Foundation

enum PackageFilter {
    case none
    case hasScreenshots
    case hasBanner
    case hasIcon
}

func getPackageList(appdata: AppData, filters: [PackageFilter] = [.none]) -> [Package] {
    var packageList: [Package] = []
    
    for (_, repoList) in appdata.repoSections {
        for repo in repoList {
            var filteredPackages: [Package] = repo.packages

            for filter in filters {
                switch filter {
                case .hasScreenshots:
                    filteredPackages = filteredPackages.filter { !($0.screenshots?.isEmpty ?? true) }
                case .hasBanner:
                    filteredPackages = filteredPackages.filter { !($0.banner == nil) }
                case .hasIcon:
                    filteredPackages = filteredPackages.filter { !($0.icon == nil || $0.icon == URL(string: "")) }
                default:
                    break
                }
            }

            packageList.append(contentsOf: filteredPackages)
        }
    }

    return packageList
}

func getFeaturedPackageList(appdata: AppData) -> [Featured] {
    var packageList: [Featured] = []
    for (_, repoList) in appdata.repoSections {
        for repo in repoList {
            if !(repo.featured?.isEmpty ?? true) {
                packageList.append(contentsOf: repo.featured!)
            }
        }
    }
    return packageList
}

func isPackageInstalled(_ bundleid: String) -> Bool {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let installedDirectory = documentsDirectory.appendingPathComponent("installed", isDirectory: true)
    if FileManager.default.fileExists(atPath: installedDirectory.appendingPathComponent(bundleid).path) {
        return true
    }
    return false
}

func purgePackage(_ bundleid: String) {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let installedDirectory = documentsDirectory.appendingPathComponent("installed", isDirectory: true)
    do {try FileManager.default.removeItem(atPath: installedDirectory.appendingPathComponent(bundleid).path)} catch {}
}

func getInstalledPackages() -> [Package] {
    var packages: [Package] = []
    let folderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("installed")
    
    if let folderURL = folderURL {
        do {
            let fileManager = FileManager.default
            let folderContents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            for itemURL in folderContents {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory) {
                    let jsonData = try Data(contentsOf: itemURL.appendingPathComponent("info.json"))
                    let decoder = JSONDecoder()
                    let package = try decoder.decode(Package.self, from: jsonData)
                    packages.append(package)
                }
            }
        } catch {
            print("Error while processing folder: \(error.localizedDescription)")
        }
    }
    
    return packages
}

func getRepos(appdata: AppData, completion: @escaping (Repo) -> Void) async {
    var repourls = SavedRepoData()
    repourls.urls += appdata.RepoData.urls
    
    // Create a queue to process repos one at a time
    let queue = DispatchQueue(label: "com.example.fetchReposQueue", qos: .userInitiated)
    
    for url in repourls.urls {
        await getRepoInfo(url.absoluteString) { repoInfo in
            completion(repoInfo)
        }
    }
}

func findPackageViaBundleID(_ bundleid: String, appdata: AppData) -> Package? {
    let packageList = getPackageList(appdata: appdata)
    if var package = packageList.first(where: { $0.bundleID == bundleid }) {
        return package
    }
    return nil
}


func downloadJSON(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) async {
    let urlSession = await URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        if let data = data {
            completion(.success(data))
        }
    }
        
    urlSession.resume()
}

func getRepoInfo(_ repourl: String, completion: @escaping (Repo) -> Void) async {
    let blankrepo: Repo = Repo(name: "Unknown", desc: "", url: URL(string: ""), icon: "", accent: nil, featured: [], packages: [], repotype: "unknown", purekfd: nil, misaka: nil, picasso: nil)
    
    if let url = URL(string: repourl) {
        await downloadJSON(from: url) { (result) in
            var repo: Repo = blankrepo
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                do {
                    switch getRepoType(String(data: data, encoding: .utf8) ?? "") {
                    case "purekfd":
                        var repodata = try decoder.decode(PureKFDRepo.self, from: data)
                        repodata.url = url.deletingLastPathComponent()
                        repo = translateToRepo(repoType: "purekfd", repo: repodata) ?? blankrepo
                    case "misaka":
                        var repodata = try decoder.decode(MisakaRepo.self, from: data)
                        repodata.RepositoryURL = url.deletingLastPathComponent()
                        repo = translateToRepo(repoType: "misaka", repo: repodata) ?? blankrepo
                    case "picasso":
                        var repodata = try decoder.decode(PicassoRepo.self, from: data)
                        repodata.url = url.deletingLastPathComponent()
                        repo = translateToRepo(repoType: "picasso", repo: repodata) ?? blankrepo
                    case "flux":
                        let repodata = try decoder.decode([String:FluxPkg].self, from: data)
                        repo = translateToRepo(repoType: "flux", repo: repodata, repoURL: url) ?? blankrepo
                    case "jb":
                        if let jsonData = try? JSONSerialization.data(withJSONObject: String(data: data, encoding: .utf8)?.toJSON() as Any, options: .prettyPrinted) {
                            let repodata = try decoder.decode(JBRepo.self, from: jsonData)
                            repo = translateToRepo(repoType: "jb", repo: repodata, repoURL: url.deletingLastPathComponent()) ?? blankrepo
                        }
                    case "unknown":
                        repo.desc = "Unrecognized Repo (\(url)"
                        repo.url = url.deletingLastPathComponent()
                    default:
                        repo.desc = "Invalid JSON (\(url)"
                        repo.url = url.deletingLastPathComponent()

                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                    repo.desc = "Error Decoding JSON (\(url))"
                    repo.url = url.deletingLastPathComponent()
                }
            case .failure(let error):
                print("Error fetching JSON: \(error)")
                repo.desc = "Error fetching JSON (\(url))"
                repo.url = url.deletingLastPathComponent()
            }
            if !(repo.desc == "") {
                completion(repo)
            }
        }
    } else {
        completion(blankrepo)
    }
}

func getRepoType(_ jsonString: String) -> String {
    if jsonString.contains("b64icon") {
        return "flux"
    } else if jsonString.contains("MD5Sum:") && jsonString.contains("Origin:") {
        return "jb"
    }
    if let data = jsonString.data(using: .utf8) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if json["repotype"] is String {
                    return "purekfd"
                } else if json["RepositoryName"] is String {
                    return "misaka"
                } else {
                    return "picasso"
                }
            }
        } catch {
            return "unknown"
        }
    }
    return "invalid"
}
