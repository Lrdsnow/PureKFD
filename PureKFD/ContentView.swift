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
//START LOG
var LogItems: [String.SubSequence] = [IsSupported() ? "Ready!" : "Unsupported", "iOS: \(GetiOSBuildID())"]

func IsSupported() -> Bool {
    let SupportedVersions = ["19A346", "19A348", "19A404", "19B75", "19C56", "19C63", "19D50", "19D52", "19E241", "19E258", "19F77", "19G71", "19G82", "19H12", "19H117", "19H218", "19H307", "19H321", "19H332", "19H349", "20A362", "20A371", "20A380", "20A392", "20B82", "20B101", "20B110", "20C65", "20D47", "20D67", "20E247", "20E252", "20F66", "20G5026e", "20G5037d", "20F5028e", "20F5039e", "20F5050f", "20F5059a", "20F65", "20E5212f", "20E5223e", "20E5229e", "20E5239b", "20E246", "20D5024e", "20D5035i", "20C5032e", "20C5043e", "20C5049e", "20C5058d", "20B5045d", "20B5050f", "20B5056e", "20B5064c", "20B5072b", "20B79"]
    return SupportedVersions.contains(GetiOSBuildID())
}

func GetiOSBuildID() -> String {
    NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")!.value(forKey: "ProductBuildVersion") as! String
}
func FetchLog() {
    guard let AttributedText = LogStream.shared.outputString.copy() as? NSAttributedString else {
        LogItems = ["Error Getting Log!"]
        return
    }
    LogItems = AttributedText.string.split(separator: "\n")
}
class LogStream {
    static let shared = LogStream()
    private(set) var outputString: NSMutableAttributedString = NSMutableAttributedString()
    public let reloadNotification = Notification.Name("LogStreamReloadNotification")
    private(set) var outputFd: [Int32] = [0, 0]
    private(set) var errFd: [Int32] = [0, 0]
    private let readQueue: DispatchQueue
    private let outputSource: DispatchSourceRead
    private let errorSource: DispatchSourceRead
    init() {
        readQueue = DispatchQueue(label: "org.coolstar.sileo.logstream", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        guard pipe(&outputFd) != -1,
            pipe(&errFd) != -1 else {
                fatalError("pipe failed")
        }
        let origOutput = dup(STDOUT_FILENO)
        let origErr = dup(STDERR_FILENO)
        setvbuf(stdout, nil, _IONBF, 0)
        guard dup2(outputFd[1], STDOUT_FILENO) >= 0,
            dup2(errFd[1], STDERR_FILENO) >= 0 else {
                fatalError("dup2 failed")
        }
        outputSource = DispatchSource.makeReadSource(fileDescriptor: outputFd[0], queue: readQueue)
        errorSource = DispatchSource.makeReadSource(fileDescriptor: errFd[0], queue: readQueue)
        outputSource.setCancelHandler {
            close(self.outputFd[0])
            close(self.outputFd[1])
        }
        errorSource.setCancelHandler {
            close(self.errFd[0])
            close(self.errFd[1])
        }
        let bufsiz = Int(BUFSIZ)
        outputSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }
            let bytesRead = read(self.outputFd[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1 && errno == EAGAIN {
                    return
                }
                self.outputSource.cancel()
                return
            }
            write(origOutput, buffer, bytesRead)
            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                let textColor = UIColor.white
                //let substring = NSMutableAttributedString(string: str, attributes: [NSAttributedString.Key.foregroundColor: textColor])
                //self.outputString.append(substring)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: self.reloadNotification, object: nil)
                }
            }
        }
        errorSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }
            let bytesRead = read(self.errFd[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1 && errno == EAGAIN {
                    return
                }
                self.errorSource.cancel()
                return
            }
            write(origErr, buffer, bytesRead)
            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                let textColor = UIColor(red: 219/255.0, green: 44.0/255.0, blue: 56.0/255.0, alpha: 1)
                let substring = NSMutableAttributedString(string: str, attributes: [NSAttributedString.Key.foregroundColor: textColor])
                self.outputString.append(substring)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: self.reloadNotification, object: nil)
                }
            }
        }
        outputSource.resume()
        errorSource.resume()
    }
}
//END LOG
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
    init() {
        // CleanUP
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let extractedFolderPath = documentsDirectory.appendingPathComponent("Misaka/Extracted")
        let downloadFolderPath = documentsDirectory.appendingPathComponent("Misaka/Download")
        let zipFileURL = documentsDirectory.appendingPathComponent("Misaka/downloaded.zip")
        let PicassoExtractedFolderPath = documentsDirectory.appendingPathComponent("Extracted")
        let PicassoTempPath = documentsDirectory.appendingPathComponent("TempOverwriteFile")
        let PicassoBackgroundFolderPath = documentsDirectory.appendingPathComponent("Background_Files")
        do {
            try fileManager.removeItem(atPath: extractedFolderPath.path)
        } catch {
            print("")
        }
        do {
            try fileManager.removeItem(at: downloadFolderPath)
        } catch {
            print("")
        }
        do {
            try fileManager.removeItem(at: zipFileURL)
        } catch {
            print("")
        }
        // MDC Grant Full Disk
//        if checkiOSVersionRange() == .mdc {
//            grant_full_disk_access() { error in
//                if (error != nil) {
//                    UIApplication.shared.alert(body: "\(String(describing: error?.localizedDescription))\nPlease close the app and retry.")
//                    return
//                }
//            }
//        }
    }
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
    @State private var dev: Bool = false
    
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
                HomeView(dev: $dev).navigationBarTitle("PureKFD", displayMode: .large)
            } else if selectedTab == .search {
                SearchView().navigationBarTitle("PureKFD - Search", displayMode: .large)
            }
        }
        .onAppear {
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
            DispatchQueue.global(qos: .utility).async {
                                 FetchLog()
                             }
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



struct LogView: View {
    @State private var isSharing: Bool = false
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scroll in
                    VStack(alignment: .leading) {
                        ForEach(0..<LogItems.count, id: \.self) { LogItem in
                            Text("[*] \(String(LogItems[LogItem]))")
                                .textSelection(.enabled)
                                .font(.custom("Menlo", size: 15))
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: LogStream.shared.reloadNotification)) { obj in
                        DispatchQueue.global(qos: .utility).async {
                            FetchLog()
                            scroll.scrollTo(LogItems.count - 1)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(20)
            
            Button(action: {
                isSharing = true
            }) {
                Text("Share Log")
                    .padding()
                    .foregroundColor(.purple) // Set the text color to purple
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.purple, lineWidth: 2) // Add purple outline
                    )
            }
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width - 50, height: 600)
        .sheet(isPresented: $isSharing, onDismiss: {
            // Optional: Add any cleanup or actions after sharing is dismissed
        }) {
            // Content of the share sheet
            ActivityView(activityItems: [shareableLogContent()])
        }
    }
    
    private func shareableLogContent() -> String {
        // Generate a shareable string from LogItems
        let logContent = LogItems.map { "[*] \($0)" }.joined(separator: "\n")
        return logContent
    }
}

