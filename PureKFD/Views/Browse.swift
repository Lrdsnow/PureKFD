//
//  Browse.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import SwiftUI
import SDWebImageSwiftUI
import MarqueeText
import TextFieldAlert

struct BrowseView: View {
    @State private var isAddingRepoURLAlertPresented = false
    @State private var isAddingRepoURLAlert16Presented = false
    @State private var newRepoURL = ""
    @EnvironmentObject var appData: AppData
    @State private var repoSections: [String:[Repo]] = [:]
    @State private var reloading = false
    
    var body: some View {
        if !repoSections.isEmpty {
            NavigationView {
                List {
                    let repoTypes = sortedRepoTypes()
                    ForEach(repoTypes, id: \.self) { repoType in
                        if let repos = appData.repoSections[repoType]?.sorted(by: { $0.name < $1.name }) {
                            Section(header: Text(repoType.capitalized.replacingOccurrences(of: "PureKFD", with: "PureKFD") + " Repos")) {
                                ForEach(repos.sorted(by: { $0.name < $1.name })) { repo in
                                    NavigationLink(destination: RepoView(repo: repo, appData: appData).navigationTitle(repo.name).if(repo.accent != nil) { view in
                                        view.accentColor(repo.accent!.toColor())
                                    }) {
                                        RepoRow(reponame: repo.name, repodesc: repo.desc, repoicon: repo.icon, repo: repo, appData: appData)
                                    }
                                }
                            }.hideListRowSeparator()
                        }
                    }
                }
                .onAppear {
                    haptic()
                    appData.reloading_browse = false
                }
                .navigationTitle("Browse")
                .navigationBarItems(trailing:
                                        HStack {
                    NavigationLink(destination: BrowseOptionsView(browseview: self).navigationTitle("Browse Options"), label: {
                        Image("options_icon")
                            .renderingMode(.template)
                    })
                    Button(action: {
                        if #available(iOS 16, *) {
                            isAddingRepoURLAlert16Presented = true
                        } else {
                            isAddingRepoURLAlertPresented = true
                        }
                    }) {
                        Image("plus_icon")
                            .renderingMode(.template)
                    }
                }
                )
                .refreshableBrowseView(browseview: self, appData: appData)
                .addRepoAlert(browseview: self, adding16: $isAddingRepoURLAlert16Presented, adding: $isAddingRepoURLAlertPresented, newRepoURL: $newRepoURL)
                    .onChange(of: isAddingRepoURLAlertPresented) { newValue in
                        if !newValue {
                            Task {
                                await addRepo()
                            }
                        }
                }
            }
        } else {
            ZStack {
                ProgressView().onAppear() {
                    if appData.repoSections.isEmpty || reloading {
                        Task {
                            await fetchRepos()
                        }
                        reloading = false
                    } else {
                        repoSections = appData.repoSections
                    }
                }
                Text("\n\nGetting Repos...")
            }
        }
    }
    
    func triggerReload() {
        appData.reloading_browse = true
        reloading = true
        repoSections = [:]
    }
    
    func fetchRepos() async {
        let temp_repoSections = Dictionary(grouping: await getAllRepos(appdata: appData), by: { $0.repotype }).mapValues { $0.sorted { $0.repotype < $1.repotype } }
        repoSections = temp_repoSections
        appData.repoSections = repoSections
        appData.refreshedRepos = true
    }

