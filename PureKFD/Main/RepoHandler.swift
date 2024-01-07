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

func updateTweakJSON(jsonURL: URL) -> Package? {
    var package: Package? = nil
    
    do {
        let jsonData = try Data(contentsOf: jsonURL)
        if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            package = Package(name: json["name"] as? String ?? "",
                              bundleID: json["bundleID"] as? String ?? "",
                              author: json["author"] as? String ?? "Unknown Author",
                              version: json["version"] as? String ?? "",
                              desc: json["desc"] as? String ?? "",
                              longdesc: json["longdesc"] as? String ?? nil,
                              icon: URL(string: json["icon"] as? String ?? ""),
                              accent: json["accent"] as? String ?? nil,
                              screenshots: (json["screenshots"] as? [String])?.map { urlString in
                                URL(string: urlString)
                              } ?? nil,
                              banner: URL(string: json["banner"] as? String ?? ""),
                              previewbg: URL(string: json["previewbg"] as? String ?? ""),
                              category: json["category"] as? String ?? "Misc",
                              path: URL(string: json["path"] as? String ?? ""),
                              install_actions: json["install_actions"] as? [String]? ?? nil,
                              uninstall_actions: json["uninstall_actions"] as? [String]? ?? nil,
                              url: URL(string: json["url"] as? String ?? ""),
                              disabled: json["disabled"] as? Bool ?? false,
                              hasprefs: json["hasprefs"] as? Bool ?? false,
                              pkgtype: json["pkgtype"] as? String ?? "")
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(package)
                try jsonData.write(to: jsonURL)
            } catch {
                log("Error encoding struct to JSON: \(error)")
            }
        } else {
            log("Invalid Tweak JSON at path \(jsonURL.path)")
        }
    } catch {
        return nil
    }
    
    return package
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
                    do {
                        let jsonData = try Data(contentsOf: itemURL.appendingPathComponent("info.json"))
                        let decoder = JSONDecoder()
                        let package = try decoder.decode(Package.self, from: jsonData)
                        packages.append(package)
                    } catch {
                        if let package = updateTweakJSON(jsonURL: itemURL.appendingPathComponent("info.json")) {
                            packages.append(package)
                        } else {
                            log("bad tweak at path \(itemURL.path)")
                        }
                    }
                }
            }
        } catch {
            NSLog("Error while processing folder: %@", error.localizedDescription)
        }
    }
    
    return packages
}

