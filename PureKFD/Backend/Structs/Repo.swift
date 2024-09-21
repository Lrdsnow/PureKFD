//
//  Repo.swift
//  purekfd
//
//  Created by Lrdsnow on 6/27/24.
//

import Foundation
import JASON
import SwiftUI

public struct Repo: Codable, Hashable {
    let name: String
    var description: String
    var url: URL?
    var fullURL: URL?
    let icon: String
    var categorized: Bool = true
    var accent: String?
    var featured: [Featured]?
    var packages: [Package]
    
    let defaultRowAccent: String?
    
    var error: String? = nil
    
    var filtered: Bool? = nil
    
    var iconURL: URL? {get { return self.icon.hasPrefix("https://") || self.icon.hasPrefix("http://") ? URL(string: self.icon) : self.url?.appendingPathComponent(self.icon) }}
    
    var prettyURL: String? {
        get {
            if let url = url {
                if url.absoluteString.contains("raw.githubusercontent.com"),
                   let range = url.absoluteString.range(of: "raw.githubusercontent.com/") {
                    let stringComponents = String(url.absoluteString[range.upperBound...]).components(separatedBy: "/")
                    if stringComponents.count >= 2 {
                        let githubString = "\(stringComponents[0])/\(stringComponents[1])"
                        return "GitHub - \(githubString)"
                    } else {
                        return url.absoluteString
                    }
                }
                return url.absoluteString
            }
            return nil
        }
    }
    
    var accentColor: Color? {
        get {
            if let accent = accent {
                return Color(hex: accent)
            } else {
                return nil
            }
        }
    }
    
    init(_ _error: Error, _ _url: URL?) {
        name = "Unknown Repo"
        description = _url?.absoluteString ?? _error.localizedDescription
        icon = ""
        categorized = false
        accent = nil
        defaultRowAccent = nil
        featured = nil
        packages = []
        url = _url?.deletingLastPathComponent()
        fullURL = _url
        error = _error.localizedDescription
    }
    
    init(_ json: JSON, _ repo_url: URL?, noPkgs: Bool = false) {
        if let _name = json["name"].string,
           let _url = repo_url?.pathExtension == "" ? repo_url : repo_url?.deletingLastPathComponent() {
            name = _name
            description = json["description"].stringValue
            icon = json["icon"].stringValue
            categorized = json["categorized"].boolValue
            accent = json["accent"].string
            defaultRowAccent = json["defaultRowAccent"].string
            url = _url
            fullURL = repo_url
            if !noPkgs {
                let temp_featured = (json["featured"].array as? [[String: Any]])?.map { Featured($0, Repo(json, _url, noPkgs: true)) }
                featured = temp_featured
                packages = (json["packages"].array as? [[String: Any]])?.map { Package($0, Repo(json, _url, noPkgs: true), temp_featured) } ?? []
            } else {
                featured = nil
                packages = []
            }
        } else {
            name = "Unknown Repo"
            description = repo_url?.absoluteString ?? "Error: invalid json"
            categorized = false
            accent = nil
            defaultRowAccent = nil
            featured = nil
            packages = []
            url = repo_url?.deletingLastPathComponent()
            fullURL = repo_url
            icon = ""
            error = "Error: invalid json"
            featured = nil
            packages = []
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fullURL)
    }
    
    public static func == (lhs: Repo, rhs: Repo) -> Bool {
        return lhs.fullURL == rhs.fullURL
    }
}
