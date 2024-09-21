//
//  RepoHandler.swift
//  purekfd
//
//  Created by Lrdsnow on 6/26/24.
//

import Foundation
import JASON
import Alamofire
//import UIKit

public class RepoHandler: ObservableObject {
    
    var cached_repo_urls: [URL]? = nil
    var repo_urls: [URL] {
        get {
            if let cached_repo_urls = cached_repo_urls {
                return cached_repo_urls
            } else if let urls = try? String(contentsOfFile: URL.documents.appendingPathComponent("repos.list").path, encoding: .utf8).components(separatedBy: "\n").compactMap({ URL(string: $0) }) {
                cached_repo_urls = urls
                return urls
            } else {
                let urls = [
                    // PureKFD/PureKFD Repos
                    URL(string: "https://raw.githubusercontent.com/Lrdsnow/PureKFDRepo/main/v6/repo.json")!, // PureKFD v6 Repo
                    URL(string: "https://raw.githubusercontent.com/PureKFD/PureKFDRepo/main/repo.json")!, // PureKFD v5 Repo
                    URL(string: "https://raw.githubusercontent.com/dora727/KaedeFriedDora/master/Essentials/manifest.json")!, // MeowRepo - Built for PureKFD v6
                    URL(string: "https://raw.githubusercontent.com/jailbreakdotparty/jailbreak.party-repo/refs/heads/main/v6/repo.json")!, // Jailbreak.party - Built for PureKFD v6
                    URL(string: "https://raw.githubusercontent.com/Dreel0akl/poopypoopermaybeworking/master/Essentials/manifest.json")!, // Poop Repo - Built for PureKFD
                    URL(string: "https://raw.githubusercontent.com/circularsprojects/circles-repo/main/purekfd.json")!, // Circular's Repo - Built for PureKFD
                    URL(string: "https://raw.githubusercontent.com/EPOS05/EPOSbox/main/purekfd.json")!, // EPOS Box - Built for PureKFD
                    URL(string: "https://raw.githubusercontent.com/34306/iPA/main/PureKFD/purekfd.json")!, // Huy's Repo - Built for PureKFD
                    URL(string: "https://raw.githubusercontent.com/HackZy01/aurora/main/purekfd.json")!, // Aurora - Built for PureKFD
                    URL(string: "https://raw.githubusercontent.com/YangJiiii/YangJiiii.github.io/main/file/Repo/purekfd.json")!, // YangJiii's Repo - Built for PureKFD
                    URL(string: "https://raw.githubusercontent.com/dobabaophuc1706/misakarepo/main/purekfd.json")!, // Phuc Do's Repo - Built for PureKFD
                    // Picasso Repos
                    URL(string: "https://raw.githubusercontent.com/sourcelocation/Picasso-test-repo/main/manifest.json")!, // Beta Picasso Repo
                    URL(string: "https://raw.githubusercontent.com/BomberFish/PicassoRepos/master/Essentials/manifest.json")!, // Main Picasso Repo
                    URL(string: "https://raw.githubusercontent.com/BomberFish/PicassoRepos/master/CabinFever/manifest.json")! // Cabin Fever
                ]
                try? String(urls.compactMap({ $0.absoluteString }).joined(separator: "\n")).write(to: URL.documents.appendingPathComponent("repos.list"), atomically: true, encoding: .utf8)
                cached_repo_urls = urls
                return urls
            }
        }
        set {
            cached_repo_urls = newValue
            try? String(newValue.compactMap({ $0.absoluteString }).joined(separator: "\n")).write(to: URL.documents.appendingPathComponent("repos.list"), atomically: true, encoding: .utf8)
        }
    }
    
    func updateRepos(_ appData: AppData) {
        for url in repo_urls {
            getRepo(url) { repo, error in
                if var repo = repo {
                    
                    var new_pkgs: [Package] = []
                    repo.packages.forEach({ pkg in
                        var temp_pkg = pkg
                        temp_pkg.feature = repo.featured?.first(where: { $0.bundleid == pkg.bundleid })
                        new_pkgs.append(temp_pkg)
                    })
                    repo.packages = new_pkgs
                    
                    if appData.filterPackages, ExploitHandler.exploits[appData.selectedExploit].varOnly {
                        var newpkgs: [Package] = []
                        repo.packages.forEach({ pkg in
                            if pkg.varonly != true {
                                var temp_pkg = pkg
                                temp_pkg.filtered = true
                                newpkgs.append(temp_pkg)
                            } else {
                                newpkgs.append(pkg)
                            }
                        })
                        repo.packages = newpkgs
                        if !repo.packages.contains(where: { $0.filtered != true }) {
                            repo.filtered = true
                            appData.repos.append(repo)
                            return // Skip to next repo
                        }
                    }

                    if let index = appData.repos.firstIndex(where: { $0.fullURL == url }) {
                        appData.repos[index] = repo
                    } else {
                        appData.repos.append(repo)
                    }
                    
                    appData.repos = Array(Set(appData.repos))
                    appData.pkgs = appData.repos.flatMap { $0.packages }
                    appData.featured = appData.repos.flatMap { $0.featured ?? [] }
                }
            }
        }
    }
    
    func getRepo(_ url: URL, completion: @escaping (Repo?, Error?) -> Void) {
        AF.request(url).responseJASON { response in
            switch response.result {
            case .success(let json):
                completion(Repo(json, url), nil)
            case .failure(let error):
                completion(Repo(error, url), error)
            }
        }
    }
    
    func addRepo(_ url: URL, _ appData: AppData) {
        var urls = repo_urls
        urls.append(url)
        cached_repo_urls = urls
        do {
            try String(urls.compactMap({ $0.absoluteString }).joined(separator: "\n")).write(to: URL.documents.appendingPathComponent("repos.list"), atomically: true, encoding: .utf8)
        } catch { print(error) }
        updateRepos(appData)
    }
    
    func removeRepo(_ url: URL, _ appData: AppData) {
        var urls = repo_urls
        urls.removeAll(where: { $0 == url })
        appData.repos.removeAll(where: { $0.fullURL == url })
        cached_repo_urls = urls
        try? String(urls.compactMap({ $0.absoluteString }).joined(separator: "\n")).write(to: URL.documents.appendingPathComponent("repos.list"), atomically: true, encoding: .utf8)
        updateRepos(appData)
    }
}

func updateInstalledTweaks(_ appData: AppData) {
    let pkgs_dir = URL.documents.appendingPathComponent("pkgs")
    let fm = FileManager.default
    do {
        for tweak in try fm.contentsOfDirectory(atPath: pkgs_dir.path) {
            print(pkgs_dir.path)
            if !appData.installed_pkgs.contains(where: { $0.bundleid == tweak }) {
                do {
                    appData.installed_pkgs.append(try JSONDecoder().decode(Package.self, from: Data(contentsOf: pkgs_dir.appendingPathComponent("\(tweak)/_info.json"))))
                } catch {
                    appData.installed_pkgs.append(
                        Package(["bundleid":tweak,"error":"Error decoding tweak"], nil, nil)
                    )
                }
            }
        }
    } catch {}
}
