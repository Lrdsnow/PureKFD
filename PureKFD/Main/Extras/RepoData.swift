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
    let accent: String?
    let featured: [Featured]?
    var packages: [Package]
    // Repo Data
    let repotype: String // Can be "purekfd", "misaka" or "picasso"
    let purekfd: PureKFDRepo?
    let misaka: MisakaRepo?
    let picasso: PicassoRepo?
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
    // Install Values:
    var path: URL?
    var installtype: String?
    var versions: [String:String]?
    // Repo Values:
    let url: URL?
    var repo: Repo?
    // Installed values
    var disabled: Bool?
    var hasprefs: Bool?
    // Package Data
    var pkgtype: String // Can be "purekfd", "misaka" or "picasso"
    let purekfd: PureKFDPkg?
    let misaka: MisakaPkg?
    let picasso: PicassoPkg?
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
     let icon: String
     let screenshots: [URL?]?
     let banner: String?
     let path: String
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

// Misaka


struct MisakaRepo: Codable, Identifiable {
    let id = UUID()
    let RepositoryName: String
    let RepositoryDescription: String
    let RepositoryAuthor: String
    let RepositoryIcon: String
    let RepositoryWebsite: String?
    let RepositoryAccent: String?
    var RepositoryURL: URL?
    let DefaultHeaderImage: String?
    let featured: [Featured]?
    let RepositoryContents: [MisakaPkg]
    let packages: [PureKFDPkg]?
}


struct MisakaPkg: Codable, Identifiable {
    let id = UUID()
    let Name: String
    let Description: String?
    let MinIOSVersion: String?
    let MaxIOSVersion: String?
    let Author: MisakaAuthor?
    let Icon: String?
    let HeaderImage: String?
    let Category: String?
    let Caption: String?
    let Screenshot: [String]?
    let accent: String?
    let Releases: [MisakaRelease]?
    let PackageID: String?
}

struct MisakaAuthor: Codable {
    let Label: String?
    let Links: [MisakaLink]?
}

struct MisakaLink: Codable {
    let Label: String?
    let Link: String?
}

struct MisakaRelease: Codable {
    let Version: String?
    let Package: String?
    let Description: String?
}

// Flux kms
struct FluxPkg: Codable {
    let shortDesc: String?
    let link: String?
    let author: String?
    let categories: String?
    let preview: String?
    let longDesc: String?
    let b64icon: String?
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

func translateToPackage(pkgType: String, package: Any, repourl: URL? = URL(string: "")) -> Package? {
    let blacklisted = ["ca.bomberfish.DynamicIsland"]
    switch pkgType {
    case "purekfd":
        if let purekfdPackage = package as? PureKFDPkg {
            if blacklisted.contains(purekfdPackage.bundleid) {
                return nil
            }
            let screenshotsWithRepoURL: [URL?]?
            if let screenshots = purekfdPackage.screenshots {
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
            
            return Package(name: purekfdPackage.name,
                           bundleID: purekfdPackage.bundleid,
                           author: purekfdPackage.author,
                           version: purekfdPackage.version,
                           desc: purekfdPackage.description ?? "",
                           longdesc: purekfdPackage.long_description ?? "",
                           icon: URL(string: String(String(repourl?.absoluteString ?? "") + purekfdPackage.icon)),
                           accent: purekfdPackage.accent,
                           screenshots: screenshotsWithRepoURL,
                           banner: URL(string: String(String(repourl?.absoluteString ?? "") + (purekfdPackage.banner ?? ""))),
                           previewbg: nil,
                           path: URL(string: String(String(repourl?.absoluteString ?? "") + purekfdPackage.path)),
                           installtype: "kfd",
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType,
                           purekfd: purekfdPackage,
                           misaka: nil,
                           picasso: nil)
        }
    case "misaka":
        if let misakaPackage = package as? MisakaPkg {
            if blacklisted.contains(misakaPackage.PackageID ?? "nil") {
                return nil
            }
            return Package(name: misakaPackage.Name,
                           bundleID: misakaPackage.PackageID ?? "",
                           author: misakaPackage.Author?.Label ?? "Unknown Author",
                           version: misakaPackage.Releases?[0].Version,
                           desc: misakaPackage.Description ?? "",
                           longdesc: misakaPackage.Caption ?? "",
                           icon: URL(string: misakaPackage.Icon ?? ""),
                           accent: misakaPackage.accent,
                           screenshots: misakaPackage.Screenshot?.compactMap { URL(string: $0) },
                           banner: URL(string: misakaPackage.HeaderImage ?? ""), 
                           previewbg: nil,
                           path: URL(string: misakaPackage.Releases!.first?.Package ?? ""),
                           installtype: "kfd",
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType,
                           purekfd: nil,
                           misaka: misakaPackage,
                           picasso: nil)
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
                           path: URL(string: String(String(repourl?.absoluteString ?? "") + picassoPackage.path)),
                           installtype: "kfd",
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType,
                           purekfd: nil,
                           misaka: nil,
                           picasso: picassoPackage)
        }
    case "flux":
        if let fluxPackage = package as? (String,FluxPkg) {
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let uniqueFilename = UUID().uuidString
            let tempFileURL = tempDirectoryURL.appendingPathComponent(uniqueFilename)
            do {
                let imageData = Data(base64Encoded: fluxPackage.1.b64icon ?? "")
                try imageData?.write(to: tempFileURL)
            } catch {}
            return Package(name: fluxPackage.0,
                           bundleID: "\(UUID())",
                           author: fluxPackage.1.author ?? "",
                           version: "1.0",
                           desc: fluxPackage.1.shortDesc ?? "",
                           longdesc: fluxPackage.1.longDesc ?? "",
                           icon: tempFileURL,
                           accent: nil,
                           screenshots: [URL(string: fluxPackage.1.preview ?? "")],
                           banner: nil,
                           previewbg: nil,
                           path: URL(string: fluxPackage.1.link ?? ""),
                           installtype: "shortcut",
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType,
                           purekfd: nil,
                           misaka: nil,
                           picasso: nil)
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
                           path: repourl?.appendingPathComponent(jbPkg["Filename"] ?? ""),
                           installtype: "jb", 
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType,
                           purekfd: nil,
                           misaka: nil,
                           picasso: nil)
        }
    default:
        return nil
    }
    return nil
}

