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
    let repotype: String // Can be "PureKFD", "misaka" or "picasso"
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
    let install_actions: [String]?
    let uninstall_actions: [String]?
    // Repo Values:
    let url: URL?
    var repo: Repo?
    // Installed values
    var disabled: Bool?
    var hasprefs: Bool?
    // Package Data
    var pkgtype: String // Can be "PureKFD", "misaka" or "picasso"
//    let PureKFD: PureKFDPkg?
//    let misaka: MisakaPkg?
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
    let icon: String?
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

// Cow
struct CowabungaPkg: Codable {
    let name: String
    let identification: String?
    let description: String
    let url: String
    let preview: String
    let version: String
}

// Altstore
struct AltstoreRepo: Codable {
    let name: String?
    let identifier: String?
    let subtitle: String?
    let iconURL: String?
    let website: String?
    let sourceURL: String?
    let featuredApps: [String]?
    let apps: [AltstoreApp]?
}

struct AltstoreApp: Codable {
    let name: String
    let bundleIdentifier: String
    let developerName: String?
    let version: String?
    let versionDate: String?
    let downloadURL: String?
    let localizedDescription: String?
    let iconURL: String?
    let tintColor: String?
    let size: Int?
    let screenshotURLs: [String]?
}

// ESign
struct ESignRepo: Codable {
    let name: String?
    let identifier: String?
    let sourceURL: String?
    let apps: [ESignApp]?
}

struct ESignApp: Codable {
    let name: String
    let version: String?
    let versionDate: String?
    let versionDescription: String?
    let downloadURL: String?
    let iconURL: String?
    let size: Int?
}

// Scarlet
struct ScarletRepo: Codable {
    let META: ScarletMeta
    let Tweaked: [ScarletApp]?
    let Macdirtycow: [ScarletApp]?
    let Sideloaded: [ScarletApp]?
}

struct ScarletMeta: Codable {
    let repoName: String
    let repoIcon: String?
}