struct ActivityView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController
    
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Update the view controller if needed
    }
}

enum iOSVersionRange {
    case mdc
    case kfd
    case other
}

func checkiOSVersionRange() -> iOSVersionRange {
    let systemVersion = UIDevice.current.systemVersion
    let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }

    if versionComponents.count >= 2 {
        let major = versionComponents[0]
        let minor = versionComponents[1]

        if (major == 14 && minor >= 0 && minor <= 7) ||
           (major == 15 && minor >= 0 && minor <= 7) ||
           (major == 16 && minor >= 0 && minor <= 1) {
            return .mdc
        } else if (major == 16 && minor >= 2 && minor <= 5) ||
                  (major == 16 && minor == 6) {
            return .kfd
        }
    }

    return .other
}

class UserSettings: ObservableObject {
    @Published var autoRespring: Bool {
        didSet {
            UserDefaults.standard.set(autoRespring, forKey: "autoRespring")
        }
    }
    @Published var dev: Bool {
        didSet {
            UserDefaults.standard.set(dev, forKey: "dev")
        }
    }
    @Published var exploit_method: Int {
        didSet {
            UserDefaults.standard.set(exploit_method, forKey: "exploit_method")
        }
    }
    @Published var enforce_exploit_method: Bool {
        didSet {
            UserDefaults.standard.set(enforce_exploit_method, forKey: "enforce_exploit_method")
        }
    }
    
