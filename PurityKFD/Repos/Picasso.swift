//
//  Picasso.swift
//  test
//
//  Created by Lrdsnow on 8/20/23.
//

import Foundation
import SwiftUI
import ZIPFoundation

struct Package: Codable {
    let name: String
    let bundleid: String
    let author: String
    let description: String?
    let version: String
    let icon: String
    let path: String
}

struct Repo: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let packages: [Package]
    var url: URL?
    
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

struct PicassoContentRow: View {
    let name: String
    let author: String
    let icon: String
    let repo: Repo
    @State private var contentIcon: UIImage? = nil
    
    var body: some View {
        HStack {
            if let icon = contentIcon { // Display the fetched icon if available
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 30, height: 30) // Adjust the size as needed
                    .cornerRadius(5)
            } else {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
            }
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }.onAppear {
            if let iconURL = URL(string: repo.url!.appendingPathComponent(icon).absoluteString) { do {
                fetchImage(from: iconURL) { result in
                    switch result {
                    case .success(let image):
                        DispatchQueue.main.async {
                            contentIcon = image // Update the fetched image
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
