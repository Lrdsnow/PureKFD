//
//  Misaka.swift
//  test
//
//  Created by Lrdsnow on 8/20/23.
//

import Foundation
import SwiftUI
import ZIPFoundation

struct Repository: Codable, Identifiable {
    let id = UUID()
    let RepositoryName: String
    let RepositoryDescription: String
    let RepositoryAuthor: String
    let RepositoryIcon: String
    let RepositoryWebsite: String
    var RepositoryURL: URL?
    let RepositoryContents: [Content]
}

struct Content: Codable, Identifiable {
    let id = UUID()
    let Name: String
    let Description: String?
    let Caption: String?
    let Screenshot: [String]?
    let Icon: String?
    let Author: Author?
    let Releases: [Release]?
    let PackageID: String?
    let MinIOSVersion: String?
    let MaxIOSVersion: String?
}

struct Author: Codable {
    let Label: String
    let Links: [Link]?
}

struct Link: Codable {
    let Label: String
    let Link: String
}

struct Release: Codable {
    let Version: String
    let Package: String
    let Description: String?
}

struct RepositoriesListView: View {
    let repositories: [Repository]
    
    var body: some View {
        List(repositories) { repository in
            NavigationLink(destination: ContentDetailsView(contents: repository.RepositoryContents, repository: repository)) {
                RepositoryRow(repository: repository)
            }
        }
    }
}

struct RepositoryRow: View {
    let repository: Repository
    @State private var repositoryIcon: UIImage? = nil // State to hold the fetched image

    var body: some View {
        HStack {
            if let icon = repositoryIcon { // Display the fetched icon if available
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 30, height: 30) // Adjust the size as needed
                    .cornerRadius(5)
            } else {
                Image(systemName: "folder.fill")
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading) {
                Text(repository.RepositoryName)
                    .font(.headline)
                    .foregroundColor(.purple)
                Text(repository.RepositoryDescription)
                    .font(.subheadline)
                    .foregroundColor(.purple.opacity(0.7))
            }
        }
        .onAppear {
            if let iconURL = URL(string: repository.RepositoryIcon) { // Assuming you have the icon URL in your Repository model
                fetchImage(from: iconURL) { result in
                    switch result {
                    case .success(let image):
                        DispatchQueue.main.async {
                            repositoryIcon = image // Update the fetched image
                        }
                    case .failure(let error):
                        print("Error fetching image: \(error)")
                    }
                }
            }
        }
    }
}



struct ContentDetailsView: View {
    let contents: [Content]
    let repository: Repository
    
    var body: some View {
        List(contents) { content in
            NavigationLink(destination: destinationView(for: content)) {
                ContentRow(content: content, repo: repository)
            }.listRowBackground(Color.clear)
        }
        .navigationTitle(repository.RepositoryName)
    }
    
    @ViewBuilder
    private func destinationView(for content: Content) -> some View {
        AppDetailView(pkg: nil, MisakaPkg: content, repo: nil, MisakaRepo: repository, picassoRepo: false)
    }
}


struct ContentRow: View {
    let content: Content
    let repo: Repository
    @State private var contentIcon: UIImage? = nil // State to hold the fetched icon image
    
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
                Text(content.Name)
                    .font(.headline)
                    .foregroundColor(.purple)
                if let authorLabel = content.Author?.Label {
                    Text(authorLabel)
                        .font(.subheadline)
                        .foregroundColor(.purple.opacity(0.7))
                } else {
                    let authorLabel = repo.RepositoryAuthor
                    Text(authorLabel)
                        .font(.subheadline)
                        .foregroundColor(.purple.opacity(0.7))
                }
            }
        }
        .onAppear {
            if let iconURL = content.Icon, let url = URL(string: iconURL) {
                // Use the provided extension method to download the image
                UIImageView().downloaded(from: url) { image in
                    contentIcon = image
                }
            }
        }
    }
}

func fetchData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        if let data = data {
            completion(.success(data))
        } else {
            completion(.failure(NSError(domain: "FetchingError", code: 404, userInfo: nil)))
        }
    }.resume()
}

func fetchImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        if let data = data, let image = UIImage(data: data) {
            completion(.success(image))
        } else {
            completion(.failure(NSError(domain: "FetchingError", code: 404, userInfo: nil)))
        }
    }.resume()
}

class RepositoriesListViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    
    func fetchRepositories(repoURLs: [URL], completion: @escaping ([Repo]) -> Void) { // Change Array<URL> to [URL]
        repositories = []
        
        let dispatchGroup = DispatchGroup() // Create a dispatch group
        
        for url in repoURLs {
            dispatchGroup.enter() // Enter the dispatch group
            
            fetchData(from: url) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        var decodedData = try decoder.decode(Repository.self, from: data)
                        decodedData.RepositoryURL = url
                        DispatchQueue.main.async {
                            // Append the new repository to the existing list
                            self.repositories.append(decodedData)
                            dispatchGroup.leave() // Leave the dispatch group
                        }
                        completion(convertToRepos(from: self.repositories))
                    } catch {
                        print("Error decoding JSON: \(error)")
                        dispatchGroup.leave() // Leave the dispatch group on error as well
                    }
                case .failure(let error):
                    print("Error fetching data: \(error)")
                    dispatchGroup.leave() // Leave the dispatch group on error
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // This block will be executed when all tasks in the dispatch group are complete
            // You can perform any necessary actions here, such as updating UI
        }
    }
}

