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

func getAllRepos(appdata: AppData) async -> [Repo] {
    var repourls = SavedRepoData()
    repourls.urls += appdata.RepoData.urls

    var readRepos = Set<URL>()
    var repos: [Repo] = []

    for url in repourls.urls {
        if !readRepos.contains(url) {
            let repoInfo = await getRepoInfo(url.absoluteString, appData: appdata)
            if repoInfo.url?.absoluteString != "" {
                repos.append(repoInfo)
                readRepos.insert(url)
            }
        }
    }
    
    return repos
}

func getRepos(appdata: AppData, completion: @escaping (Repo) -> Void) async {
    var repourls = SavedRepoData()
    repourls.urls += appdata.RepoData.urls
    
    for url in repourls.urls {
        completion(await getRepoInfo(url.absoluteString, appData: appdata))
    }
}

func findPackageViaBundleID(_ bundleid: String, appdata: AppData) -> Package? {
    let packageList = getPackageList(appdata: appdata)
    if let package = packageList.first(where: { $0.bundleID == bundleid }) {
        return package
    }
    return nil
}

func downloadJSON(from url: URL, lowend: Bool) async throws -> Data {
    let config = URLSessionConfiguration.default
    if lowend {
        config.timeoutIntervalForRequest = 30
    }

    let session = URLSession(configuration: config)
    let (data, _) = try await session.data(from: url)
    return data
}

func getRepoInfo(_ repourl: String, appData: AppData, lowend: Bool = false) async -> Repo {
    let blankrepo: Repo = Repo(name: "Unknown", desc: "", url: URL(string: ""), icon: "", accent: nil, featured: [], packages: [], repotype: "unknown")
    
    guard let url = URL(string: repourl) else {
        return blankrepo
    }
    do {
        let data = try await downloadJSON(from: url, lowend: lowend)
        var repo: Repo = blankrepo
        let decoder = JSONDecoder()
        do {
            switch getRepoType(String(data: data, encoding: .utf8) ?? "") {
            case "purekfd":
                if !appData.UserData.filters.kfd {
                    var repodata = try decoder.decode(PureKFDRepo.self, from: data)
                    repodata.url = url.deletingLastPathComponent()
                    repo = translateToRepo(repoType: "PureKFD", repo: repodata) ?? blankrepo
                }
            case "misaka":
                if !appData.UserData.filters.kfd {
                    var repodata = try decoder.decode(MisakaRepo.self, from: data)
                    repodata.RepositoryURL = url.deletingLastPathComponent()
                    repo = translateToRepo(repoType: "misaka", repo: repodata) ?? blankrepo
                }
            case "picasso":
                if !appData.UserData.filters.kfd {
                    var repodata = try decoder.decode(PicassoRepo.self, from: data)
                    repodata.url = url.deletingLastPathComponent()
                    repo = translateToRepo(repoType: "picasso", repo: repodata) ?? blankrepo
                }
            case "altstore":
                if !appData.UserData.filters.ipa {
                    let repodata = try decoder.decode(AltstoreRepo.self, from: data)
                    repo = translateToRepo(repoType: "altstore", repo: repodata, repoURL: url) ?? blankrepo
                }
            case "esign":
                if !appData.UserData.filters.ipa {
                    let repodata = try decoder.decode(ESignRepo.self, from: data)
                    repo = translateToRepo(repoType: "esign", repo: repodata, repoURL: url) ?? blankrepo
                }
            case "scarlet":
                if !appData.UserData.filters.ipa {
                    let repodata = try decoder.decode(ScarletRepo.self, from: data)
                    repo = translateToRepo(repoType: "scarlet", repo: repodata, repoURL: url) ?? blankrepo
                }
            case "flux":
                if !appData.UserData.filters.shortcuts {
                    let repodata = try decoder.decode([String:FluxPkg].self, from: data)
                    repo = translateToRepo(repoType: "flux", repo: repodata, repoURL: url) ?? blankrepo
                }
            case "jb":
                if !appData.UserData.filters.jb {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: String(data: data, encoding: .utf8)?.toJSON() as Any, options: .prettyPrinted) {
                        let repodata = try decoder.decode(JBRepo.self, from: jsonData)
                        repo = translateToRepo(repoType: "jb", repo: repodata, repoURL: url.deletingLastPathComponent()) ?? blankrepo
                    }
                }
            case "cowabunga":
                if !appData.UserData.filters.kfd {
                    let repodata = try decoder.decode([CowabungaPkg].self, from: data)
                    repo = translateToRepo(repoType: "cowabunga", repo: repodata, repoURL: url) ?? blankrepo
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
        if !(repo.desc == "") {
            return repo
        }
    } catch {
        print("Error fetching or decoding JSON: \(error)")
        var repo = blankrepo
        repo.desc = "\(error.localizedDescription) (\(repourl))"
        repo.url = url.deletingLastPathComponent()
        return repo
    }
    return blankrepo
}

func getRepoType(_ jsonString: String) -> String {
    if jsonString.contains("longDesc"), jsonString.contains("shortDesc") {
        return "flux"
    } else if jsonString.contains("isLanZouCloud") {
        return "esign"
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
                } else if json["META"] is [String: String] {
                    return "scarlet"
                } else if json["identifier"] is String {
                    return "altstore"
                } else {
                    return "picasso"
                }
            } else if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                if ((json.first)?["contact"] != nil) {
                    return "cowabunga"
                }
            }
        } catch {
            return "unknown"
        }
    }
    return "invalid"
}
