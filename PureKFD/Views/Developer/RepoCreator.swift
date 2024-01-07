//
//  RepoCreator.swift
//  PureKFD
//
//  Created by Lrdsnow on 12/22/23.
//

import Foundation
import SwiftUI
import WebKit
import OctoKit
import QuickLook

class Github: NSObject, WKNavigationDelegate {
    var accessTokenCompletion: ((String?) -> Void)?
    var repos: [Repository] = []
    
    func handleAuthorizationCode(_ code: String?, completion: @escaping (String?) -> Void) {
        let clientId = "106f6a7cce8861504a0d"
        let clientSecret = ""
        let tokenUrl = "https://github.com/login/oauth/access_token"
        let tokenBody = "client_id=\(clientId)&client_secret=\(clientSecret)&code=\(code ?? "")&redirect_uri=purekfd://github-oauth-callback"
        
        if let url = URL(string: "https://github.com/login/oauth/access_token") {
            log(url)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = tokenBody.data(using: .utf8)
            
            let task : URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    completion(nil)
                } else if let data = data {
                    let dataStr = String(data: data, encoding: .utf8)
                    if let dataStr = dataStr {
                        let dataArr = dataStr.components(separatedBy: "&")
                        let token = dataArr.first?.components(separatedBy: "=").last
                        if let token = token {
                            completion(token)
                        } else {
                            log("ERROR: Invalid Token")
                            completion(nil)
                        }
                    } else {
                        log("ERROR: Invalid Data")
                        completion(nil)
                    }
                }
            }
            
            task.resume()
        }
    }
    
    func getUsername(_ token: String, completion: @escaping (String?) -> Void) {
      let config = TokenConfiguration(token)
      Octokit(config).me() { response in
        switch response {
        case .success(let user):
            completion(user.login)
        case .failure(let error):
            log("Error: \(error)")
            completion(nil)
        }
      }
    }
    
    func getRepos(_ token: String, _ username: String, completion: @escaping ([Repository]?) -> Void) {
        let configuration = TokenConfiguration(token)
        let client = Octokit(configuration)
        client.repositories() { response in
            switch response {
            case .success(let repositories):
                for repo in repositories {
                    if repo.owner.login == username {
                        self.repos.append(repo)
                    }
                }
                completion(self.repos)
            case .failure(let error):
                log("Error: \(error)")
                completion(nil)
            }
        }
    }
    
    func getTreeContents(_ token: String, _ repo: Repository, _ tree_sha: String, completion: @escaping ([ghFile]) -> Void) {
        let url = URL(string: "https://api.github.com/repos/\(repo.owner.login ?? "")/\(repo.name ?? "")/git/trees/\(tree_sha)?recursive=true")!
        var request = URLRequest(url: url)
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        let task: URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                log("Error: \(error)")
            } else if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
                    if let tree = json["tree"] as? [[String: Any]] {
                        var ret: [ghFile] = []
                        for index in tree.indices {
                            let file = tree[index]
                            ret.append(
                                ghFile(path: file["path"] as? String ?? "",
                                       type: file["type"] as? String ?? "",
                                       sha: file["sha"] as? String ?? "",
                                       url: file["url"] as? String ?? ""
                                )
                            )
                        }
                        completion(ret)
                    }
                } catch {
                    log("Error decoding JSON: \(error)")
                }
            }
        }
        
        task.resume()
    }
    
    func getFileContents(_ token: String, _ url: String, completion: @escaping (String?) -> Void) {
        let Url = URL(string: url)!
        var request = URLRequest(url: Url)
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        let task: URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                log("Error: \(error)")
                completion(nil)
            } else if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
                    completion(json["content"] as? String)
                } catch {
                    log("Error decoding JSON: \(error)")
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
}

func findRepos(_ node: ghFileTreeNode?, result: inout [ghFileTreeNode]) {
    if let node = node {
        for child in node.children {
            if child.value.path == ".purekfd_config" {
                result.append(node)
                break
            }
            findRepos(child, result: &result)
        }
    }
}

struct ghRepo {
    let id: String = "\(UUID())"
    var repo: Repository
    var tree: ghFileTreeNode
}

