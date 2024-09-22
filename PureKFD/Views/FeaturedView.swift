//
//  Home.swift
//  purekfd
//
//  Created by Lrdsnow on 6/26/24.
//

import SwiftUI
import NukeUI
import Zip

struct FeaturedView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var repoHandler: RepoHandler
    @Binding var selectedTab: Int
    @State private var featured: [(Package,Featured)] = []
    @State private var selectedTweak: Package? = nil
    @State private var showSelectedTweak = false
    @State private var showSettings = false
    @AppStorage("FilterPackages") var filterPackages = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.accentColor
                    .ignoresSafeArea(.all)
                    .opacity(0.07)
                
                ScrollView(.vertical) {
                    VStack {
                        HStack {
                            appIconImage.resizable().scaledToFill().frame(width: 60, height: 60).cornerRadius(11).padding(.trailing, 3)
                            VStack(alignment: .leading) {
                                Text("PureKFD").font(.system(size: 36, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                            }
                            Spacer()
                            NavigationLink(destination: SettingsView(), isActive: $showSettings, label: {
                                Image(systemName: "gearshape").foregroundColor(.accentColor)
                            }).buttonStyle(.borderedProminent).tint(.accentColor.opacity(0.3)).cornerRadius(50)//.clipShape(.circle)
                        }.padding(.leading, 1)
                        if appData.featured.count >= 10 {
                            VStack(spacing: 10) {
                                ForEach(featured, id:\.0.bundleid) { feature in
                                    FeaturedViewCard(feature, true)
                                }
                            }.onAppear() {
                                if featured.isEmpty {
                                    let repo_featured = appData.repos
                                        .filter { $0.filtered != true } // Filter out repos that are marked as filtered
                                        .flatMap { $0.packages ?? [] } // Flatten the packages from each repo
                                        .filter { $0.filtered != true } // Ensure the package itself is not filtered
                                        .compactMap { $0.feature } // Extract features, filtering out nils
                                        .filter { !($0.square ?? false) } // Filter out features with square == true
                                        .shuffled() // Shuffle the features
                                        .prefix(10) // Get the first 10 features
                                    for feature in repo_featured {
                                        if let pkg = appData.pkgs.first(where: { $0.bundleid == feature.bundleid }) {
                                            featured.append((pkg, feature))
                                        }
                                    }
                                }
                            }
                        } else {
                            ProgressView().tint(.accentColor)
                        }
                        //
                        NavigationLink(destination:
                                        HStack {
                            if let selectedTweak = selectedTweak {
                                TweakView(tweak: selectedTweak)
                            } else {
                                ProgressView()
                            }
                        }.onDisappear() { selectedTweak = nil }, isActive: $showSelectedTweak, label: {Text("test")}).opacity(0.01).onTapGesture {}
                        //
                    }.padding(.horizontal).padding(.bottom, 60)
                }.ios16padding()
            }
            .onChange(of: filterPackages) { _ in
                appData.repos = []
                appData.featured = []
                appData.pkgs = []
                featured = []
                repoHandler.updateRepos(appData)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onOpenURL(perform: { url in
                if url.pathExtension == "purekfd" {
                    showSelectedTweak = false
                    showSettings = false
                    url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    let fm = FileManager.default
                    do {
                        let tempURL = URL.documents.appendingPathComponent("temp")
                        let tempFileURL = tempURL.appendingPathComponent("import.zip")
                        try? fm.removeItem(at: tempURL)
                        try fm.createDirectory(at: tempURL, withIntermediateDirectories: true)
                        try fm.copyItem(at: url, to: tempFileURL)
                        let output = try Zip.quickUnzipFile(tempFileURL)
                        if let tweakFolder = findTweakFolder(in: output) {
                            let bundleID = "\(tweakFolder.lastPathComponent)"
                            let infoCacheURL = tweakFolder.appendingPathComponent("_info.json")
                            let infoURL = tweakFolder.appendingPathComponent("info.json")
                            if fm.fileExists(atPath: infoCacheURL.path),
                               let data = try? Data(contentsOf: infoCacheURL),
                               let tweakInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                                var temp_pkg = Package(tweakInfo, nil, nil)
                                temp_pkg.path = tempFileURL
                                selectedTweak = temp_pkg
                            } else if fm.fileExists(atPath: infoURL.path),
                                let data = try? Data(contentsOf: infoURL),
                                      let tweakInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                                var temp_pkg = Package(tweakInfo, nil, nil)
                                temp_pkg.path = tempFileURL
                                selectedTweak = temp_pkg
                            } else {
                                if let pkg = appData.pkgs.first(where: { $0.bundleid == bundleID }) {
                                    var temp_pkg = pkg
                                    temp_pkg.path = tempFileURL
                                    selectedTweak = temp_pkg
                                } else {
                                    var temp_pkg = Package(["bundleid":bundleID], nil, nil)
                                    temp_pkg.path = tempFileURL
                                    selectedTweak = temp_pkg
                                }
                            }
                        } else {
                            throw "No tweak folder!"
                        }
                        try? fm.removeItem(at: output)
                        showSelectedTweak = true
                        selectedTab = 0
                    } catch {
                        showPopup("Error", "Failed to import: \(error.localizedDescription)")
                    }
                }
            })
        }.navigationViewStyle(.stack)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct FeaturedViewCard: View {
    let feature: (Package, Featured)
    let homeView: Bool
    @State private var accent: Color? = nil
    
    init(_ feature: (Package, Featured), _ homeView: Bool = false) {
        self.feature = feature
        self.accent = nil
        self.homeView = homeView
    }
    
    var body: some View {
        NavigationLink(destination: TweakView(tweak: feature.0)) {
            VStack(spacing: 0) {
                LazyImage(url: feature.1.banner) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .background(Color.black)
                            .frame(width: homeView ? UIScreen.main.bounds.width/1.1 : UIScreen.main.bounds.width/(DeviceInfo.ipad ? 3 : 1.5), height: homeView ? 200 : 147)
                            .clipShape(RoundedCorner(radius: homeView ? 24 : 20, corners: [.topLeft, .topRight]))
                            .onAppear() {
                                if accent == nil,
                                   UserDefaults.standard.bool(forKey: "useAvgImageColors") {
                                    if let uiImage = state.imageContainer?.image,
                                       let accentColor = averageColor(from: uiImage) {
                                        accent = Color(accentColor.bright())
                                    }
                                }
                            }
                    } else {
                        RoundedCorner(radius: homeView ? 24 : 20, corners: [.topLeft, .topRight]).stroke((feature.0.accentColor ?? .accentColor).opacity(0.1)).frame(width: homeView ? UIScreen.main.bounds.width/1.1 : UIScreen.main.bounds.width/1.5, height: homeView ? 200 : 147)
                            .overlay(
                                HStack {
                                    Spacer()
                                    ProgressView().tint(feature.0.accentColor ?? .accentColor)
                                    Spacer()
                                }
                            )
                    }
                }
                HStack {
                    LazyImage(url: feature.0.icon) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .background(Color.black)
                        } else if state.error != nil {
                            appIconImage
                                .resizable()
                                .scaledToFill()
                        } else {
                            ProgressView()
                                .scaledToFit()
                        }
                    }.frame(width: homeView ? 45 : 33, height: homeView ? 45 : 33).cornerRadius(11).padding(.trailing, 3)
                    VStack(alignment: .leading) {
                        Text(feature.0.name).font(.system(size: homeView ? 20 : 16, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(accent ?? feature.0.accentColor ?? .accentColor)
                        Text(feature.0.repo?.name ?? "").font(.system(size: homeView ? 16 : 14)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(accent ?? feature.0.accentColor ?? .accentColor).opacity(0.7)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(accent ?? feature.0.accentColor ?? .accentColor)
                    //                                            NavigationLink(destination: TweakView(tweak: feature.0), label: {
                    //                                                Text("Get")
                    //                                            }).buttonStyle(.borderedProminent).tint((feature.0.accentColor ?? .accentColor).opacity(0.3)).cornerRadius(50)
                }.padding().frame(width: homeView ? UIScreen.main.bounds.width/1.1 : UIScreen.main.bounds.width/(DeviceInfo.ipad ? 3 : 1.5), height: homeView ? 75 : 55).background((accent ?? feature.0.accentColor ?? .accentColor).opacity(0.1))
            }.frame(width: homeView ? UIScreen.main.bounds.width/1.1 : UIScreen.main.bounds.width/(DeviceInfo.ipad ? 3 : 1.5), height: homeView ? 275 : 202).clipShape(RoundedRectangle(cornerRadius: homeView ? 24 : 20))
        }
    }
}
