//
//  TweakView.swift
//  PureKFD
//
//  Created by Lrdsnow on 10/5/24.
//

import SwiftUI
import NukeUI

struct TweakView: View {
    let tweak: Package
    @State private var banner: URL? = nil
    @State private var queued = false
    @State private var installed = false
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        ScrollView {
            VStack {
                if let banner = banner ?? tweak.banner {
                    LazyImage(url: banner) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            RoundedRectangle(cornerRadius: 20).stroke(Color.accentColor.opacity(0.1), lineWidth: 3).overlay(HStack {Spacer(); ProgressView(); Spacer()})
                            
                        }
                    }
                    .padding(.bottom)
                    .padding(.top, -40)
                    .padding(.horizontal, 10)
                }
                Button(action: {
                    if !installed && !queued {
                        appData.queued_pkgs.append((tweak, 0.0, nil))
                        queued = true
                    } else if queued {
                        showConfirmPopup("Confirm", "Are you sure you want to remove \(tweak.name) from the queue?") { confirm in
                            if confirm {
                                appData.queued_pkgs.removeAll(where: { $0.0.bundleid == tweak.bundleid })
                                queued = false
                            }
                        }
                    } else if installed {
                        
                    }
                }, label: {
                    HStack {
                        HStack(alignment: .center) {
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
                            }.frame(width: 60, height: 60).cornerRadius(15).padding(.trailing, 3)
                            VStack(alignment: .leading) {
                                Text(tweak.name).font(.title2.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1)
                                Text((tweak.description ?? "").uppercaseFirstLetter()).font(.subheadline).minimumScaleFactor(0.8).lineLimit(1)
                                Text("Made by \(tweak.author ?? "Unknown Author") • v\(tweak.version ?? "1.0")").font(.caption).minimumScaleFactor(0.8).lineLimit(1)
                            }
                        }
                        Spacer()
                        if queued {
                            Image(systemName: "clock").font(.title2)
                        } else if installed {
                            Image(systemName: "checkmark.square").font(.title2)
                        } else {
                            Image(systemName: "square.and.arrow.down").font(.title2)
                        }
                    }.padding()
                }).animation(.spring, value: queued).buttonStyle(.plain)
                TweakDepictionView(json: genDepictionJSON(), url: tweak.depiction, banner: $banner, accent: .constant(Color.accentColor)).padding(.horizontal)
            }
        }
    }
    
    func genDepictionJSON() -> [String:Any] {
        var json_array: [[String:Any]] = []
        if let description = tweak.long_description {
            json_array.append(
                [
                    "class": "DepictionSubheaderView",
                    "title": "Description",
                    "fontWeight":"bold"
                ]
            )
            json_array.append(
                [
                    "class": "DepictionLabelView",
                    "text": description
                ]
            )
        }
        if let screenshots = tweak.screenshots {
            json_array.append(
                [
                    "class":"DepictionScreenshotsView",
                    "itemCornerRadius":20.0 as CGFloat,
                    "screenshots":screenshots.compactMap( { ["url":$0.absoluteString] as [String:String] } ) as [[String:String]]
                ]
            )
        }
        
        return [
            "class": "DepictionTabView",
            "tabs": [
                [
                    "class": "DepictionStackView",
                    "tabname": "Details",
                    "views": json_array
                ]
            ]
        ]
    }
}