func buildFileTree(_ ghFiles: [ghFile]) -> ghFileTreeNode {
    let root = ghFileTreeNode(value: ghFile())

    for ghFile in ghFiles {
        var newGhFile = ghFile
        let components = ghFile.path.components(separatedBy: "/")
        newGhFile.path = components.last ?? newGhFile.path
        var current = root

        for component in components {
            if !component.isEmpty {
                if let existingChild = current.children.first(where: { $0.value.path == component }) {
                    current = existingChild
                } else {
                    let newChild = ghFileTreeNode(value: newGhFile)
                    current.children.append(newChild)
                    current = newChild
                }
            }
        }
    }

    return root
}

func printFileTree(_ node: ghFileTreeNode?, indent: String = "") -> String {
    if let node = node {
        var tree = indent + node.value.path + "\n"
        
        for child in node.children {
            tree += printFileTree(child, indent: indent + "    ")
        }
        
        return tree
    }
    return ""
}

struct ghData {
    var token: String? = nil
    var username: String? = nil
    var repos: [ghRepo] = []
    var repo_files: [String:ghFileTreeNode] = [:]
    var purekfd_repos: [(ghRepo, [ghFileTreeNode])] = []
}

struct ghFile {
    let id: String = "\(UUID())"
    var path: String = ""
    var type: String = ""
    var sha: String = ""
    var url: String = ""
}

class ghFileTreeNode {
    var value: ghFile
    var children: [ghFileTreeNode]

    init(value: ghFile) {
        self.value = value
        self.children = []
    }
}

struct FileTreeView: View {
    var node: ghFileTreeNode
    @State private var isExpanded = false
    let github: Github
    @Binding var gh: ghData

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                ForEach(node.children, id: \.value.id) { childNode in
                    if !childNode.children.isEmpty {
                        FileTreeView(node: childNode, github: github, gh: $gh)
                    } else {
                        NavigationLink(destination: ghFileOverview(file: childNode.value, github: github, gh: $gh)) {
                            Text(childNode.value.path)
                                .padding(.leading, 20)
                        }
                    }
                }
            },
            label: {
                Text(node.value.path)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
    }
}

class QLPreviewControllerDataSourceURL: NSObject, QLPreviewControllerDataSource {
    let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return NSURL(fileURLWithPath: filePath) as QLPreviewItem
    }
}

struct ghFileOverview: View {
    let file: ghFile
    let github: Github
    @Binding var gh: ghData
    @State private var qlPreviewDataSource: QLPreviewControllerDataSourceURL?
    
    var body: some View {
        List {
            Section("General Info") {
                HStack {
                    Text("Name:")
                    Spacer()
                    Text(file.path)
                }
                HStack {
                    Text("Type:")
                    Spacer()
                    Text(file.type)
                }
                HStack {
                    Text("Sha:")
                    Spacer()
                    Text(file.sha)
                }
            }.listBG()
            Section() {
                Button(action: {
                    UIApplication.shared.alert(title: "Downloading...", body: "Please wait...", withButton: false)
                    github.getFileContents(gh.token ?? "", file.url) { contents in
                        UIApplication.shared.dismissAlert(animated: false)
                        if let contents = contents {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                openInQuickLook(contents)
                            }
                        } else {
                            UIApplication.shared.alert(title: "Failed!", body: "Something went wrong", withButton: true)
                        }
                    }
                }, label: {
                    Text("Download File")
                })
            }.listBG()
        }.listStyle(.insetGrouped).clearBG().bgImage().navigationTitle("File Info")
    }
    
    func openInQuickLook(_ base64String: String) {
        guard let data = Data(base64Encoded: base64String.replacingOccurrences(of: "\n", with: "")) else {
            log("Invalid base64 string")
            return
        }
        
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectory.appendingPathComponent(file.path)
        try? FileManager.default.removeItem(at: temporaryFileURL)
        
        do {
            try data.write(to: temporaryFileURL)
            qlPreviewDataSource = QLPreviewControllerDataSourceURL(filePath: temporaryFileURL.path)
            
            let qlPreviewController = QLPreviewController()
            qlPreviewController.dataSource = qlPreviewDataSource
            log(temporaryFileURL)
            UIApplication.shared.windows.first?.rootViewController?.present(qlPreviewController, animated: true, completion: nil)
        } catch {
            log("Error writing data to file: \(error.localizedDescription)")
        }
    }
}

