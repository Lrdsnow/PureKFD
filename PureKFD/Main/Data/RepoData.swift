//
//  RepoData.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import Foundation

// Generic Data

struct Repo: Codable, Identifiable {
    let id = UUID()
    // Repo Info
    let name: String
    var desc: String
    var url: URL?
    let icon: String
    var categorized: Bool = true
    let accent: String?
    var featured: [Featured]?
    var packages: [Package]
    // Repo Data
    let repotype: String // Can be "PureKFD", "legacyencrypted" or "picasso"
}

struct Package: Codable, Identifiable {
    let id = UUID()
    // Package Info
    var name: String
    var bundleID: String
    var author: String
    var version: String?
    let desc: String
    let longdesc: String?
    var icon: URL?
    let accent: String?
    let screenshots: [URL?]?
    let banner: URL?
    let previewbg: URL?
    let category: String
    var beta: Bool = false
    // Install Values:
    var path: URL?
    var installtype: String?
    var versions: [String:String]?
    let install_actions: [String]?
    let uninstall_actions: [String]?
    // Repo Values:
    let url: URL?
    var repo: Repo?
    // Installed values
    var disabled: Bool?
    var hasprefs: Bool?
    // Package Data
    var pkgtype: String // Can be "PureKFD", "legacyencrypted" or "picasso"
//    let PureKFD: PureKFDPkg?
//    let legacyencrypted: LegacyEncryptedPkg?
//    let picasso: PicassoPkg?
}

struct Featured: Codable {
     let name: String
     let bundleid: String
     var banner: String
     let fontcolor: String?
     let showname: Bool?
     let square: Bool?
}

// PureKFD

struct PureKFDPkg: Codable {
     let name: String
     let bundleid: String
     let author: String
     let description: String?
     let long_description: String?
     let version: String
     let accent: String?
     let category: String?
     let icon: String
     let screenshots: [URL?]?
     let banner: String?
     let path: String
     let installtype: String?
 }

struct PureKFDRepo: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let accent: String?
    var featured: [Featured]?
    let packages: [PureKFDPkg]
    var url: URL?
}

// Picasso

struct PicassoPkg: Codable {
     let name: String
     let bundleid: String
     let author: String
     let description: String?
     let version: String
     let icon: String
     let path: String
 }

struct PicassoRepo: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let featured: [Featured]?
    let packages: [PicassoPkg]
    var url: URL?
}

// JB
struct JBRepo: Codable {
    let Origin: String?
    let Label: String?
    let Version: String?
    let Codename: String?
    let Architectures: String?
    let Components: String?
    let Description: String?
    let MD5Sum: String?
}

// Translators

func translateToPackage(pkgType: String, package: Any, repourl: URL? = URL(string: ""), installtype: String? = nil) -> Package? {
    let blacklisted = ["ca.bomberfish.DynamicIsland"]
    switch pkgType {
    case "PureKFD":
        if let PureKFDPackage = package as? PureKFDPkg {
            if blacklisted.contains(PureKFDPackage.bundleid) {
                return nil
            }
            let screenshotsWithRepoURL: [URL?]?
            if let screenshots = PureKFDPackage.screenshots {
                screenshotsWithRepoURL = screenshots.map { screenshotURL in
                    if let screenshotURL = screenshotURL {
                        return URL(string: repourl?.absoluteString ?? "")?.appendingPathComponent(screenshotURL.absoluteString)
                    } else {
                        return nil
                    }
                }
            } else {
                screenshotsWithRepoURL = nil
            }
            
            return Package(name: PureKFDPackage.name,
                           bundleID: PureKFDPackage.bundleid,
                           author: PureKFDPackage.author,
                           version: PureKFDPackage.version,
                           desc: PureKFDPackage.description ?? "",
                           longdesc: PureKFDPackage.long_description ?? "",
                           icon: URL(string: String(String(repourl?.absoluteString ?? "") + PureKFDPackage.icon)),
                           accent: PureKFDPackage.accent,
                           screenshots: screenshotsWithRepoURL,
                           banner: URL(string: String(String(repourl?.absoluteString ?? "") + (PureKFDPackage.banner ?? ""))),
                           previewbg: nil,
                           category: PureKFDPackage.category ?? "Misc",
                           path: URL(string: String(String(repourl?.absoluteString ?? "") + PureKFDPackage.path)),
                           installtype: PureKFDPackage.installtype ?? "kfd",
                           install_actions: [],
                           uninstall_actions: [],
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType)
        }
    case "picasso":
        if let picassoPackage = package as? PicassoPkg {
            if blacklisted.contains(picassoPackage.bundleid) {
                return nil
            }
            return Package(name: picassoPackage.name,
                           bundleID: picassoPackage.bundleid,
                           author: picassoPackage.author,
                           version: picassoPackage.version,
                           desc: picassoPackage.description ?? "",
                           longdesc: nil,
                           icon: URL(string: String(String(repourl?.absoluteString ?? "") + picassoPackage.icon)),
                           accent: nil,
                           screenshots: nil,
                           banner: nil, 
                           previewbg: nil, 
                           category: "Picasso",
                           path: URL(string: String(String(repourl?.absoluteString ?? "") + picassoPackage.path)),
                           installtype: "kfd",
                           install_actions: [],
                           uninstall_actions: [],
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType)
        }
    case "jb":
        if let jbPkg = package as? [String:String] {
            return Package(name: jbPkg["Name"] ?? "",
                           bundleID: jbPkg["Package"] ?? "",
                           author: jbPkg["Author"] ?? "",
                           version: jbPkg["Version"] ?? "",
                           desc: jbPkg["Description"] ?? "",
                           longdesc: nil,
                           icon: URL(string: jbPkg["Icon"] ?? "none"),
                           accent: nil,
                           screenshots: nil,
                           banner: nil,
                           previewbg: nil,
                           category: "Misc",
                           path: repourl?.appendingPathComponent(jbPkg["Filename"] ?? ""),
                           installtype: "unknown",
                           install_actions: [],
                           uninstall_actions: [],
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType)
        }
    default:
        return nil
    }
    return nil
}