    @Published var puafPagesIndex: Int {
        didSet {
            UserDefaults.standard.set(puafPagesIndex, forKey: "puafPagesIndex")
        }
    }
    @Published var puafMethod: Int {
        didSet {
            UserDefaults.standard.set(puafMethod, forKey: "puafMethod")
        }
    }
    @Published var kreadMethod: Int {
        didSet {
            UserDefaults.standard.set(kreadMethod, forKey: "kreadMethod")
        }
    }
    @Published var kwriteMethod: Int {
        didSet {
            UserDefaults.standard.set(kwriteMethod, forKey: "kwriteMethod")
        }
    }
    @Published var puafPages: Int {
        didSet {
            UserDefaults.standard.set(puafPages, forKey: "puafPages")
        }
    }
    @Published var RespringMode: Int {
        didSet {
            UserDefaults.standard.set(RespringMode, forKey: "RespringMode")
        }
    }

    init() {
        self.autoRespring = UserDefaults.standard.bool(forKey: "autoRespring")
        self.dev = UserDefaults.standard.bool(forKey: "dev")
        self.exploit_method = UserDefaults.standard.integer(forKey: "exploit_method")
        self.enforce_exploit_method = UserDefaults.standard.bool(forKey: "enforce_exploit_method")
        self.puafPagesIndex = UserDefaults.standard.integer(forKey: "puafPagesIndex")
        self.puafMethod = UserDefaults.standard.integer(forKey: "puafMethod")
        self.kreadMethod = UserDefaults.standard.integer(forKey: "kreadMethod")
        self.kwriteMethod = UserDefaults.standard.integer(forKey: "kwriteMethod")
        self.puafPages = UserDefaults.standard.integer(forKey: "puafPages")
        self.RespringMode = UserDefaults.standard.integer(forKey: "RespringMode")
        if UserDefaults.standard.object(forKey: "puafPagesIndex") == nil {
            self.puafPagesIndex = 7
        }
        if UserDefaults.standard.object(forKey: "puafPages") == nil {
            self.puafPages = 0
        }
        if UserDefaults.standard.object(forKey: "puafMethod") == nil {
            self.puafMethod = 1
        }
        if UserDefaults.standard.object(forKey: "kreadMethod") == nil {
            self.kreadMethod = 1
        }
        if UserDefaults.standard.object(forKey: "kwriteMethod") == nil {
            self.kwriteMethod = 1
        }
        if UserDefaults.standard.object(forKey: "RespringMode") == nil {
            self.RespringMode = 0
        }
    }
}


struct HomeView: View {
    @StateObject private var userSettings = UserSettings()
    @State private var autoRespring = false
    @State private var exploit_method = 0
    @State private var enforce_exploit_method = false
    
    // KFD:
    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    @State private var puafPagesIndex = 7
    @State private var puafPages = 0
    @State private var puafMethod = 1
    @State private var kreadMethod = 1
    @State private var kwriteMethod = 1
    @State private var RespringMode = 0
    @Binding var dev: Bool
  
