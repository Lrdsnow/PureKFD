//
//  TweakView.swift
//  purekfd
//
//  Created by Lrdsnow on 6/28/24.
//

import SwiftUI
import NukeUI

struct TweakView: View {
    let tweak: Package
    @State var bgColor: Color = .accentColor
    @State private var accent: Color? = nil
    @State private var banner: URL? = nil
    @State private var queued = false
    @State private var installed = false
    @EnvironmentObject var appData: AppData
        
    var body: some View {
        ZStack {
            bgColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            
            ScrollView {
                VStack {
                    if let banner = banner ?? tweak.banner {
                        LazyImage(url: banner) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: UIScreen.main.bounds.width-40, height: DeviceInfo.ipad ? 300 : 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                RoundedRectangle(cornerRadius: 20).stroke(tabTint().opacity(0.1), lineWidth: 3).frame(width: UIScreen.main.bounds.width-40, height: DeviceInfo.ipad ? 300 : 200).overlay(HStack {Spacer(); ProgressView(); Spacer()})
                                
                            }
                        }
                        .padding(.bottom)
                        .padding(.top, -40)
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
                                            .onAppear() {
                                                if accent == nil,
                                                   UserDefaults.standard.bool(forKey: "useAvgImageColors") {
                                                    if let uiImage = state.imageContainer?.image,
                                                       let accentColor = averageColor(from: uiImage) {
                                                        bgColor = Color(accentColor.bright())
                                                        accent = Color(accentColor.bright())
                                                        return
                                                    }
                                                }
                                                bgColor = tabTint()
                                                accent = tabTint()
                                            }
                                    } else if state.error != nil {
                                        appIconImage
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        ProgressView()
                                            .scaledToFit()
                                    }
                                }.frame(width: 60, height: 60).cornerRadius(15).padding(.trailing, 3)
                                VStack(alignment: .leading) {
                                    Text(tweak.name).font(.title2.weight(.bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(tabTint())
                                    Text((tweak.description ?? "").uppercaseFirstLetter()).font(.subheadline).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(tabTint()).opacity(0.7)
                                }
                            }
                            Spacer()
                            if queued {
                                Image(systemName: "clock").font(.title2).foregroundColor(tabTint())
                            } else if installed {
                                Image(systemName: "checkmark.square").font(.title2).foregroundColor(tabTint())
                            } else {
                                Image(systemName: "square.and.arrow.down").font(.title2).foregroundColor(tabTint())
                            }
                        }.padding()
                    }).background(RoundedRectangle(cornerRadius: 25).foregroundColor(tabTint().opacity(0.1))).animation(.spring, value: queued)
                    HStack {
                        Spacer()
                        Text("Made by \(tweak.author ?? "Unknown Author") • v\(tweak.version ?? "1.0")").foregroundColor(tabTint()).font(.caption)
                        Spacer()
                    }.padding(.vertical, 1)
                    if accent != nil {
                        TweakDepictionView(json: genDepictionJSON(), url: tweak.depiction, banner: $banner, accent: $bgColor).tint(tabTint())
                    }
                }.padding().padding(.top, 20)
            }
        }.animation(.easeInOut(duration: 0.25), value: bgColor).onAppear() {
            queued = appData.queued_pkgs.contains(where: { $0.0.bundleid == tweak.bundleid })
            installed = appData.installed_pkgs.contains(where: { $0.bundleid == tweak.bundleid })
        }
    }
    
    func tabTint() -> Color { return ((tweak.repo?.accentColor?.isSimilar(bgColor, 0.3) ?? true) ? tweak.repo?.accentColor ?? bgColor : accent ?? tweak.repo?.accentColor ?? bgColor) }
    
    func genDepictionJSON() -> [String:Any] {
        var json_array: [[String:Any]] = []
        if let description = tweak.long_description {
            json_array.append(
                [
                    "class": "DepictionSubheaderView",
                    "title": "Description",
                    "fontWeight":"bold",
                    "textColor":tabTint().toHex()
                ]
            )
            json_array.append(
                [
                    "class": "DepictionLabelView",
                    "text": description,
                    "textColor":tabTint().toHex()
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
