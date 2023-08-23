//
//  ContentView.swift
//  test
//
//  Created by Lrdsnow on 8/19/23.
//

import SwiftUI
import Foundation
import Combine
import ZIPFoundation

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

enum SelectedItem: Hashable {
    case repo(Repo)
}

@main
struct RepoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var isAddRepoAlertPresented = false
    @State private var selectedTab: Tab = .home
    @State private var addrepoURL = ""
    @State private var PicassoRepos: [Repo] = []
    @State private var selectedRepo: SelectedItem? = nil
    @ObservedObject var viewModel = RepositoriesListViewModel()
    
    enum Tab {
        case repos
        case installed
        case home
        case search
    }
    
    //@State private var PicassoRepoURLs = [
    //   URL(string: "https://raw.githubusercontent.com/sourcelocation/Picasso-test-repo/main/")!,
    //   URL(string: "https://bomberfish.ca/PicassoRepos/Essentials/")!
    //]
    
    //@State private var MisakaRepoURLs = [
    //    URL(string: "https://raw.githubusercontent.com/shimajiron/Misaka_Network/main/repo.json")!,
    //    URL(string: "https://raw.githubusercontent.com/34306/iPA/main/repo.json")!,
    //    URL(string: "https://puck.roeegh.com/repo.json")!,
    //]
    
    @AppStorage("MisakaRepoURLs") private var misakaRepoURLsData: Data = Data()
    @AppStorage("PicassoRepoURLs") private var picassoRepoURLsData: Data = Data()
    
    @State private var PicassoRepoURLs: [URL] = []
    @State private var MisakaRepoURLs: [URL] = []
    
    var body: some View {
        NavigationView {
            if selectedTab == .repos {
                List {
                    Section(header: Text("Picasso Repos")) {
                        ForEach(PicassoRepos) { repo in
                            NavigationLink(
                                destination: PicassoContentDetailsView(repo: repo, selectedRepo: $selectedRepo),
                                tag: .repo(repo),
                                selection: $selectedRepo
                            ) {
                                RepoRow(repo: repo)
                            }
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
                    Section(header: Text("Misaka Repos")) {
                        ForEach(viewModel.repositories) { repository in
                            NavigationLink(destination: ContentDetailsView(contents: repository.RepositoryContents, repository: repository)) {
                                RepositoryRow(repository: repository)
                            }.contextMenu {
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
            } else if selectedTab == .installed {
                InstalledPackagesView(installedPackages: getInstalledPackages())
                    .navigationBarTitle("PureKFD - Installed")
            } else if selectedTab == .home {
                HomeView().navigationBarTitle("PureKFD", displayMode: .large)
            } else if selectedTab == .search {
                SearchView().navigationBarTitle("PureKFD - Search", displayMode: .large)
            }
        }
        .onAppear {
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
                    URL(string: "https://raw.githubusercontent.com/EPOS05/MisakaRepoEPOS/main/repo.json")!,
                    URL(string: "https://raw.githubusercontent.com/tdquang266/MDC/main/repo.json")!,
                    URL(string: "https://raw.githubusercontent.com/kloytofyexploiter/Misaka-repo_MRX/main/repo.json")!,
                    URL(string: "https://raw.githubusercontent.com/HackZy01/misio/main/repo.json")!,
                    URL(string: "https://raw.githubusercontent.com/p0s3id0n86/misakarepo/main/Repo/repo.json")!,
                    URL(string: "https://raw.githubusercontent.com/tyler10290/MisakaRepoBackup/main/repo.json")!,
                    URL(string: "https://raw.githubusercontent.com/hanabiADHD/DekotasMirror/main/dekotas.json")!,
                    URL(string: "https://gist.githubusercontent.com/c22dev/af8dd3a760330eb31da5f8751af1b487/raw/6eb744fabc6eb0eb3352ce41c9a08ce5c38c4e6a/index.json")!
                ]
            }
            
            fetchPicassoRepos()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                fetchMisakaRepos()
            }
        }
        .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
        
                        Button(action: {
                            selectedTab = .home
                        }) {
                            VStack {
                                Image(systemName: "house")
                                Text("Home").font(.subheadline)
                            }
                        }
                        .foregroundColor(selectedTab == .home ? .purple : .purple.opacity(0.4))
        
                        Spacer()
        
                        Button(action: {
                            selectedTab = .repos
                        }) {
                            VStack {
                                Image(systemName: "square.grid.2x2.fill")
                                Text("Repos").font(.subheadline)
                            }
                        }
                        .foregroundColor(selectedTab == .repos ? .purple : .purple.opacity(0.4))
        
                        Spacer()
        
                        Button(action: {
                            selectedTab = .installed
                        }) {
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Installed").font(.subheadline)
                            }
                        }.foregroundColor(selectedTab == .installed ? .purple : .purple.opacity(0.4))
        
                        Spacer()
                        
                        Button(action: {
                            selectedTab = .search
                        }) {
                            VStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search").font(.subheadline)
                            }
                        }.foregroundColor(selectedTab == .search ? .purple : .purple.opacity(0.4))
        
                        Spacer()
                    }
        }
        
    }
    
    func addRepo(addPicassoRepo: Bool) {
        if var newURL = URL(string: addrepoURL) {
            // Remove "manifest.json" if it's a Picasso repo
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
                Text(repo.name)
                    .font(.headline)
                Text(repo.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }.onAppear {
            if let iconURL = URL(string: repo.url!.appendingPathComponent(repo.icon).absoluteString) {
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

struct HomeView: View {
    @State private var autoRespring = true
    @State private var kopened = false
    @State private var enableResSet = false
    @State private var dev = false
    @State private var AggressiveApply = false
    
    // KFD:
    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    @State private var puafPagesIndex = 7
    @State private var puafPages = 0
    @State private var puafMethod = 1
    @State private var kreadMethod = 1
    @State private var kwriteMethod = 1
    @State private var RespringMode = 0
    
    var body: some View {
            Form {
                Section(header: Text("General Options")) {
                    ToggleSettingView(title: "Respring on Apply", isOn: $autoRespring)
                    ToggleSettingView(title: "Agressive Apply (Takes Longer)", isOn: $AggressiveApply)
                }
                
                Section(header: Text("Actions")) {
                    Button(action: {
                        UIApplication.shared.alert(title: "Applying...", body: "Please wait", animated: false, withButton: false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            Task {
                                exploit(puaf_pages: UInt64(puafPagesOptions[puafPagesIndex]), puaf_method: UInt64(puafMethod), kread_method: UInt64(kreadMethod), kwrite_method: UInt64(kwriteMethod)) //kopen
                                fix_exploit()

                                if AggressiveApply {
                                    for _ in 1...10 {
                                        applyAllTweaks()
                                    }
                                } else {
                                    applyAllTweaks()
                                }

                                close_exploit() //kclose
                                UIApplication.shared.dismissAlert(animated: false)
                                
                                if autoRespring {
                                    if RespringMode == 0 {
                                        backboard_respring()
                                    } else {
                                        respring()
                                    }
                                }
                            }
                        }
                    }) {
                        if autoRespring {
                            Text("Apply & Respring")
                                .settingButtonStyle()
                        } else {
                            Text("Apply")
                                .settingButtonStyle()
                        }
                    }
                    
                    Button(action: {
                        respring()
                    }) {
                        Text("Respring")
                            .settingButtonStyle()
                    }
                    
                    Button(action: {
                        close_exploit()
                        exit(0)
                    }) {
                        Text("Exit")
                            .settingButtonStyle()
                    }
                }
            }
            .navigationBarItems(trailing: NavigationLink(destination: settingsView) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .tint(.purple)
                }
            )
    }
    
    private var settingsView: some View {
        SettingsView(puafPagesIndex: $puafPagesIndex, puafMethod: $puafMethod, kreadMethod: $kreadMethod, kwriteMethod: $kwriteMethod, puafPages: $puafPages, RespringMode: $RespringMode)
            .navigationBarTitle("Settings")
    }
}

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Package] = []

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search Packages", text: $searchText)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 15)
                .onChange(of: searchText) { newValue in
                    searchResults = PackageManager.shared.searchPackages(with: newValue)
            }
            
            List(searchResults) { package in
                NavigationLink(destination: PackageDetailView(package: package)) {
                    PackageRow(package: package)
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
                Text(package.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
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



struct SettingsView: View {
    @Binding var puafPagesIndex: Int
    @Binding var puafMethod: Int
    @Binding var kreadMethod: Int
    @Binding var kwriteMethod: Int
    @Binding var puafPages: Int
    @Binding var RespringMode: Int

    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    private let puafMethodOptions = ["physpuppet", "smith"]
    private let kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    private let kwriteMethodOptions = ["dup", "sem_open"]
    private let RespringOptions = ["Backboard Respring", "Frontboard Respring"]

    var body: some View {
        Form {
            Section(header: Text("Exploit Settings")) {
                Picker("puaf pages:", selection: $puafPagesIndex) {
                    ForEach(0 ..< puafPagesOptions.count, id: \.self) {
                        Text(String(self.puafPagesOptions[$0]))
                    }
                }.tint(.purple).foregroundColor(.purple)

                Picker("puaf method:", selection: $puafMethod) {
                    ForEach(0 ..< puafMethodOptions.count, id: \.self) {
                        Text(self.puafMethodOptions[$0])
                    }
                }.tint(.purple).foregroundColor(.purple)

                Picker("kread method:", selection: $kreadMethod) {
                    ForEach(0 ..< kreadMethodOptions.count, id: \.self) {
                        Text(self.kreadMethodOptions[$0])
                    }
                }.tint(.purple).foregroundColor(.purple)

                Picker("kwrite method:", selection: $kwriteMethod) {
                    ForEach(0 ..< kwriteMethodOptions.count, id: \.self) {
                        Text(self.kwriteMethodOptions[$0])
                    }
                }.tint(.purple).foregroundColor(.purple)
            }
            Section(header: Text("Other Settings")) {
                Picker("Respring Mode:", selection: $RespringMode) {
                    ForEach(0 ..< RespringOptions.count, id: \.self) {
                        Text(String(self.RespringOptions[$0]))
                    }
                }.tint(.purple).foregroundColor(.purple)
            }
        }.navigationBarTitle("Settings", displayMode: .inline)
    }
}


struct ToggleSettingView: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 20) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.purple)
                    .imageScale(.large)
                    .tint(.purple)
                Text(title).font(.headline).foregroundColor(.purple)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .foregroundColor(.purple)
        .tint(.purple)
    }
}

extension Text {
    func settingButtonStyle() -> some View {
        self
            .foregroundColor(.purple)
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.purple, lineWidth: 2)
            )
    }
}

struct PicassoContentDetailsView: View {
    let repo: Repo
    @Binding var selectedRepo: SelectedItem?
    
    var body: some View {
        List(repo.packages, id: \.bundleid) { package in
            NavigationLink(destination: AppDetailView(pkg: package, MisakaPkg: nil, repo: repo, MisakaRepo: nil, picassoRepo: true)) {
                PicassoContentRow(name: package.name, author: package.author, icon: package.icon, repo: repo)
            }.foregroundColor(.purple)
        }
        .navigationTitle(repo.name)
    }
}

func isPackageInstalled(pkg: Package, repo: Repo) -> Bool {
    let installedFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Installed")
    let installedPackageFolderURL = installedFolderPath.appendingPathComponent(pkg.bundleid)
    
    return FileManager.default.fileExists(atPath: installedPackageFolderURL.path)
}
