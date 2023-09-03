//
//  Picasso.swift
//  test
//
//  Created by Lrdsnow on 8/20/23.
//

import Foundation
import SwiftUI
import ZIPFoundation

struct Package: Codable, Identifiable {
    let id = UUID()
    let name: String
    let bundleid: String
    let author: String
    let description: String?
    let screenshots: [String]?
    let version: String
    let icon: String
    let path: String
    var repo: Repo?
    let MisakaReleases: [Release]?
    let MinIOSVersion: String?
    let MaxIOSVersion: String?
    let type: String?
}

struct Repo: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String?
    let description: String?
    let icon: String?
    let packages: [Package]
    var url: URL?
    let type: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func ==(lhs: Repo, rhs: Repo) -> Bool {
        return lhs.id == rhs.id
    }
}


func downloadAndExtractJSONFiles(from url: URL, icon iconurl: URL, completion: @escaping (Bool) -> Void) {
    let fileManager = FileManager.default

    // Create a destination folder for extraction
    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let extractedFolderPath = documentsDirectory.appendingPathComponent("Extracted")
    
    do {
        try fileManager.createDirectory(at: extractedFolderPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("Error creating extraction folder: \(error.localizedDescription)")
        completion(false)
    }

    let zipFileURL = extractedFolderPath.appendingPathComponent("downloaded.zip")

    let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
        guard let tempURL = tempURL else {
            print("Download failed with error: \(error?.localizedDescription ?? "Unknown error")")
            completion(false)
            return
        }

        do {
            try fileManager.moveItem(at: tempURL, to: zipFileURL)

            // Unzip the downloaded ZIP file using ZIPFoundation
            guard let archive = Archive(url: zipFileURL, accessMode: .read) else {
                print("Failed to create archive")
                completion(false)
                return
            }

            var infoJSON: [String: Any]?
            var tweakJSON: [String: Any]?
            var prefJSON: [String: Any]?

            for entry in archive {
                let entryPath = entry.path
                let destinationURL = extractedFolderPath.appendingPathComponent(entryPath)
                do {
                    try archive.extract(entry, to: destinationURL)

                    // Attempt to read JSON files based on their names
                    if entryPath.contains("info.json") {
                        if let data = try? Data(contentsOf: destinationURL),
                           let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            infoJSON = json
                        }
                    } else if entryPath.contains("tweak.json") {
                        if let data = try? Data(contentsOf: destinationURL),
                           let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            tweakJSON = json
                        }
                    } else if entryPath.contains("prefs.json") {
                        if let data = try? Data(contentsOf: destinationURL),
                           let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            prefJSON = json
                        }
                    }
                } catch {
                    print("Error extracting \(entryPath): \(error)")
                    completion(false)
                }
            }

            // Use the extracted JSON data as needed
            if let infoJSON = infoJSON {
                print("Info JSON: \(infoJSON)")
            }
            if let tweakJSON = tweakJSON {
                print("Tweak JSON: \(tweakJSON)")
            }
            if let prefJSON = prefJSON {
                print("Prefs JSON: \(prefJSON)")
            }

            // Extracted folder renaming and moving
            var filename = url.lastPathComponent
            if filename.lowercased().hasSuffix(".picasso") {
                filename = String(filename.prefix(upTo: filename.index(filename.endIndex, offsetBy: -8)))
            }
            let pkgExtractedFolderPath = extractedFolderPath.appendingPathComponent(filename)
            
            let installedFolderPath = documentsDirectory.appendingPathComponent("Installed")
            
            do {
                try fileManager.createDirectory(at: installedFolderPath, withIntermediateDirectories: true, attributes: nil)
                
                let installedFolderURL = installedFolderPath.appendingPathComponent(filename)
                try fileManager.moveItem(at: pkgExtractedFolderPath, to: installedFolderURL)
                
                // Download Icon
                let iconFileURL = installedFolderURL.appendingPathComponent("icon.png")
                let iconTask = URLSession.shared.downloadTask(with: iconurl) { tempURL, response, error in
                    guard let tempURL = tempURL else {
                        if let error = error {
                            print("Icon download failed with error: \(error.localizedDescription)")
                        } else {
                            print("Icon download failed with unknown error")
                        }
                        completion(false)
                        return
                    }
                    
                    do {
                        try FileManager.default.moveItem(at: tempURL, to: iconFileURL)
                        completion(true)
                    } catch {
                        print("Error moving icon file: \(error.localizedDescription)")
                        completion(false)
                    }
                }
                iconTask.resume()
            } catch {
                print("Error moving folder to Installed: \(error.localizedDescription)")
                completion(false)
            }

            try? fileManager.removeItem(at: extractedFolderPath)
        } catch {
            print("Error: \(error.localizedDescription)")
            completion(false)
        }
    }

    task.resume()
}

class AppState: ObservableObject {
    @Published var imageCacheData: [String: Data] = [:]
    
    func saveImageToCache(_ data: Data, forKey key: String) {
        imageCacheData[key] = data
    }
    
    func loadImageFromCache(forKey key: String) -> Data? {
        return imageCacheData[key]
    }
}

struct PicassoContentRow: View {
    let name: String
    let author: String
    let icon: String
    let repo: Repo
    
    @StateObject private var appState = AppState() // Create an AppState instance
    