func getAllRepos(appdata: AppData) async -> [Repo] {
    var repourls = SavedRepoData()
    repourls.urls += appdata.RepoData.urls
    
    var repos: [Repo] = []
    
    await withTaskGroup(of: Repo?.self) { group in
        for url in repourls.urls {
            group.addTask {
                if let repoInfo = try? await getRepoInfo(url.absoluteString, appData: appdata) {
                    return repoInfo
                }
                return nil
            }
        }
        
        for await result in group {
            if let result = result {
                repos.append(result)
            }
        }
    }
    
    let uniqueRepos = repos.filter { repo in
        let isUnique = !repos.contains(where: { $0.url == repo.url }) // Assuming 'url' is the property representing the repository URL
        return isUnique
    }
    
    return uniqueRepos
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

func applyBeta(_ beta: Repo, _ rel: Repo) -> Repo {
    var ret = beta
    var beta_ids: [String] = []
    var featured_beta_ids: [String] = []
    
    for index in ret.packages.indices {
        let pkg = ret.packages[index]
        if !beta_ids.contains(pkg.bundleID) {
            ret.packages[index].beta = true
            beta_ids.append(pkg.bundleID)
        }
    }
    
    for index in rel.packages.indices {
        let pkg = rel.packages[index]
        if !beta_ids.contains(pkg.bundleID) {
            ret.packages.append(pkg)
        }
    }
    
    if let featured = ret.featured {
        for index in featured.indices {
            let pkg = featured[index]
            if !featured_beta_ids.contains(pkg.bundleid) {
                featured_beta_ids.append(pkg.bundleid)
            }
        }
    }
    
    if let featured = rel.featured {
        for index in featured.indices {
            let pkg = featured[index]
            if !featured_beta_ids.contains(pkg.bundleid) {
                ret.featured = ret.featured ?? []
                ret.featured!.append(pkg)
            }
        }
    }
    
    return ret
}

func getRepoInfo(_ repourl: String, appData: AppData, usedata: Data? = nil, lowend: Bool = false) async -> Repo {
    let blankrepo: Repo = Repo(name: "Unknown", desc: "", url: URL(string: ""), icon: "", accent: nil, featured: [], packages: [], repotype: "unknown")
    
    guard let url = URL(string: repourl) else {
        return blankrepo
    }
    do {
        let data = usedata == nil ? try await downloadJSON(from: url, lowend: lowend) : usedata!
        var repo: Repo = blankrepo
        let decoder = JSONDecoder()
        do {
            switch getRepoType(String(data: data, encoding: .utf8) ?? "") {
            case "bridge":
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if appData.UserData.betaRepos {
                        if var betarepo = json["beta"] as? String {
                            if !betarepo.starts(with: "http") {
                                betarepo = "\(url.deletingLastPathComponent())" + betarepo
                            }
                            let betaRepo = await getRepoInfo(betarepo, appData: appData)
                            if var releaserepo = json["release"] as? String {
                                if !releaserepo.starts(with: "http") {
                                    releaserepo = "\(url.deletingLastPathComponent())" + releaserepo
                                }
                                let releaseRepo = await getRepoInfo(releaserepo, appData: appData)
                                return applyBeta(betaRepo, releaseRepo)
                            }
                            return betaRepo
                        }
                    } else {
                        if var releaserepo = json["release"] as? String {
                            if !releaserepo.starts(with: "http") {
                                releaserepo = "\(url.deletingLastPathComponent())" + releaserepo
                            }
                            return await getRepoInfo(releaserepo, appData: appData)
                        }
                    }
                }
            case "purekfd":
                if !appData.UserData.filters.kfd {
                    var repodata = try decoder.decode(PureKFDRepo.self, from: data)
                    repodata.url = url.deletingLastPathComponent()
                    repo = translateToRepo(repoType: "PureKFD", repo: repodata) ?? blankrepo
                }
            case "legacyencrypted":
                if !appData.UserData.filters.kfd {
                    var repodata = try decoder.decode(LegacyEncryptedRepo.self, from: data)
                    repodata.RepositoryURL = url.deletingLastPathComponent()
                    repo = translateToRepo(repoType: "legacyencrypted", repo: repodata) ?? blankrepo
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
            log("Error decoding JSON: %@", "\(error)")
            repo.desc = "Error Decoding JSON (\(url))"
            repo.url = url.deletingLastPathComponent()
        }
        if !(repo.desc == "") {
            return repo
        }
    } catch {
        log("Error fetching or decoding JSON: %@", "\(error)")
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
                    return "legacyencrypted"
                } else if json["META"] is [String: String] {
                    return "scarlet"
                } else if json["identifier"] is String {
                    return "altstore"
                } else if (json["info"] as? String ?? "") == "purekfdbridge" {
                    return "bridge"
                } else {
                    return "picasso"
                }
            } else if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                if ((json.first)?["contact"] != nil) {
                    return "cowabunga"
                }
            }
        } catch {
            log("\n\n\nERROR:")
            log(error.localizedDescription)
            log("-----\n\n\n")
            return "unknown"
        }
    }
    return "invalid"
}

func getCachedRepos() -> [Repo] {
    let folderPath = URL.documents.appendingPathComponent("config/repoCache")
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        var repos: [Repo] = []
        for fileURL in fileURLs {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            do {
                let repo = try decoder.decode(Repo.self, from: data)
                repos.append(repo)
            } catch {
                log("failed to decode repo at \(fileURL.path.components(separatedBy: "/").last ?? "nil")")
            }
        }
        return repos
    } catch {
        log("Error reading JSON files: \(error)")
        return []
    }
}