//    func fetchRepos() async {
//        appData.repoSections = [:]
//        await getRepos(appdata: appData) { repo in
//            DispatchQueue.main.async {
//                let repoType = repo.repotype
//                if var existingRepos = appData.repoSections[repoType] {
//                    if let existingRepoIndex = existingRepos.firstIndex(where: { $0.url == repo.url }) {
//                        existingRepos[existingRepoIndex] = repo
//                    } else {
//                        existingRepos.append(repo)
//                    }
//                    appData.repoSections[repoType] = existingRepos
//                } else {
//                    appData.repoSections[repoType] = [repo]
//                }
//            }
//        }
//    }
    
    func addRepo() async {
        guard let url = URL(string: newRepoURL) else {
            UIApplication.shared.alert(title: "Error", body: "Invalid Repo?", withButton: true)
            return
        }
        
        let releaseURL = url.appendingPathComponent("Release")
        
        let session = URLSession.shared
        var request = URLRequest(url: releaseURL)
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await session.data(from: request.url!)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if statusCode == 200 {
                appData.RepoData.urls.append(releaseURL)
                newRepoURL = ""
                appData.save()
                await fetchRepos()
            } else {
                // Check the base URL without /Release
                var baseRequest = URLRequest(url: url)
                baseRequest.httpMethod = "HEAD"
                
                let (_, baseResponse) = try await session.data(from: baseRequest.url!)
                let baseStatusCode = (baseResponse as? HTTPURLResponse)?.statusCode ?? 0
                
                if baseStatusCode == 200 {
                    appData.RepoData.urls.append(url)
                    newRepoURL = ""
                    appData.save()
                    await fetchRepos()
                } else {
                    UIApplication.shared.alert(title: "Error", body: "Invalid Repo?", withButton: true)
                }
            }
        } catch {
            UIApplication.shared.alert(title: "Error", body: "Invalid Repo?", withButton: true)
        }
    }

    private func sortedRepoTypes() -> [String] {
        var repoTypes = appData.repoSections.keys.sorted(by: { (repoType1, repoType2) -> Bool in
            let count1 = appData.repoSections[repoType1]?.count ?? 0
            let count2 = appData.repoSections[repoType2]?.count ?? 0
            return count1 < count2
        })
        if let PureKFDIndex = repoTypes.firstIndex(of: "PureKFD") {
            _ = repoTypes.remove(at: PureKFDIndex)
            repoTypes.insert("PureKFD", at: 0)
        }
        return repoTypes
    }
}

struct BrowseOptionsView: View {
    let browseview: BrowseView
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        List {
            Section(header: Text("Hide Tweaks")) {
                Toggle("Hide MDC/KFD Tweaks", isOn: $appData.UserData.filters.kfd)
                    .mainViewTweaks()
                    .listRowBackground(Color.accentColor.opacity(0.2))
                Toggle("Hide Jailbreak Tweaks", isOn: $appData.UserData.filters.jb)
                    .mainViewTweaks()
                    .listRowBackground(Color.accentColor.opacity(0.2))
                Toggle("Hide Apps", isOn: $appData.UserData.filters.ipa)
                    .mainViewTweaks()
                    .listRowBackground(Color.accentColor.opacity(0.2))
                Toggle("Hide Shortcuts", isOn: $appData.UserData.filters.shortcuts)
                    .mainViewTweaks()
                    .listRowBackground(Color.accentColor.opacity(0.2))
            }
            
//            Section(header: Text("Personalization")) {
//                ForEach(appData.repoSections.keys.sorted(), id: \.self) { sectionKey in
//                    Group {
//                        @State var default_name = "\(sectionKey.capitalized) Repo"
//                        @State var default_desc = "\(sectionKey.capitalized) Description"
//                        VStack(alignment: .leading) {
//                            Text("Customize \(sectionKey.capitalized) Dummy Values")
//                                .font(.footnote)
//                            HStack {
//                                WebImage(url: URL(string: ""))
//                                    .resizable()
//                                    .placeholder(Image("folder_icon").resizable().renderingMode(.template))
//                                    .indicator(.progress)
//                                    .transition(.fade)
//                                    .aspectRatio(contentMode: .fit)
//                                    .frame(width: 30, height: 30, alignment: .leading)
//                                    .cornerRadius(5)
//                                VStack(alignment: .leading) {
//                                    TextField("", text: $default_name)
//                                        .padding(.vertical, -5)
//                                    TextField("", text: $default_desc)
//                                        .padding(.vertical, -5)
//                                }
//                            }
//                        }
//                    }.listRowBackground(Color.accentColor.opacity(0.2))
//                }
//            }
        }.listStyle(.insetGrouped).padding().onChange(of: appData.UserData.filters) {_ in
            appData.save()
            appData.repoSections = [:]
            appData.refreshedRepos = false
            refreshView(appData: appData)
            Task {
                await browseview.fetchRepos()
            }
        }
    }
}

