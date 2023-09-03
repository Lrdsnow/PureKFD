//
//  ContentView.swift
//  test
//
//  Created by Lrdsnow on 8/19/23.
//

import SwiftUI
import Foundation
import Combine
import UIKit
import ZIPFoundation

enum SelectedItem: Hashable {
    case repo(Repo)
}

@main
struct RepoApp: App {
    @StateObject var appDelegate = AppDelegate()
    @StateObject var userSettings = UserSettings()
    
    init() {
        cleanupFilesAndDirectories()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate)
                .environmentObject(userSettings)
        }
    }
    private func cleanupFilesAndDirectories() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let foldersToDelete = ["Misaka/Extracted", "Misaka/Download", "Misaka/downloaded.zip", "Extracted", "TempOverwriteFile", "Background_Files"]
        
        for folderName in foldersToDelete {
            do {
                try fileManager.removeItem(atPath: documentsDirectory.appendingPathComponent(folderName).path)
            } catch {
                print("")
            }
        }
        
        do {
            try fileManager.removeItem(atPath: documentsDirectory.appendingPathComponent("Misaka/Download").path)
            try fileManager.removeItem(at: documentsDirectory.appendingPathComponent("Misaka/downloaded.zip"))
        } catch {
            print("")
        }
    }
}

class AppDelegate: ObservableObject {
    @Published var TweakSettings_current_path: String = ""
    @Published var TweakSettings_overwrite_path: String = ""
    @Published var TweakSettings_IsActive: Bool = false
    @Published var TweakSettings_PackageID: String = ""
    @Published var App_Loading: Bool = false
}

struct ContentView: View {
    @State private var isAddRepoAlertPresented = false
    @State private var selectedTab: Tab = .home
    @State private var addrepoURL = ""
    @State private var PicassoRepos: [Repo] = []
    @State private var selectedRepo: SelectedItem? = nil
    @ObservedObject var viewModel = RepositoriesListViewModel()
    
    @State private var dev: Bool = false
    
    enum Tab {
        case repos, installed, home, search
    }
    
    init() {
        UINavigationBar.appearance().prefersLargeTitles = true
    }
    
    @AppStorage("MisakaRepoURLs") private var misakaRepoURLsData: Data = Data()
    @AppStorage("PicassoRepoURLs") private var picassoRepoURLsData: Data = Data()
    
    @State private var PicassoRepoURLs: [URL] = []
    @State private var MisakaRepoURLs: [URL] = []
    
    var body: some View {
        NavigationView {
            mainContent()
        }
        .onAppear {
            initializeData()
            fetchPicassoRepos()
            fetchMisakaRepos()
        }
        .toolbar {
            bottomBar()
        }
    }
    
    func addRepo(addPicassoRepo: Bool) {
        if var newURL = URL(string: addrepoURL) {

            if addPicassoRepo, newURL.lastPathComponent == "manifest.json" {
                if let urlWithoutManifest = URL(string: newURL.deletingLastPathComponent().absoluteString) {
                    newURL = urlWithoutManifest
                }
            }
            
            if addPicassoRepo {
                PicassoRepoURLs.append(newURL)
                savePicassoRepoURLs()
                fetchPicassoRepos()
            } else {
                MisakaRepoURLs.append(newURL)
                saveMisakaRepoURLs()
                fetchMisakaRepos()
            }
        }
        
        addrepoURL = ""
        isAddRepoAlertPresented = false
    }
    
    func removeRepo(PicassoRepo: Bool) {
        if var newURL = URL(string: addrepoURL) {
            if PicassoRepo {
                if PicassoRepo, newURL.lastPathComponent == "manifest.json" {
                    if let urlWithoutManifest = URL(string: newURL.deletingLastPathComponent().absoluteString) {
                        newURL = urlWithoutManifest
                    }
                }
                if let index = PicassoRepoURLs.firstIndex(where: { $0.absoluteString == newURL.absoluteString }) {
                    PicassoRepoURLs.remove(at: index)
                    savePicassoRepoURLs()
                    fetchPicassoRepos()
                }
            } else {
                if let index = MisakaRepoURLs.firstIndex(of: newURL) {
                    MisakaRepoURLs.remove(at: index)
                    saveMisakaRepoURLs()
                    fetchMisakaRepos()
                }
            }
        }
        
        addrepoURL = ""
        isAddRepoAlertPresented = false
    }
    