func translateToRepo(repoType: String, repo: Any, repoURL: URL? = URL(string: "")) -> Repo? {
    switch repoType {
    case "purekfd":
        if let purekfdRepo = repo as? PureKFDRepo {
            var translatedPackages = [Package]()
            for pkg in purekfdRepo.packages {
                if let translatedPackage = translateToPackage(pkgType: "purekfd", package: pkg, repourl: purekfdRepo.url) {
                    translatedPackages.append(translatedPackage)
                }
            }
            var repofeatured: [Featured] = []
            if var featured = purekfdRepo.featured {
                for index in 0..<featured.count {
                    if var pkg = featured[index] as? Featured {
                        pkg.banner = String((purekfdRepo.url?.absoluteString ?? "") + pkg.banner)
                        featured[index] = pkg
                    }
                }
                repofeatured = featured
            }
            return Repo(name: purekfdRepo.name,
                            desc: purekfdRepo.description,
                            url: purekfdRepo.url,
                            icon: String((purekfdRepo.url?.absoluteString ?? "") + purekfdRepo.icon),
                            accent: purekfdRepo.accent,
                            featured: repofeatured,
                            packages: translatedPackages,
                            repotype: repoType,
                            purekfd: purekfdRepo,
                            misaka: nil,
                            picasso: nil)
        }
    case "misaka":
        if let misakaRepo = repo as? MisakaRepo {
            var translatedPackages = [Package]()
            for pkg in misakaRepo.RepositoryContents {
                if let translatedPackage = translateToPackage(pkgType: "misaka", package: pkg) {
                    translatedPackages.append(translatedPackage)
                }
            }
            if misakaRepo.packages != nil {
                for pkg in misakaRepo.packages! {
                    if let translatedPackage = translateToPackage(pkgType: "purekfd", package: pkg, repourl: misakaRepo.RepositoryURL) {
                        translatedPackages.append(translatedPackage)
                    }
                }
            }
            return Repo(name: misakaRepo.RepositoryName,
                        desc: misakaRepo.RepositoryDescription,
                        url: misakaRepo.RepositoryURL,
                        icon: misakaRepo.RepositoryIcon,
                        accent: misakaRepo.RepositoryAccent,
                        featured: misakaRepo.featured,
                        packages: translatedPackages,
                        repotype: repoType,
                        purekfd: nil,
                        misaka: misakaRepo,
                        picasso: nil)
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
                        repotype: repoType,
                        purekfd: nil,
                        misaka: nil,
                        picasso: picassoRepo)
        }
    case "flux":
        if let fluxRepo = repo as? [String:FluxPkg] {
            var translatedPackages = [Package]()
            for pkg in fluxRepo {
                if let translatedPackage = translateToPackage(pkgType: "flux", package: pkg, repourl: nil) {
                    translatedPackages.append(translatedPackage)
                }
            }
            return Repo(name: "Flux Repo",
                        desc: repoURL?.absoluteString ?? "Unknown Flux Repo",
                        url: repoURL,
                        icon: "none",
                        accent: nil,
                        featured: nil,
                        packages: translatedPackages,
                        repotype: repoType,
                        purekfd: nil,
                        misaka: nil,
                        picasso: nil)
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
                        repotype: repoType,
                        purekfd: nil,
                        misaka: nil,
                        picasso: nil)
        }
    default:
        return nil
    }
    return nil
}
