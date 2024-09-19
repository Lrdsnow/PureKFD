//
//  ContentView.swift
//  purekfd macOS
//
//  Created by Lrdsnow on 9/1/24.
//

import SwiftUI
import NukeUI

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    @State var repoHandler = RepoHandler()
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: HomeView(), label: {Label("Featured", systemImage: "star.fill")})
                NavigationLink(destination: HomeView(), label: {Label("Installed", systemImage: "square.and.arrow.down")})
                Section("Repos") {
                    ForEach(appData.repos.sorted(by: { $0.name < $1.name }), id: \.url) { repo in
                        NavigationLink(destination: RepoView(repo: repo), label: {
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
                                }.frame(width: 16, height: 16).cornerRadius(11).padding(.trailing, 3)
                                Text(repo.name)
                            }
                        }).contextMenu {
                            if let url = repo.prettyURL {
                                Text(url).font(.footnote).minimumScaleFactor(0.5).lineLimit(1).opacity(0.5)
                            }
                            if repo.error != nil {
                                Button(action: {
                                    // error stuff
                                }, label: {
                                    HStack {
                                        Text("Error Info")
                                        Spacer()
                                        Image(systemName: "exclamationmark.circle.fill")
                                    }
                                })
                            }
                            Button(action: {
                                if let url = repo.fullURL {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    pasteboard.setString(url.absoluteString, forType: .string)
                                }
                            }, label: {
                                HStack {
                                    Text("Copy URL")
                                    Spacer()
                                    Image(systemName: "doc.on.clipboard")
                                }
                            })
                            Button(role: .destructive, action: {
                                if let url = repo.fullURL {
                                    repoHandler.removeRepo(url, appData)
                                }
                            }, label: {
                                HStack {
                                    Text("Delete Repo")
                                    Spacer()
                                    Image(systemName: "trash")
                                }
                            })
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollIndicators(.never)
        }
        .task() {
            log("Running on an \(DeviceInfo.modelName) (\(DeviceInfo.cpu)) running \(DeviceInfo.osString) \(DeviceInfo.version) (\(DeviceInfo.build))")
            updateInstalledTweaks(appData)
            repoHandler.updateRepos(appData)
        }
    }
}

#Preview {
    ContentView()
}