    func saveMisakaRepoURLs() {
        if let encodedData = try? JSONEncoder().encode(MisakaRepoURLs) {
            misakaRepoURLsData = encodedData
        }
    }
    
    func savePicassoRepoURLs() {
        if let encodedData = try? JSONEncoder().encode(PicassoRepoURLs) {
            picassoRepoURLsData = encodedData
        }
    }
    
    func fetchPicassoRepos() {
        if !PicassoRepoURLs.isEmpty {
            NetworkManager().fetchRepos(from: PicassoRepoURLs) { fetchedRepos in
                var allPackages: [Package] = []

                for repo in fetchedRepos {
                    let repoURL = repo.url
                    for package in repo.packages {
                        var modifiedPackage = package
                        modifiedPackage.repo = repo
                        allPackages.append(modifiedPackage)
                    }
                }

                PackageManager.shared.indexPackages(packages: allPackages)
                self.PicassoRepos = fetchedRepos
            }
        }
    }

    func fetchMisakaRepos() {
        if !MisakaRepoURLs.isEmpty {
            viewModel.fetchRepositories(repoURLs: MisakaRepoURLs) { fetchedRepos in
                var allPackages: [Package] = []

                for repo in fetchedRepos {
                    let repoURL = repo.url
                    for package in repo.packages {
                        var modifiedPackage = package
                        modifiedPackage.repo = repo
                        allPackages.append(modifiedPackage)
                    }
                }

                PackageManager.shared.indexPackages(packages: allPackages)
            }
        }
    }
    
    private func mainContent() -> some View {
        Group {
            if selectedTab == .repos {
                reposContent()
            } else if selectedTab == .installed {
                InstalledPackagesView(installedPackages: getInstalledPackages())
                    .navigationBarTitle("PureKFD - Installed")
            } else if selectedTab == .home {
                HomeView().navigationBarTitle("PureKFD", displayMode: .large)
            } else if selectedTab == .search {
                SearchView().navigationBarTitle("PureKFD - Search", displayMode: .large)
            }
        }
    }
    
