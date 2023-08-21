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
                        
                        // Set the URL property of the repo
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
        case settings
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
                .navigationBarTitle("PurityKFD - Repos")
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
                    .navigationBarTitle("PurityKFD - Installed")
            } else if selectedTab == .home {
                HomeView().navigationBarTitle("PurityKFD", displayMode: .large)
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
                    URL(string: "https://raw.githubusercontent.com/Lrdsnow/lrdsnows-repo/main/PurityKFD/")!,
                    URL(string: "https://raw.githubusercontent.com/circularsprojects/circles-repo/main/")!,
                    URL(string: "https://raw.githubusercontent.com/sourcelocation/Picasso-test-repo/main/")!,
                    URL(string: "https://bomberfish.ca/PicassoRepos/Essentials/")!,
                ]
            }
            
            if MisakaRepoURLs.isEmpty {
                MisakaRepoURLs = [
                    URL(string: "https://raw.githubusercontent.com/shimajiron/Misaka_Network/main/repo.json")!,
                    URL(string: "https://raw.githubusercontent.com/34306/iPA/main/repo.json")!,
                    URL(string: "https://puck.roeegh.com/repo.json")!,
                ]
            }
            
            fetchPicassoRepos()
            fetchMisakaRepos()
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
                    self.PicassoRepos = fetchedRepos
            }
        }
    }
    
    func fetchMisakaRepos() {
        if !MisakaRepoURLs.isEmpty {
            viewModel.fetchRepositories(repoURLs: MisakaRepoURLs)
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
    
    // KFD:
    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    @State private var puafPagesIndex = 7
    @State private var puafPages = 0
    @State private var puafMethod = 1
    @State private var kreadMethod = 1
    @State private var kwriteMethod = 1
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General Options")) {
                    ToggleSettingView(title: "Respring on Apply", isOn: $autoRespring)
                }
                
                Section(header: Text("Actions")) {
                    Button(action: {
                        UIApplication.shared.alert(title: "Applying...", body: "Please wait", animated: false, withButton: false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            Task {
                                exploit(puaf_pages: UInt64(puafPagesOptions[puafPagesIndex]), puaf_method: UInt64(puafMethod), kread_method: UInt64(kreadMethod), kwrite_method: UInt64(kwriteMethod))
                                fix_exploit()
                                applyAllTweaks()
                                close_exploit()
                                UIApplication.shared.dismissAlert(animated: false)
                                if autoRespring {
                                    backboard_respring()
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
                    if dev {
                        Button(action: {
                            exploit(puaf_pages: UInt64(2048), puaf_method: UInt64(1), kread_method: UInt64(1), kwrite_method: UInt64(1))
                            do_fun()
                            close_exploit()
                            if autoRespring {
                                respring()
                            }
                        }) {
                            Text("Fun")
                                .settingButtonStyle()
                        }
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
    }
    
    private var settingsView: some View {
        SettingsView(puafPagesIndex: $puafPagesIndex, puafMethod: $puafMethod, kreadMethod: $kreadMethod, kwriteMethod: $kwriteMethod, puafPages: $puafPages)
            .navigationBarTitle("Settings")
    }
}

struct SettingsView: View {
    @Binding var puafPagesIndex: Int
    @Binding var puafMethod: Int
    @Binding var kreadMethod: Int
    @Binding var kwriteMethod: Int
    @Binding var puafPages: Int

    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    private let puafMethodOptions = ["physpuppet", "smith"]
    private let kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    private let kwriteMethodOptions = ["dup", "sem_open"]

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
            NavigationLink(destination: AppDetailView(pkg: package, MisakaPkg: nil, repo: repo, picassoRepo: true)) {
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


struct AppDetailView: View {
    let pkg: Package?
    let MisakaPkg: Content?
    let repo: Repo?
    let picassoRepo: Bool
    @State private var contentIcon: UIImage? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    func picasso(pkg: Package, repo: Repo) {
        if let pkgURL = URL(string: (repo.url!.appendingPathComponent(pkg.path).absoluteString)) {
            if let iconURL = URL(string: (repo.url!.appendingPathComponent(pkg.icon).absoluteString)) {
                downloadAndExtractJSONFiles(from: pkgURL, icon: iconURL) { success in
                    if success {
                        alertTitle = "Success"
                        alertMessage = "Package \"\(pkg.name)\" was successfully downloaded and installed."
                    } else {
                        alertTitle = "Error"
                        alertMessage = "Failed to download and install package"
                    }
                    showAlert = true
                }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 16) {
                    if let icon = contentIcon {
                        Image(uiImage: icon)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pkg?.name ?? MisakaPkg?.Name ?? "Not Found")
                            .font(.title).bold()
                            .foregroundColor(.purple)
                        Text(pkg?.author ?? MisakaPkg?.Author?.Label ?? "Not Found")
                            .font(.subheadline)
                            .foregroundColor(.purple.opacity(0.7))
                        if picassoRepo {
                            if isPackageInstalled(pkg: pkg!, repo: repo!) {
                                Text("Installed")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 5)
                                    .background(Color.purple.opacity(0.7))
                                    .cornerRadius(50)
                            } else {
                                Button(action: {
                                    picasso(pkg: pkg!, repo: repo!)
                                }) {
                                    Text("Install")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 5)
                                        .background(Color.purple)
                                        .cornerRadius(50)
                                }
                            }
                        } else {
                                Button(action: {
                                    // Handle install action
                                }) {
                                    Text("Coming Soon")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 5)
                                        .background(Color.purple.opacity(0.7)) // Customize button color
                                        .cornerRadius(50)
                                }.disabled(true)
                            }
                        }
                    }
                    //.padding() // Add padding only to the VStack if needed
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    .onAppear {
                        if picassoRepo {
                            if let iconURL = URL(string: (repo?.url!.appendingPathComponent(pkg!.icon).absoluteString)!) {
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
                        } else {
                            if let iconURL = URL(string: MisakaPkg!.Icon ?? "NoIcon") {
                                if iconURL != URL(string: "NoIcon") {
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
                Text("Description").bold().padding(.vertical, 5).font(.title2).foregroundColor(.purple)
                Text(pkg?.description ?? MisakaPkg?.Description ?? "No description found for this package").foregroundColor(.purple)
            }
        }
    }
