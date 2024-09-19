//
//  TweakView.swift
//  purekfd
//
//  Created by Lrdsnow on 6/27/24.
//

import Foundation
import SwiftUI
import NukeUI

struct RepoView: View {
    let repo: Repo
    @State var bgColor: Color = .accentColor
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        ZStack {
            bgColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            ScrollView(.vertical) {
                VStack {
                    HStack {
                        HStack {
                            LazyImage(url: repo.iconURL) { state in
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
                            }.frame(width: 75, height: 75).cornerRadius(16)
                            VStack(alignment: .leading) {
                                Text(repo.name).font(.system(size: 36, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor((repo.accentColor?.isSimilar(bgColor, 0.3) ?? true) ? repo.accentColor ?? bgColor : bgColor)
                                Text(repo.description).foregroundColor((repo.accentColor?.isSimilar(bgColor, 0.3) ?? true) ? repo.accentColor ?? bgColor : bgColor).opacity(0.7).lineLimit(1).minimumScaleFactor(0.6)
                            }
                            Spacer()
                        }
                    }.padding(.vertical, 5)
                    if let featured = repo.featured {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(featured, id:\.bundleid) { tweak in
                                    FeaturedViewCard((appData.pkgs.first(where: { $0.bundleid == tweak.bundleid}) ?? Package([:], nil, nil), tweak), false)
                                }
                            }
                        }
                    }
                    ForEach(repo.packages, id:\.bundleid) { tweak in
                        TweakListRowView(tweak: tweak)
                    }
                }.padding()
            }
        }.animation(.easeInOut(duration: 0.25), value: bgColor).navigationBarTitleDisplayMode(.inline)
    }
}

struct TweakListRowView: View {
    let tweak: Package
    let navlink: Bool
    let search: Bool
    @Binding var installing: Bool
    @State private var accent: Color? = nil
    @EnvironmentObject var appData: AppData
    @State private var startLoading = false
    
    init(tweak: Package, navlink: Bool = true, search: Bool = false, installing: Binding<Bool> = .constant(false), accent: Color? = nil) {
        self.tweak = tweak
        self.navlink = navlink
        self.search = search
        self.accent = accent
        self._installing = installing
    }
    
    var body: some View {
        HStack {
            ConditionalNavigationLink(useNavlink: navlink, destination: AnyView(TweakView(tweak: tweak)), label: AnyView(VStack {
                HStack {
                    if startLoading {
                        LazyImage(url: tweak.icon) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .background(Color.black)
                                    .onAppear() {
                                        Task {
                                            if accent == nil,
                                               UserDefaults.standard.bool(forKey: "useAvgImageColors") {
                                                if let uiImage = state.imageContainer?.image,
                                                   let accentColor = averageColor(from: uiImage) {
                                                    DispatchQueue.main.async {
                                                        accent = Color(accentColor.bright())
                                                    }
                                                }
                                            }
                                        }
                                    }
                            } else if state.error != nil {
                                appIconImage
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                ProgressView()
                                    .scaledToFit()
                            }
                        }.frame(width: 45, height: 45).cornerRadius(11).padding(.trailing, 3)
                    } else {
                        ProgressView().frame(width: 45, height: 45).padding(.trailing, 3)
                    }
                    VStack(alignment: .leading) {
                        Text(tweak.name).font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(accent ?? tweak.accentColor ?? tweak.repo?.accentColor ?? .accentColor)
                        Text(tweak.description?.uppercaseFirstLetter() ?? tweak.author?.uppercaseFirstLetter() ?? tweak.bundleid).font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).opacity(0.7).foregroundColor(accent ?? tweak.accentColor ?? tweak.repo?.accentColor ?? .accentColor)
                    }
                    Spacer()
                    if navlink {
                        Image(systemName: "chevron.right").foregroundColor(accent ?? tweak.accentColor ?? tweak.repo?.accentColor ?? .accentColor).font(.footnote)
                    } else if installing {
                        if let queued_pkg = appData.queued_pkgs.first(where: { $0.0.bundleid == tweak.bundleid }) {
                            if queued_pkg.2 == nil {
                                CircularProgressView(progress: queued_pkg.1, tweak: tweak, accent: $accent).frame(width: 22, height: 22)
                            } else {
                                Image(systemName: "exclamationmark.circle.fill").frame(width: 32, height: 32).foregroundColor(.red)
                            }
                        }
                    } else if tweak.error != nil {
                        Image(systemName: "exclamationmark.circle.fill").frame(width: 32, height: 32).foregroundColor(.red)
                    }
                }
            }.padding())
        )
        }.background(RoundedRectangle(cornerRadius: 25).foregroundColor((accent ?? tweak.accentColor ?? tweak.repo?.accentColor ?? .accentColor).opacity(0.1))).onAppear() {
            if search {
                Task(priority: .background) {
                    DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
                        startLoading = true 
                    })
                }
            } else {
                startLoading = true
            }
        }
    }
    
    struct ConditionalNavigationLink: View {
        let useNavlink: Bool
        let destination: AnyView
        let label: AnyView
        
        var body: some View {
            if useNavlink {
                NavigationLink(destination: destination) {
                    label
                }
            } else {
                label
            }
        }
    }
    
    struct CircularProgressView: View {
        let progress: Double
        let tweak: Package
        @Binding var accent: Color?
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(
                        (accent ?? tweak.accentColor ?? tweak.repo?.accentColor ?? .accentColor).opacity(0.5),
                        lineWidth: 5
                    )
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        (accent ?? tweak.accentColor ?? tweak.repo?.accentColor ?? .accentColor),
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)

            }
        }
    }

}