func translateToRepo(repoType: String, repo: Any, repoURL: URL? = URL(string: "")) -> Repo? {
    switch repoType {
    case "PureKFD":
        if let PureKFDRepo = repo as? PureKFDRepo {
            var translatedPackages = [Package]()
            for pkg in PureKFDRepo.packages {
                if let translatedPackage = translateToPackage(pkgType: "PureKFD", package: pkg, repourl: PureKFDRepo.url) {
                    translatedPackages.append(translatedPackage)
                }
            }
            var repofeatured: [Featured] = []
            if var featured = PureKFDRepo.featured {
                for index in 0..<featured.count {
                    if var pkg = featured[index] as? Featured {
                        pkg.banner = String((PureKFDRepo.url?.absoluteString ?? "") + pkg.banner)
                        featured[index] = pkg
                    }
                }
                repofeatured = featured
            }
            return Repo(name: PureKFDRepo.name,
                            desc: PureKFDRepo.description,
                            url: PureKFDRepo.url,
                            icon: String((PureKFDRepo.url?.absoluteString ?? "") + PureKFDRepo.icon),
                            accent: PureKFDRepo.accent,
                            featured: repofeatured,
                            packages: translatedPackages,
                            repotype: repoType)
        }
    case "picasso":
        if let picassoRepo = repo as? PicassoRepo {
            var translatedPackages = [Package]()
            for pkg in picassoRepo.packages {
                if let translatedPackage = translateToPackage(pkgType: "picasso", package: pkg, repourl: picassoRepo.url) {
                    translatedPackages.append(translatedPackage)
                }
            }
            return Repo(name: picassoRepo.name,
                        desc: picassoRepo.description,
                        url: picassoRepo.url,
                        icon: String((picassoRepo.url?.absoluteString ?? "") + picassoRepo.icon),
                        accent: nil,
                        featured: picassoRepo.featured,
                        packages: translatedPackages,
                        repotype: repoType)
        }
    case "jb":
        if let jbRepo = repo as? JBRepo {
            var translatedPackages = [Package]()
            let jbPkgsURL = repoURL?.appendingPathComponent("Packages") ?? URL(fileURLWithPath: "none")
            var jbPkgsData = Data()
            do {try jbPkgsData = Data(contentsOf: jbPkgsURL)} catch {}
            let jbPkgsString = String(data: jbPkgsData, encoding: .utf8) ?? ""
            for pkg in jbPkgsString.toJSONArray() {
                if let translatedPackage = translateToPackage(pkgType: "jb", package: pkg, repourl: jbPkgsURL) {
                    translatedPackages.append(translatedPackage)
                }
            }
            let repoIcon = repoURL?.appendingPathComponent("CydiaIcon.png").absoluteString ?? ""
            return Repo(name: jbRepo.Origin ?? "JB Repo",
                        desc: jbRepo.Description ?? "JB Repo Desc",
                        url: repoURL,
                        icon: repoIcon,
                        accent: nil,
                        featured: nil,
                        packages: translatedPackages,
                        repotype: repoType)
        }
    default:
        return nil
    }
    return nil
}