    private func reposContent() -> some View {
        List {
            Section(header: Text("Picasso Repos").foregroundColor(.purple)) {
                ForEach(PicassoRepos) { repo in
                    NavigationLink(
                        destination: PicassoContentDetailsView(repo: repo, selectedRepo: $selectedRepo),
                        tag: .repo(repo),
                        selection: $selectedRepo
                    ) {
                        RepoRow(repo: repo)
                    }.listRowBackground(Color.clear)
                    .contextMenu {
                        Button(action: {
                            let pasteboard = UIPasteboard.general
                            pasteboard.string = repo.url?.appendingPathComponent("manifest.json").absoluteString
                        }) {
                            Label("Copy URL", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive, action: {
                            addrepoURL = (repo.url?.appendingPathComponent("manifest.json").absoluteString)!
                            removeRepo(PicassoRepo: true)
                        }) {
                            Label("Remove Repo", systemImage: "trash")
                        }
                    }
                }
            }
            
            Section(header: Text("Misaka Repos").foregroundColor(.purple)) {
                ForEach(viewModel.repositories) { repository in
                    NavigationLink(destination: ContentDetailsView(contents: repository.RepositoryContents, repository: repository)) {
                        RepositoryRow(repository: repository)
                    }.listRowBackground(Color.clear).contextMenu {
                        Button(action: {
                            let pasteboard = UIPasteboard.general
                            pasteboard.string = repository.RepositoryURL?.absoluteString
                        }) {
                            Label("Copy URL", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive, action: {
                            addrepoURL = (repository.RepositoryURL?.absoluteString)!
                            removeRepo(PicassoRepo: false)
                        }) {
                            Label("Remove Repo", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationBarTitle("PureKFD - Repos")
        .navigationBarItems(trailing: Button(action: {
            isAddRepoAlertPresented.toggle()
        }) {
            Image(systemName: "plus.circle")
                .font(.system(size: 20))
        })
        .alert("Add Repo", isPresented: $isAddRepoAlertPresented) {
            TextField("Repo URL", text: $addrepoURL)
                .textInputAutocapitalization(.never)
            Button("Add Picasso Repo") {
                addRepo(addPicassoRepo: true)
            }
            Button("Add Misaka Repo") {
                addRepo(addPicassoRepo: false)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enter the repository URL")
        }
    }
    
    private func bottomBar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Spacer()
            
            Button(action: {
                selectedTab = .home
            }) {
                tabButton(imageName: "house", text: "Home", tab: .home)
            }.foregroundColor(selectedTab == .home ? .purple : .purple.opacity(0.4))
            
            Spacer()
            
            Button(action: {
                selectedTab = .repos
            }) {
                tabButton(imageName: "square.grid.2x2.fill", text: "Repos", tab: .repos)
            }.foregroundColor(selectedTab == .repos ? .purple : .purple.opacity(0.4))
            
            Spacer()
            
            Button(action: {
                selectedTab = .installed
            }) {
                tabButton(imageName: "checkmark.circle.fill", text: "Installed", tab: .installed)
            }.foregroundColor(selectedTab == .installed ? .purple : .purple.opacity(0.4))
            
            Spacer()
            
            Button(action: {
                selectedTab = .search
            }) {
                tabButton(imageName: "magnifyingglass", text: "Search", tab: .search)
            }.foregroundColor(selectedTab == .search ? .purple : .purple.opacity(0.4))
            
            Spacer()
        }
    }
    
    private func tabButton(imageName: String, text: String, tab: Tab) -> some View {
        VStack {
            Image(systemName: imageName)
            Text(text).font(.subheadline)
        }
    }
    
    private func initializeData() {
        DispatchQueue.global(qos: .utility).async {
            FetchLog()
        }
        
        if let savedMisakaRepoURLs = try? JSONDecoder().decode([URL].self, from: misakaRepoURLsData) {
            MisakaRepoURLs = savedMisakaRepoURLs
        }
        
        if let savedPicassoRepoURLs = try? JSONDecoder().decode([URL].self, from: picassoRepoURLsData) {
            PicassoRepoURLs = savedPicassoRepoURLs
        }
        
        if PicassoRepoURLs.isEmpty {
            PicassoRepoURLs = [
                URL(string: "https://raw.githubusercontent.com/Lrdsnow/lrdsnows-repo/main/PureKFD/")!,
                URL(string: "https://raw.githubusercontent.com/circularsprojects/circles-repo/main/")!,
                URL(string: "https://raw.githubusercontent.com/sourcelocation/Picasso-test-repo/main/")!,
                URL(string: "https://bomberfish.ca/PicassoRepos/Essentials/")!,
            ]
        }
        
        if MisakaRepoURLs.isEmpty {
            MisakaRepoURLs = [
                URL(string: "https://raw.githubusercontent.com/shimajiron/Misaka_Network/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/34306/iPA/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/roeegh/Puck/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/hanabiADHD/nbxyRepo/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/huligang/coolwcat/main/repo.json")!,
                URL(string: "https://yangjiii.tech/file/Repo/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/leminlimez/leminrepo/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/ichitaso/misaka/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/chimaha/misakarepo/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/sugiuta/repo-mdc/master/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/dobabaophuc1706/misakarepo/main/Repo/repo.json")!,
                URL(string: "https://github.com/Fomri/fomrirepo/raw/main/repo.json")!,
                URL(string: "https://tweakrain.github.io/repos/misaka/misaka.json")!,
                URL(string: "https://www.iwishkem.tk/misaka.json")!,
                URL(string: "https://raw.githubusercontent.com/EPOS05/EPOSbox/main/misaka.json")!,
                URL(string: "https://raw.githubusercontent.com/tdquang266/MDC/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/kloytofyexploiter/Misaka-repo_MRX/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/HackZy01/misio/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/p0s3id0n86/misakarepo/main/Repo/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/tyler10290/MisakaRepoBackup/main/repo.json")!,
                URL(string: "https://raw.githubusercontent.com/hanabiADHD/DekotasMirror/main/dekotas.json")!,
                URL(string: "https://gist.githubusercontent.com/c22dev/af8dd3a760330eb31da5f8751af1b487/raw/6eb744fabc6eb0eb3352ce41c9a08ce5c38c4e6a/index.json")!
            ]
        }
    }
}
