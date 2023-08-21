//
//  Misaka.swift
//  test
//
//  Created by Lrdsnow on 8/20/23.
//

import Foundation
import SwiftUI

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
    let Icon: String?
    let Author: Author?
    let Releases: [Release]?
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
                Text(repository.RepositoryDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
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
                ContentRow(content: content)
            }
        }
        .navigationTitle(repository.RepositoryName)
    }
    
    @ViewBuilder
    private func destinationView(for content: Content) -> some View {
        AppDetailView(pkg: nil, MisakaPkg: content, repo: nil, picassoRepo: false)
    }
}

struct ContentRow: View {
    let content: Content
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
                if let authorLabel = content.Author?.Label {
                    Text(authorLabel)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("Unknown Author")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            if let iconURL = content.Icon, let url = URL(string: iconURL) {
                fetchImage(from: url) { result in
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
    
    func fetchRepositories(repoURLs: [URL]) { // Change Array<URL> to [URL]
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