struct RepoOverview: View {
    let github: Github
    @Binding var gh: ghData
    let repo: ghRepo
    
    var body: some View {
        List {
            Section("General Info") {
                HStack {
                    Text("Name:")
                    Spacer()
                    Text(repo.repo.name ?? "unknown repo")
                }
                HStack {
                    Text("Description:")
                    Spacer()
                    Text(repo.repo.repositoryDescription ?? "unknown desc")
                }
                HStack {
                    Text("URL:")
                    Spacer()
                    Text(repo.repo.htmlURL ?? "no github url")
                }
            }.listBG()
            Section("Contents") {
                ForEach(repo.tree.children, id: \.value.id) { childNode in
                    if !childNode.children.isEmpty {
                        FileTreeView(node: childNode, github: github, gh: $gh)
                    } else {
                        NavigationLink(destination: ghFileOverview(file: childNode.value, github: github, gh: $gh)) {
                            Text(childNode.value.path)
                                .padding(.leading, 20)
                        }
                    }
                }
            }.listBG()
        }.listStyle(.insetGrouped).clearBG().bgImage().navigationTitle("Repo Info")
    }
}

struct GithubPureKFDRepoOverview: View {
    @EnvironmentObject var appData: AppData
    let github: Github
    @Binding var gh: ghData
    let ghrepo: ghRepo
    let tree: ghFileTreeNode
    @State private var repos: [Repo] = []
    