struct RepoView: View {
    var repo: Repo
    let appData: AppData
    
    var body: some View {
        List {
            if let featuredPackages = repo.featured {
                if #available(iOS 15.0, *) {
                    FeaturedPackagesView(featuredPackages: featuredPackages)
                        .listRowSeparator(.hidden)
                        .frame(width: UIScreen.main.bounds.width)
                }
            }
            ForEach(repo.packages.indices, id: \.self) { index in
                let package = repo.packages[index]
                NavigationLink(destination: PackageDetailView(package: package, appData: appData).if(package.accent != nil) { view in
                    view.accentColor(package.accent!.toColor())
                }) {
                    if #available(iOS 16, *) {
                        PkgRow(pkgname: package.name, pkgauthor: package.author, pkgiconURL: repo.packages[index].icon, pkg: repo.packages[index])
                            .contextMenu(menuItems: {Button(action: {
                                let pasteboard = UIPasteboard.general
                                pasteboard.string = package.bundleID
                                }) {
                                    Text("Copy Bundle ID")
                                    Image("copy_icon")
                                        .renderingMode(.template)
                                }
                                Button(action: {
                                    appData.queued.append(package)
                                }) {
                                    Text("Add to queue")
                                    Image("download_icon")
                                        .renderingMode(.template)
                                }}, preview: {PackagePreviewView(package: package).if(package.accent != nil) { view in
                                view.accentColor(package.accent!.toColor())
                            }})
                    } else {
                        PkgRow(pkgname: package.name, pkgauthor: package.author, pkgiconURL: repo.packages[index].icon, pkg: repo.packages[index])
                    }
                }
                .hideListRowSeparator()
            }
        }.onAppear() {
            refreshView(appData: appData)
            haptic()
        }
    }
}

struct RepoRow: View {
    @State var reponame: String?
    @State var repodesc: String?
    @State var repoicon: String?
    @State var repo: Repo?
    @State var appData: AppData?
    
    var body: some View {
        HStack {
            WebImage(url: URL(string: repoicon ?? ""))
                .resizable()
                .placeholder(Image("folder_icon").resizable().renderingMode(.template))
                .indicator(.progress)
                .transition(.fade)
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30, alignment: .leading)
                .cornerRadius(5)
            
            VStack(alignment: .leading) {
                Text(reponame ?? "Unknown Repo Name")
                    .font(.headline)
                    .foregroundColor(Color.accentColor)
                Text(repodesc ?? "Unknown Repo Description")
                    .font(.subheadline)
                    .foregroundColor(Color.accentColor.opacity(0.7))
            }
        }.contextMenu(menuItems: {
            if repo != nil {
                Button(action: {
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = repo?.url?.absoluteString
                }) {
                    Text("Copy Repo URL")
                    Image("copy_icon").renderingMode(.template)
                }
                if !defaulturls().urls.map({ $0.deletingLastPathComponent() }).contains(repo?.url ?? URL(string: "file:///")!) {
                    Button(action: {
                        deleteRepo(repo: repo)
                    }) {
                        Text("Delete Repo")
                        Image("trash_icon").renderingMode(.template)
                    }.foregroundColor(.red)
                }
            }
        })
    }
    
    private func deleteRepo(repo: Repo?) {
        guard let repo = repo, let appData = appData else {
            return
        }
        if let urlIndex = appData.RepoData.urls.firstIndex(where: { $0.absoluteString.contains(repo.url?.absoluteString ?? "") }) {
            appData.RepoData.urls.remove(at: urlIndex)
        }
        if var existingRepos = appData.repoSections[repo.repotype] {
            if let existingRepoIndex = existingRepos.firstIndex(where: { $0.name == repo.name }) {
                existingRepos.remove(at: existingRepoIndex)
                appData.repoSections[repo.repotype] = existingRepos
            }
        }
        appData.save()
    }
}