    @State private var contentIcon: UIImage? = nil
    
    var body: some View {
        HStack {
            if let icon = contentIcon {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .cornerRadius(5)
            } else {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.purple)
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.purple.opacity(0.7))
            }
        }
        .onAppear {
            if let iconURL = URL(string: repo.url!.appendingPathComponent(icon).absoluteString) {
                if let cachedImageData = appState.loadImageFromCache(forKey: iconURL.absoluteString) {
                    // Use cached image data
                    contentIcon = UIImage(data: cachedImageData)
                } else {
                    // Download and cache the image
                    downloadAndCacheImage(from: iconURL)
                }
            }
        }
    }
    
    private func downloadAndCacheImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    contentIcon = image
                    appState.saveImageToCache(data, forKey: url.absoluteString)
                }
            }
        }.resume()
    }
}

struct PicassoContentDetailsView: View {
    let repo: Repo
    @Binding var selectedRepo: SelectedItem?
    
    var body: some View {
        List(repo.packages, id: \.bundleid) { package in
            NavigationLink(destination: AppDetailView(pkg: package, MisakaPkg: nil, repo: repo, MisakaRepo: nil, picassoRepo: true)) {
                PicassoContentRow(name: package.name, author: package.author, icon: package.icon, repo: repo)
            }.listRowBackground(Color.clear)
        }
        .navigationTitle(repo.name ?? "Unknown Repo Name")
    }
}

class PackageManager {
    static var shared = PackageManager()
    private var indexedPackages: [String: Package] = [:]

    func indexPackages(packages: [Package]) {
        for package in packages {
            indexedPackages[package.bundleid] = package
        }
    }

    func searchPackages(with searchText: String) -> [Package] {
        let lowercaseSearchText = searchText.lowercased()
        let matchingPackages = indexedPackages.values.filter { package in
            package.name.lowercased().contains(lowercaseSearchText)
        }
        return Array(matchingPackages)
    }
}

class NetworkManager {
    func fetchRepos(from urls: [URL], completion: @escaping ([Repo]) -> Void) {
        var repos: [Repo] = []

        let group = DispatchGroup()

        for url in urls {
            group.enter()
            let manifestURL = url.appendingPathComponent("manifest.json")
            URLSession.shared.dataTask(with: manifestURL) { data, response, error in
                defer { group.leave() }

                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        var repo = try decoder.decode(Repo.self, from: data)
                        
                        
                        repo.url = url
                        
                        repos.append(repo)
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }.resume()
        }

        group.notify(queue: .main) {
            completion(repos)
        }
    }
}

struct RepoRow: View {
    let repo: Repo
    @State private var repositoryIcon: UIImage? = nil
    
    var body: some View {
        HStack {
            if let icon = repositoryIcon {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .cornerRadius(5)
            } else {
                Image(systemName: "folder.fill")
                    .foregroundColor(.purple)
            }
            VStack(alignment: .leading) {
                Text(repo.name ?? "Unknown Repo Name")
                    .font(.headline)
                    .foregroundColor(.purple)
                Text(repo.description ?? "Unknown Repo Description")
                    .font(.subheadline)
                    .foregroundColor(.purple.opacity(0.7))
            }
        }.onAppear {
            DispatchQueue.global(qos: .utility).async {
                                 FetchLog()
                             }
            if let iconURL = URL(string: repo.url!.appendingPathComponent(repo.icon ?? "").absoluteString) {
                fetchImage(from: iconURL) { result in
                    switch result {
                    case .success(let image):
                        DispatchQueue.main.async {
                            repositoryIcon = image
                        }
                    case .failure(let error):
                        print("Error fetching image: \(error)")
                    }
                }
            }
        }
    }
}

struct PackageRow: View {
    let package: Package
    @State private var contentIcon: UIImage? = nil

    var body: some View {
        HStack {
            if let icon = contentIcon {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .cornerRadius(5)
            } else {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
            }
            VStack(alignment: .leading) {
                Text(package.name)
                    .font(.headline)
                    .foregroundColor(.purple)
                Text(package.author)
                    .font(.subheadline)
                    .foregroundColor(.purple.opacity(0.7))
            }
            Spacer()
            if package.type == "misaka" {
                Text("Misaka")
                    .font(.footnote)
                    .foregroundColor(.purple.opacity(0.5))
            } else {
                Text("Picasso")
                    .font(.footnote)
                    .foregroundColor(.purple.opacity(0.5))
            }
        }
        .onAppear {
            DispatchQueue.global(qos: .utility).async {
                                 FetchLog()
                             }
            if package.type == "misaka" {
                if let iconURL = URL(string: package.icon) {
                    fetchImage(from: iconURL) { result in
                        switch result {
                        case .success(let image):
                            DispatchQueue.main.async {
                                contentIcon = image
                            }
                        case .failure(let error):
                            print("Error fetching image: \(error)")
                        }
                    }
                }
            } else {
                if let iconURL = URL(string: (package.repo?.url!.appendingPathComponent(package.icon).absoluteString)!) {
                    fetchImage(from: iconURL) { result in
                        switch result {
                        case .success(let image):
                            DispatchQueue.main.async {
                                contentIcon = image
                            }
                        case .failure(let error):
                            print("Error fetching image: \(error)")
                        }
                    }
                }
            }
        }
    }
}