func downloadPackage(from url: URL, icon iconurl: URL, pkg: Content, completion: @escaping (Bool) -> Void) {
    let fileManager = FileManager.default
    
    let clean = true
    
    var errorText = "Failed to install package"
    
    // Create a destination folder for extraction
    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let extractedFolderPath = documentsDirectory.appendingPathComponent("Misaka/Extracted")
    let installedFolderPath = documentsDirectory.appendingPathComponent("Misaka/Installed")
    let downloadFolderPath = documentsDirectory.appendingPathComponent("Misaka/Download")
    
    do {
        try fileManager.createDirectory(at: extractedFolderPath, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: installedFolderPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("Error creating Misaka folders: \(error.localizedDescription)")
        completion(false)
    }
    
    let zipFileURL = documentsDirectory.appendingPathComponent("Misaka/downloaded.zip")
    
    UIApplication.shared.alert(title: "Installing...", body: "Please wait", animated: false, withButton: false)
    let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
        guard let tempURL = tempURL else {
            print("Download failed with error: \(error?.localizedDescription ?? "Unknown error")")
            completion(false)
            return
        }
        
        do {
            try fileManager.moveItem(at: tempURL, to: zipFileURL)
            
            print("Unzipping...")
            if !unzip(Data_zip: zipFileURL, Extract: extractedFolderPath) {
                errorText = "Could Not Decompress Package"
                let error = NSError(domain: "error", code: 1, userInfo: nil)
                throw error
            }
            
            // Recursive function to find a parent folder containing a subfolder with ".system" in its name
            func findParentFolderWithSystemSubfolder(in directoryPath: String) -> String? {
                let fileManager = FileManager.default
                guard let contents = try? fileManager.contentsOfDirectory(atPath: directoryPath) else {
                    return nil
                }

                for item in contents {
                    let itemPath = (directoryPath as NSString).appendingPathComponent(item)
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
                        if isDirectory.boolValue {
                            let subfolderPath = (itemPath as NSString).appendingPathComponent(".system")
                            if fileManager.fileExists(atPath: subfolderPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                                return item
                            } else if let subFolderPath = findParentFolderWithSystemSubfolder(in: itemPath) {
                                return subFolderPath
                            }
                        }
                    }
                }

                return nil
            }

            // Move Contents to Misaka/Installed/<pkg.PackageID> & Create info.json
            if let parentFolderName = findParentFolderWithSystemSubfolder(in: extractedFolderPath.path) {
                // Move Contents
                let installedPackagePath = installedFolderPath
                let extractedParentFolderPath = extractedFolderPath.appendingPathComponent(parentFolderName)
                let destinationPath = installedPackagePath.appendingPathComponent(pkg.PackageID!)
                print(String(extractedParentFolderPath.absoluteString.dropFirst(7).replacingOccurrences(of: "%20", with: " ")))
                print(String(destinationPath.absoluteString.dropFirst(7)))
                try fileManager.moveItem(atPath: String(extractedParentFolderPath.absoluteString.dropFirst(7).replacingOccurrences(of: "%20", with: " ")), toPath: String(destinationPath.absoluteString.dropFirst(7)))

                // Create info.json
                let infoPath = destinationPath.appendingPathComponent("info.json")
                do {
                    let jsonData = try JSONEncoder().encode(pkg)
                    try jsonData.write(to: infoPath)
                } catch {
                    print("Error creating info.json: \(error)")
                    errorText = "Error creating info.json: \(error)"
                    let error = NSError(domain: "error", code: 1, userInfo: nil)
                    throw error
                }
            } else {
                print("Error getting Package Folder")
                errorText = "Error getting Package Folder"
                let error = NSError(domain: "error", code: 1, userInfo: nil)
                throw error
            }
            
            let installedPackages = getInstalledPackages()
            if !installedPackages.contains(where: { $0.bundleID == pkg.PackageID }) {
                errorText = "Installed Successfully but Package Unsupported?"
                let error = NSError(domain: "error", code: 1, userInfo: nil)
                throw error
            }
            do {
                try fileManager.removeItem(at: downloadFolderPath)
                try fileManager.removeItem(at: zipFileURL)
                try fileManager.removeItem(atPath: extractedFolderPath.path)
            } catch {
                print("Cleanup failed!!!!")
            }
            print("Finished")
            UIApplication.shared.dismissAlert(animated: false)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.1) {
                UIApplication.shared.alert(title: "Success!", body: "Successfully installed package.", animated: false, withButton: true)
            }
        } catch {
            do {
                if clean {
                    try fileManager.removeItem(at: downloadFolderPath)
                    try fileManager.removeItem(at: zipFileURL)
                    try fileManager.removeItem(atPath: extractedFolderPath.path)
                }
            } catch {
                print("Cleanup failed!!!!")
            }
            print("Error:", errorText)
            UIApplication.shared.dismissAlert(animated: false)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.1) {
                UIApplication.shared.alert(title: "Error", body: errorText, animated: false, withButton: true)
            }
        }
    }
    task.resume()
}

// Rel Stuff:

func unzip(Data_zip: URL, Extract: URL) -> Bool{
    print("Unsupported on unoffical builds")
    return false
}