struct PkgRow: View {
    @State var pkgname: String?
    @State var pkgauthor: String?
    @State var pkgiconURL: URL?
    @State var pkg: Package?
    @State var installedPackageView = false
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        HStack {
            WebImage(url: pkgiconURL)
                .resizable()
                .placeholder(Image("pkg_icon").resizable().renderingMode(.template))
                .indicator(.progress)
                .transition(.fade)
                .frame(width: 43, height: 43)
                .cornerRadius(8)
                .opacity(pkg?.disabled ?? false && installedPackageView == true ? 0.5 : 1.0)
            
            VStack(alignment: .leading) {
                Text(pkgname ?? "Unknown Package Name")
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(Color.accentColor)
                    .opacity(pkg?.disabled ?? false && installedPackageView == true ? 0.5 : 1.0)
                
                Text(String(pkgauthor ?? "Unknown Package Author") + " v" + String(pkg?.version ?? ""))
                    .font(.footnote)
                    .lineLimit(1)
                    .foregroundColor(Color.accentColor)
                    .opacity(pkg?.disabled ?? false && installedPackageView == true ? 0.3 : 0.5)
                
                MarqueeText(
                    text: pkg?.desc ?? "",
                    font: UIFont.preferredFont(forTextStyle: .footnote),
                    leftFade: 16,
                    rightFade: 16,
                    startDelay: 3
                )
                .foregroundColor(Color.accentColor)
                .padding(.top, -10)
                .frame(height: 8)
                .opacity(pkg?.disabled ?? false && installedPackageView == true ? 0.4 : 0.7)
            }
            
            HStack() {
                if pkg != nil && !installedPackageView {
                    if isPackageInstalled(pkg?.bundleID ?? "") {
                        Image(systemName: "checkmark.circle.fill")
                    } else {
                        Image(systemName: "circle")
                    }
                }
            }
        }
        .contextMenu(menuItems: {
            if pkg != nil {
                Button(action: {
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = pkg?.bundleID
                }) {
                    Text("Copy Bundle ID")
                    Image("copy_icon")
                        .renderingMode(.template)
                }
                Button(action: {
                    if pkg != nil {
                        appData.queued.append(pkg!)
                    }
                }) {
                    Text("Add to queue")
                    Image("download_icon")
                        .renderingMode(.template)
                }
            }
        })
    }
}


@available(iOS 15.0, *)
struct FeaturedPackagesView: View {
    var featuredPackages: [Featured]?
    var homeView: Bool = false
    @EnvironmentObject var appData: AppData

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 25) {
                ForEach(featuredPackages ?? [], id: \.bundleid) { package in
                    if let foundPackage = findPackageViaBundleID(package.bundleid, appdata: appData) {
                        NavigationLink(destination: PackageDetailView(package: foundPackage, appData: appData)) {
                            FeaturedPackageView(
                                packageName: package.name,
                                packageIcon: package.banner,
                                packageFontColor: package.fontcolor ?? "",
                                packageShowName: package.showname ?? true,
                                homeView: homeView,
                                square: package.square ?? false
                            )
                        }
                    }
                }
            }
            .padding()
        }.if(!homeView){view in view.padding(.leading, 10)}
    }
}


@available(iOS 15.0, *)
struct FeaturedPackageView: View {
    var packageName: String
    var packageIcon: String
    var packageFontColor: String
    var packageShowName: Bool
    var homeView: Bool
    var square: Bool

    var body: some View {
        VStack {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: packageIcon)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .frame(width: square ? (homeView ? 163 : 125) : (homeView ? 260 : 200), height: homeView ? 163 : 125)
                            .cornerRadius(10)
                    default:
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: homeView ? 260 : 200, height: homeView ? 163 : 125)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .frame(width: square ? (homeView ? 160 : 125) : (homeView ? 250 : 180), height: homeView ? 160 : 125)
                
                if packageShowName {
                    Text(packageName)
                        .padding([.leading], -1)
                        .padding([.bottom], 1)
                        .font(homeView ? .title.weight(.bold) : .title2.weight(.bold))
                        .shadow(color: Color.black.opacity(0.5), radius: 5, x: 0, y: 4)
                        .foregroundStyle(Color(UIColor(hex: packageFontColor) ?? UIColor.white))
                }
            }
        }
    }
}
