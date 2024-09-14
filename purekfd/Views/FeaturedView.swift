//
//  Home.swift
//  purekfd
//
//  Created by Lrdsnow on 6/26/24.
//

import SwiftUI
import NukeUI

struct FeaturedView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var repoHandler: RepoHandler
    @State private var featured: [(Package,Featured)] = []
    
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
                            NavigationLink(destination: SettingsView(), label: {
                                Image(systemName: "gearshape").foregroundColor(.accentColor)
                            }).buttonStyle(.borderedProminent).tint(.accent.opacity(0.3)).cornerRadius(50)//.clipShape(.circle)
                        }.padding(.leading, 1)
                        if appData.featured.count >= 10 {
                            VStack(spacing: 10) {
                                ForEach(featured, id:\.0.bundleid) { feature in
                                    FeaturedViewCard(feature, true)
                                }
                            }.onAppear() {
                                if featured.isEmpty {
                                    let repo_featured = appData.featured.filter({ !($0.square ?? false) }).shuffled().prefix(10)
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
                    }.padding(.horizontal).padding(.bottom, 60)
                }.ios16padding()
            }.onAppear() {
                updateInstalledTweaks(appData)
                repoHandler.updateRepos(appData)
            }.navigationBarTitleDisplayMode(.inline)
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
