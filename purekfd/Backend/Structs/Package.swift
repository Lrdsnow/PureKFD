//
//  Package.swift
//  purekfd
//
//  Created by Lrdsnow on 6/27/24.
//

import Foundation
import JASON
import SwiftUI

public struct Package: Codable {
    // Package Info
    var name: String
    var bundleid: String
    var author: String?
    var version: String?
    let description: String?
    let long_description: String?
    var icon: URL?
    let accent: String?
    let accentRow: String?
    let screenshots: [URL]?
    let banner: URL?
    let category: String
    let depiction: URL?
    //
    var filtered: Bool? = nil
    // Install Values:
    var path: URL?
    var versions: [String: String]?
    // Repo Values:
    let url: URL?
    var repo: Repo?
    var feature: Featured?
    // Installed values
    var disabled: Bool?
    var hasprefs: Bool
    var error: String?
    var varonly: Bool?
    var pkgpath: URL {
        return URL.documents.appendingPathComponent("pkgs/\(bundleid)")
    }
    var installed: Bool
    // JSON init stuff
    init(_ json: [String: Any], _ _repo: Repo?, _ _featured: [Featured]?) {
        name = json["name"] as? String ?? "Unknown Tweak"
        bundleid = json["bundleid"] as? String ?? ""
        author = json["author"] as? String
        version = json["version"] as? String
        description = json["description"] as? String
        long_description = json["long_description"] as? String
        error = json["error"] as? String
        let _icon = json["icon"] as? String ?? ""
        if _icon.hasPrefix("https://") || _icon.hasPrefix("http://") {
            icon = URL(string: _icon)
        } else if let _repo = _repo {
            icon = _repo.url?.appendingPathComponent(_icon)
        } else {
            icon = nil
        }
        accent = json["accent"] as? String
        accentRow = json["accentRow"] as? String ?? _repo?.defaultRowAccent
        let _banner = json["banner"] as? String
        if let _banner = _banner {
            if _banner.hasPrefix("https://") || _banner.hasPrefix("http://") {
                banner = URL(string: _banner)
            } else if let _repo = _repo {
                banner = _repo.url?.appendingPathComponent(_banner)
            } else {
                banner = nil
            }
        } else {
            banner = nil
        }
        repo = _repo
        if let screenshotsArray = json["screenshots"] as? [String],
            let _repo = _repo {
            screenshots = screenshotsArray.compactMap { $0.hasPrefix("https://") || $0.hasPrefix("http://") ? URL(string: $0) : _repo.url?.appendingPathComponent($0) }
        } else {
            screenshots = nil
        }
        category = json["category"] as? String ?? ""
        if let pathString = json["path"] as? String {
            if pathString.hasPrefix("https://") || pathString.hasPrefix("http://") {
                path = URL(string: pathString)
            } else if let _repo = _repo {
                path = _repo.url?.appendingPathComponent(pathString)
            }
        } else {
            path = nil
        }
        versions = json["versions"] as? [String: String]
        if let urlString = json["url"] as? String {
            url = URL(string: urlString)
        } else {
            url = nil
        }
        if let depictionString = json["depiction"] as? String {
            if depictionString.contains("http") {
                depiction = URL(string: depictionString)
            } else {
                depiction = _repo?.url?.appendingPathComponent(depictionString)
            }
        } else {
            depiction = nil
        }
        disabled = json["disabled"] as? Bool
        varonly = json["varonly"] as? Bool ?? json["varOnly"] as? Bool
        let temp_pkgpath = URL.documents.appendingPathComponent("pkgs/\(bundleid)")
        installed = FileManager.default.fileExists(atPath: temp_pkgpath.path)
        hasprefs = json["hasprefs"] as? Bool ?? false
        if installed {
            if !hasprefs {
                hasprefs = FileManager.default.fileExists(atPath: temp_pkgpath.appendingPathComponent(config_filename).path)
            }
            if !hasprefs {
                hasprefs = FileManager.default.fileExists(atPath: temp_pkgpath.appendingPathComponent("config.plist").path)
            }
            if !hasprefs {
                hasprefs = FileManager.default.fileExists(atPath: temp_pkgpath.appendingPathComponent("prefs.json").path)
            }
        }
        feature = _featured?.first(where: { $0.bundleid == json["bundleid"] as? String ?? "" })
    }
    public func save() {
        if let jsonData = try? JSONEncoder().encode(self) {
            try? jsonData.write(to: self.pkgpath.appendingPathComponent("_info.json"))
        }
    }

    var accentRowColor: Color? {
        if let accentRow = accentRow {
            return Color(hex: accentRow)
        } else {
            return nil
        }
    }
    var accentColor: Color? {
        if let accent = accent {
            return Color(hex: accent)
        } else if let accent = repo?.accentColor {
            return accent
        } else {
            return nil
        }
    }
}

public struct Featured: Codable {
    let name: String
    let bundleid: String
    var banner: URL?
    let fontcolor: String?
    let showname: Bool?
    let square: Bool?
    let repo: Repo?
    
    init(_ json: [String: Any], _ _repo: Repo) {
        name = json["name"] as? String ?? ""
        bundleid = json["bundleid"] as? String ?? ""
        let _banner = json["banner"] as? String ?? ""
        if _banner.hasPrefix("https://") || _banner.hasPrefix("http://") {
            banner = URL(string: _banner)
        } else {
            banner = _repo.url?.appendingPathComponent(_banner)
        }
        fontcolor = json["fontcolor"] as? String
        showname = json["showname"] as? Bool
        square = json["square"] as? Bool
        repo = _repo
    }
}
