//
//  RepoView.swift
//  purebox
//
//  Created by Lrdsnow on 9/1/24.
//

import SwiftUI
import NukeUI

struct RepoView: View {
    let repo: Repo
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        HStack {
                            LazyImage(url: repo.iconURL) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .background(Color.black)
                                } else {
                                    ProgressView()
                                        .scaledToFit()
                                }
                            }.frame(width: 55, height: 55).cornerRadius(16)
                            VStack(alignment: .leading) {
                                Text(repo.name).font(.system(size: 36, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1)
                                Text(repo.description).opacity(0.7).lineLimit(1).minimumScaleFactor(0.6)
                            }
                            Spacer()
                        }
                    }
                }
                ForEach(repo.packages, id:\.bundleid) { tweak in
                    TweakListRowView(tweak: tweak)
                }
            }.formStyle(.grouped)
        }
    }
}

struct TweakListRowView: View {
    let tweak: Package
    let navlink: Bool
    @Binding var installing: Bool
    @EnvironmentObject var appData: AppData
    
    init(tweak: Package, navlink: Bool = true, installing: Binding<Bool> = .constant(false)) {
        self.tweak = tweak
        self.navlink = navlink
        self._installing = installing
    }
    
    var body: some View {
        HStack {
            ConditionalNavigationLink(useNavlink: navlink, destination: AnyView(TweakView(tweak: tweak)), label: AnyView(VStack {
                HStack {
                    LazyImage(url: tweak.icon) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .background(Color.black)
                        } else {
                            ProgressView()
                                .scaledToFit()
                        }
                    }.frame(width: 45, height: 45).cornerRadius(11).padding(.trailing, 3)
                    VStack(alignment: .leading) {
                        Text(tweak.name).font(.title3.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1)
                        Text(tweak.description?.uppercaseFirstLetter() ?? tweak.author?.uppercaseFirstLetter() ?? tweak.bundleid).font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).opacity(0.7)
                    }
                    Spacer()
                    if installing {
                        if let queued_pkg = appData.queued_pkgs.first(where: { $0.0.bundleid == tweak.bundleid }) {
                            if queued_pkg.2 == nil {
                                CircularProgressView(progress: queued_pkg.1, tweak: tweak).frame(width: 22, height: 22)
                            } else {
                                Image(systemName: "exclamationmark.circle.fill").frame(width: 32, height: 32).foregroundColor(.red)
                            }
                        }
                    } else if tweak.error != nil {
                        Image(systemName: "exclamationmark.circle.fill").frame(width: 32, height: 32).foregroundColor(.red)
                    }
                }
            })
            )
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
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(
                        Color.accentColor.opacity(0.5),
                        lineWidth: 5
                    )
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
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