struct ScarletApp: Codable {
    let name: String?
    let version: String?
    let icon: String?
    let down: String?
    let dev: String?
    let downloadURL: String?
    let category: String?
    let description: String?
    let bundleID: String?
    let appstore: String?
    let enableBackup: Bool?
    let screenshots: [String]?
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
                           path: URL(string: String(String(repourl?.absoluteString ?? "") + PureKFDPackage.path)),
                           installtype: PureKFDPackage.installtype ?? "kfd",
                           install_actions: [],
                           uninstall_actions: [],
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType)
        }
    case "misaka":
        if let misakaPackage = package as? MisakaPkg {
            if blacklisted.contains(misakaPackage.PackageID ?? "nil") {
                return nil
            }
            
            var versionsDictionary = [String: String]()
            if let releases = misakaPackage.Releases {
                for release in releases {
                    if let version = release.Version, let packageName = release.Package {
                        versionsDictionary[version] = packageName
                    }
                }
            }
            let sortedVersions = versionsDictionary.keys.sorted { (version1, version2) -> Bool in
                return version1.compare(version2, options: .numeric) == .orderedDescending
            }
            let sortedVersionsDictionary = versionsDictionary.filter { sortedVersions.contains($0.key) }
            
            return Package(name: misakaPackage.Name,
                           bundleID: misakaPackage.PackageID ?? "",
                           author: misakaPackage.Author?.Label ?? "Unknown Author",
                           version: sortedVersionsDictionary.keys.first,
                           desc: misakaPackage.Description ?? "",
                           longdesc: misakaPackage.Caption ?? "",
                           icon: URL(string: misakaPackage.Icon ?? ""),
                           accent: misakaPackage.accent,
                           screenshots: misakaPackage.Screenshot?.compactMap { URL(string: $0) },
                           banner: URL(string: misakaPackage.HeaderImage ?? ""), 
                           previewbg: nil,
                           path: URL(string: sortedVersionsDictionary.values.first ?? ""),
                           installtype: "kfd",
                           versions: sortedVersionsDictionary,
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
                           path: URL(string: String(String(repourl?.absoluteString ?? "") + picassoPackage.path)),
                           installtype: "kfd",
                           install_actions: [],
                           uninstall_actions: [],
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType)
        }
    case "flux":
        if let fluxPackage = package as? (String,FluxPkg) {
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let uniqueFilename = UUID().uuidString
            let tempFileURL = tempDirectoryURL.appendingPathComponent(uniqueFilename)
            do {
                let imageData = Data(base64Encoded: fluxPackage.1.b64icon ?? fluxPackage.1.icon ?? "")
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
                           path: repourl?.appendingPathComponent(jbPkg["Filename"] ?? ""),
                           installtype: "unknown",
                           install_actions: [],
                           uninstall_actions: [],
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType)
        }
    case "cowabunga":
        if let cowabungaPackage = package as? CowabungaPkg {
            return Package(name: cowabungaPackage.name,
                           bundleID: "\(UUID())",
                           author: "Unknown Author",
                           version: cowabungaPackage.version,
                           desc: cowabungaPackage.description ?? "",
                           longdesc: nil,
                           icon: URL(string: String(String(repourl?.absoluteString ?? "") + cowabungaPackage.preview)),
                           accent: nil,
                           screenshots: nil,
                           banner: nil,
                           previewbg: nil,
                           path: URL(string: String(String(repourl?.absoluteString ?? "") + cowabungaPackage.url)),
                           installtype: installtype ?? "unknown",
                           install_actions: [],
                           uninstall_actions: [],
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType)
        }
    case "altstore":
        if let altstoreApp = package as? AltstoreApp {
            return Package(name: altstoreApp.name,
                           bundleID: altstoreApp.bundleIdentifier,
                           author: altstoreApp.developerName ?? "Unknown Author",
                           version: altstoreApp.version,
                           desc: altstoreApp.localizedDescription ?? "",
                           longdesc: nil,
                           icon: URL(string: altstoreApp.iconURL ?? "none"),
                           accent: altstoreApp.tintColor,
                           screenshots: altstoreApp.screenshotURLs?.compactMap { URL(string: $0) },
                           banner: nil,
                           previewbg: nil,
                           path: URL(string: altstoreApp.downloadURL ?? "none"),
                           installtype: "ipa",
                           install_actions: [],
                           uninstall_actions: [],
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType)
        }
    case "esign":
        if let esignApp = package as? ESignApp {
            return Package(name: esignApp.name,
                           bundleID: "\(UUID())",
                           author: "Unknown Author",
                           version: esignApp.version,
                           desc: esignApp.versionDescription ?? "",
                           longdesc: nil,
                           icon: URL(string: esignApp.iconURL ?? "none"),
                           accent: nil,
                           screenshots: [],
                           banner: nil,
                           previewbg: nil,
                           path: URL(string: esignApp.downloadURL ?? "none"),
                           installtype: "ipa",
                           install_actions: [],
                           uninstall_actions: [],
                           url: repourl,
                           repo: nil,
                           pkgtype: pkgType)
        }
    case "scarlet":
        if let scarletApp = package as? ScarletApp {
            return Package(name: scarletApp.name ?? "",
                           bundleID: scarletApp.bundleID ?? "\(UUID())",
                           author: scarletApp.dev ?? "Unknown Author",
                           version: scarletApp.version,
                           desc: scarletApp.description ?? "",
                           longdesc: nil,
                           icon: URL(string: scarletApp.icon ?? "none"),
                           accent: nil,
                           screenshots: scarletApp.screenshots?.compactMap { URL(string: $0) },
                           banner: nil,
                           previewbg: nil,
                           path: URL(string: scarletApp.down ?? "none"),
                           installtype: "ipa",
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
                    if let translatedPackage = translateToPackage(pkgType: "PureKFD", package: pkg, repourl: misakaRepo.RepositoryURL) {
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
    case "flux":
        if let fluxRepo = repo as? [String:FluxPkg] {
            var translatedPackages = [Package]()
            for pkg in fluxRepo {
                if let translatedPackage = translateToPackage(pkgType: "flux", package: pkg, repourl: nil) {
                    translatedPackages.append(translatedPackage)
                }
            }
            return Repo(name: "Flux Repo",
                        desc: "Flux Repo Desc",
                        url: repoURL,
                        icon: "https://github.com/Broco8Dev/Flux/raw/main/icon.png?raw=true",
                        accent: nil,
                        featured: nil,
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
    case "cowabunga":
        if let cowRepo = repo as? [CowabungaPkg] {
            var name = "Cowabunga Repo"
            var desc = repoURL?.absoluteString ?? "Unknown Cowabunga Repo"
            var installtype = "unknown"
            if repoURL != nil {
                if repoURL!.absoluteString.contains("cc-themes.json") {
                    name = "Cowabunga Control Center Themes"
                    desc = "Control Center Themes from Cowabunga!"
                } else if repoURL!.absoluteString.contains("icon-themes.json") {
                    name = "Cowabunga Icon Themes"
                    desc = "Icon Packs from Cowabunga!"
                } else if repoURL!.absoluteString.contains("lock-themes.json") {
                    name = "Cowabunga Lock Themes"
                    desc = "Lock's from Cowabunga!"
                    installtype = "cowlock"
                } else if repoURL!.absoluteString.contains("passcode-themes.json") {
                    name = "Cowabunga Passcode Themes"
                    desc = "Passcode Themes from Cowabunga!"
                }
            }
            var translatedPackages = [Package]()
            for pkg in cowRepo {
                if let translatedPackage = translateToPackage(pkgType: "cowabunga", package: pkg, repourl: repoURL?.deletingLastPathComponent(), installtype: installtype) {
                    translatedPackages.append(translatedPackage)
                }
            }
            return Repo(name: name,
                        desc: desc,
                        url: repoURL,
                        icon: "https://github.com/leminlimez/Cowabunga/blob/main/Cowabunga/Assets.xcassets/AppIcons/AppIcon.appiconset/Cowabunga.png?raw=true",
                        accent: nil,
                        featured: nil,
                        packages: translatedPackages,
                        repotype: repoType)
        }
    case "altstore":
        if let altstoreRepo = repo as? AltstoreRepo {
            var translatedPackages = [Package]()
            for pkg in altstoreRepo.apps ?? [] {
                if let translatedPackage = translateToPackage(pkgType: "altstore", package: pkg) {
                    translatedPackages.append(translatedPackage)
                }
            }
            return Repo(name: altstoreRepo.name ?? "Unknown Altstore Repo",
                        desc: altstoreRepo.subtitle ?? "Unknown Altstore Repo Desc",
                        url: URL(string: altstoreRepo.sourceURL ?? repoURL?.absoluteString ?? ""),
                        icon: altstoreRepo.iconURL ?? "https://user-images.githubusercontent.com/705880/65270980-1eb96f80-dad1-11e9-9367-78ccd25ceb02.png",
                        accent: nil,
                        featured: nil,
                        packages: translatedPackages,
                        repotype: repoType)
        }
    case "esign":
        if let esignRepo = repo as? ESignRepo {
            var translatedPackages = [Package]()
            for pkg in esignRepo.apps ?? [] {
                if let translatedPackage = translateToPackage(pkgType: "esign", package: pkg) {
                    translatedPackages.append(translatedPackage)
                }
            }
            return Repo(name: esignRepo.name ?? "Unknown Altstore Repo",
                        desc: "Esign Repo Desc",
                        url: URL(string: esignRepo.sourceURL ?? repoURL?.absoluteString ?? ""),
                        icon: "https://esign.yyyue.xyz/ESignLogo200.png",
                        accent: nil,
                        featured: nil,
                        packages: translatedPackages,
                        repotype: repoType)
        }
    case "scarlet":
        if let scarletRepo = repo as? ScarletRepo {
            var translatedPackages = [Package]()
            var apps: [ScarletApp] = []
            apps.append(contentsOf: scarletRepo.Tweaked ?? [])
            apps.append(contentsOf: scarletRepo.Macdirtycow ?? [])
            apps.append(contentsOf: scarletRepo.Sideloaded ?? [])
            for pkg in apps {
                if let translatedPackage = translateToPackage(pkgType: "scarlet", package: pkg) {
                    translatedPackages.append(translatedPackage)
                }
            }
            return Repo(name: scarletRepo.META.repoName ?? "Unknown Scarlet Repo",
                        desc: "Scarlet Repo Desc",
                        url: URL(string: repoURL?.absoluteString ?? ""),
                        icon: scarletRepo.META.repoIcon ?? "https://3414992490-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FFJiyQY8c07uhMBUxEiix%2Ficon%2FvXR6UhwzjUotIjWQQNJs%2FCydiaIcon.png?alt=media&token=60ea4c48-5812-4574-a262-a716ca698e6d",
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