    var body: some View {
        List {
            Section("Github Repo Info") {
                HStack {
                    Text("Name:")
                    Spacer()
                    Text(ghrepo.repo.name ?? "unknown repo")
                }
                HStack {
                    Text("Description:")
                    Spacer()
                    Text(ghrepo.repo.repositoryDescription ?? "unknown desc")
                }
                HStack {
                    Text("URL:")
                    Spacer()
                    Text(ghrepo.repo.htmlURL ?? "no github url")
                }
            }.listBG()
            if !repos.isEmpty {
                Section("Repo Info") {
                    if repos.count == 1 {
                        HStack {
                            Text("Name:")
                            Spacer()
                            Text(repos[0].name)
                        }
                        HStack {
                            Text("Description:")
                            Spacer()
                            Text(repos[0].desc)
                        }
                        HStack {
                            Text("Tweak Count:")
                            Spacer()
                            Text("\(repos[0].packages.count)")
                        }
                    } else {
                        ForEach(repos, id: \.id) { repo in
                            DisclosureGroup(content: {
                                HStack {
                                    Text("Name:")
                                    Spacer()
                                    Text(repo.name)
                                }
                                HStack {
                                    Text("Description:")
                                    Spacer()
                                    Text(repo.desc)
                                }
                                HStack {
                                    Text("Tweak Count:")
                                    Spacer()
                                    Text("\(repo.packages.count)")
                                }
                            }, label: {Text(repo.name)})
                        }
                    }
                }.listBG()
            } else {
                Section() {
                    HStack {
                        Text("Getting PureKFD Repo...")
                        Spacer()
                        ProgressView()
                    }
                }.listBG().task() {
                    for file in tree.children {
                        if file.value.type == "blob", file.value.path.contains(".json"), !file.value.path.contains("bridge.json") {
                            github.getFileContents(gh.token ?? "", file.value.url) { contents in
                                Task {
                                    let data = Data(base64Encoded: (contents ?? "").replacingOccurrences(of: "\n", with: ""))
                                    let temp_repo = await getRepoInfo("https://github.com/", appData: appData, usedata: data)
                                    if temp_repo.name != "Unknown" {
                                        repos.append(temp_repo)
                                        log("added pkfd repo \(temp_repo.name)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }.listStyle(.insetGrouped).clearBG().bgImage().navigationTitle("Repo Info")
    }
}

struct RepoCreatorView: View {
    @EnvironmentObject var appData: AppData
    @State private var showWebView = false
    @State private var gh = ghData()
    var github = Github()
    
    var body: some View {
        VStack {
            if gh.purekfd_repos.isEmpty {
                if gh.repos.isEmpty {
                    Button(action: {
                        showWebView.toggle()
                    }) {
                        Text("Login with GitHub")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    List(gh.repos, id: \.id) { repo in
                        //if !repo.isPrivate {
                        NavigationLink(destination: RepoOverview(github: github, gh: $gh, repo: repo), label: {
                            Text(repo.repo.name ?? "unknown repo")
                        }).listBG()
                        //}
                    }.listStyle(.insetGrouped).clearBG()
                }
            } else {
                if gh.purekfd_repos.count >= 2 {
                    List {
                        ForEach(gh.purekfd_repos.indices, id: \.self) { index in
                            
                        }
                    }.listStyle(.insetGrouped).clearBG()
                } else {
                    GithubPureKFDRepoOverview(appData: _appData, github: github, gh: $gh, ghrepo: gh.purekfd_repos[0].0, tree: gh.purekfd_repos[0].1[0])
                }
            }
        }.bgImage(appData).navigationTitle("Repo Creator").sheet(isPresented: $showWebView) {
            NavigationView {
                WebView(coordinator: github, isPresented: $showWebView)
                    .navigationTitle("Login")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing:
                        Button("Close") {
                            showWebView = false
                        }
                    )
            }.blurredBG()
        }.onAppear() {
            if gh.repos.isEmpty {
                if let token = appData.UserData.ghToken {
                    UIApplication.shared.alert(title: "Logging in...", body: "Please wait...", withButton: false)
                    gh.token = token
                    github.getUsername(token) { username in
                        gh.username = username
                        github.getRepos(token, username ?? "")  { repositories in
                            for repo in repositories ?? [] {
                                github.getTreeContents(gh.token ?? "", repo, "main") { result in
                                    let tree = buildFileTree(result)
                                    let ghrepo = ghRepo(repo: repo,
                                                        tree: tree)
                                    gh.repos.append(ghrepo)
                                    var subRepos: [ghFileTreeNode] = []
                                    findRepos(tree, result: &subRepos)
                                    if !subRepos.isEmpty {
                                        gh.purekfd_repos.append((ghrepo, subRepos))
                                    }
                                }
                            }
                            UIApplication.shared.dismissAlert(animated: true)
                        }
                    }
                }
            }
        }
        .onOpenURL { url in
            if url.scheme == "purekfd" && url.host == "github-oauth-callback" {
                let components = URLComponents(string: url.absoluteString)
                let queryItems = components?.queryItems ?? []
                let codeQueryItem = queryItems.first(where: { $0.name == "code" })
                let code = codeQueryItem?.value
                github.handleAuthorizationCode(code) { token in
                    gh.token = token
                    appData.UserData.ghToken = token
                    github.getUsername(token ?? "") { username in
                        gh.username = username
                        github.getRepos(token ?? "", username ?? "")  { repositories in
                            for repo in repositories ?? [] {
                                github.getTreeContents(gh.token ?? "", repo, "main") { result in
                                    let tree = buildFileTree(result)
                                    gh.repos.append(
                                        ghRepo(repo: repo,
                                               tree: tree)
                                    )
                                }
                            }
                            appData.save()
                            showWebView = false
                            if gh.repos.isEmpty {
                                UIApplication.shared.alert(title: "Failed!", body: "An Unknown Error Occured.", withButton: true)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct WebView: UIViewControllerRepresentable {
    var coordinator: Github
    @Binding var isPresented: Bool
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let requestUrl = navigationAction.request.url, requestUrl.isCustomUrlScheme() {
                decisionHandler(.cancel)
                UIApplication.shared.open(requestUrl, options: [:]) { success in
                    if !success {
                        
                    }
                }
            } else {
                decisionHandler(.allow)
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            log("Failed to load with error: \(error.localizedDescription)")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.userContentController = WKUserContentController()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        viewController.view = webView
        
        // Load the GitHub login URL
        if let url = URL(string: "https://github.com/login/oauth/authorize?client_id=106f6a7cce8861504a0d&scope=repo") {
            var request = URLRequest(url: url)
            let cookies = HTTPCookieStorage.shared.cookies(for: url)
            let headers = HTTPCookie.requestHeaderFields(with: cookies ?? [])
            request.allHTTPHeaderFields = headers
            webView.load(request)
        }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update UI if needed
    }
    
    typealias UIViewControllerType = UIViewController
}