    var body: some View {
            Form {
//                Section(header: Text("General Options")) {
//                    ToggleSettingView(title: "Respring on Apply", isOn: $userSettings.autoRespring)
//                    ToggleSettingView(title: "Developer Mode", isOn: $userSettings.dev)
//                }
                
                Section(header: Text("Actions")) {
                    Button(action: {
                        UIApplication.shared.alert(title: "Applying...", body: "Please wait", animated: false, withButton: false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            Task {
                                if !enforce_exploit_method {
                                    if checkiOSVersionRange() == .mdc {
                                        exploit_method = 1
                                    } else if checkiOSVersionRange() == .kfd {
                                        exploit_method = 0
                                    } else {
                                        exploit_method = 2
                                    }
                                }
                                
                                if !(exploit_method == -1) {
                                    if exploit_method == 0 {
                                        exploit(puaf_pages: UInt64(puafPagesOptions[puafPagesIndex]), puaf_method: UInt64(puafMethod), kread_method: UInt64(kreadMethod), kwrite_method: UInt64(kwriteMethod)) //kopen
                                        fix_exploit()
                                    }
                                    
                                    applyAllTweaks(exploit_method: exploit_method)
                                    
                                    
                                    if exploit_method == 0 {
                                        close_exploit() //kclose
                                    }
                                    
                                    UIApplication.shared.dismissAlert(animated: false)
                                    
//                                    if userSettings.autoRespring {
//                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                                            if RespringMode == 0 {
//                                                backboard_respring()
//                                            } else if RespringMode == 1 {
//                                                respring()
//                                            }
//                                        }
//                                    }
                                }
                            }
                        }
                    }) {
                        if userSettings.autoRespring {
                            Text("Apply")
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
                Section("Notice") {
                    Text("Version: 3.3\n\nNotes: Misaka package support is in its early stages\n\nUsage: Install a package (I recommend the NothingOS font), Hit apply & then hit respring")
                }
            }
            .navigationBarItems(
                trailing: HStack {
                    NavigationLink(destination: LogView().navigationBarTitle("PureKFD - Logs", displayMode: .large)) {
                        Image(systemName: "terminal")
                            .font(.system(size: 20))
                            .tint(.purple)
                    }
                    NavigationLink(destination: SettingsView(
                        puafPagesIndex: $userSettings.puafPagesIndex,
                        puafMethod: $userSettings.puafMethod,
                        kreadMethod: $userSettings.kreadMethod,
                        kwriteMethod: $userSettings.kwriteMethod,
                        puafPages: $userSettings.puafPages,
                        RespringMode: $userSettings.RespringMode,
                        exploit_method: $userSettings.exploit_method,
                        enforce_exploit_method: $userSettings.enforce_exploit_method
                    )) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .tint(.purple)
                    }
                }
            )
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



struct SettingsView: View {
    @Binding var puafPagesIndex: Int
    @Binding var puafMethod: Int
    @Binding var kreadMethod: Int
    @Binding var kwriteMethod: Int
    @Binding var puafPages: Int
    @Binding var RespringMode: Int
    @Binding var exploit_method: Int
    @Binding var enforce_exploit_method: Bool

    private let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    private let puafMethodOptions = ["physpuppet", "smith"]
    private let kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    private let kwriteMethodOptions = ["dup", "sem_open"]
    private let RespringOptions = ["Backboard Respring", "Frontboard Respring"]
    private let ExploitOptions = ["KFD", "MDC", "TrollStore"]

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
                
                Toggle(isOn: $enforce_exploit_method) {
                    Text("Override Exploit Method").font(.headline).foregroundColor(.purple)
                }
                if enforce_exploit_method {
                    Picker("Exploit:", selection: $exploit_method) {
                        ForEach(0 ..< ExploitOptions.count, id: \.self) {
                            Text(String(self.ExploitOptions[$0]))
                        }
                    }.tint(.purple).foregroundColor(.purple)
                }
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
    
    if !FileManager.default.fileExists(atPath: installedPackageFolderURL.path) {
        let MisakainstalledFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Misaka/Installed")
        let MisakainstalledPackageFolderURL = MisakainstalledFolderPath.appendingPathComponent(pkg.bundleid)
        return FileManager.default.fileExists(atPath: MisakainstalledPackageFolderURL.path)
    } else {
        return FileManager.default.fileExists(atPath: installedPackageFolderURL.path)
    }
}
