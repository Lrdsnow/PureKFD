//
//  Queued.swift
//  purekfd
//
//  Created by Lrdsnow on 6/29/24.
//

import SwiftUI

struct QueuedView: View {
    @EnvironmentObject var appData: AppData
    @State private var installing = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.accentColor
                .ignoresSafeArea(.all)
                .opacity(0.07)
            ScrollView(.vertical) {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Queued").font(.system(size: 36, weight: .bold)).minimumScaleFactor(0.8).lineLimit(1).foregroundColor(.accentColor)
                        }
                        Spacer()
                    }.padding(.leading, 1)
                    ForEach(appData.queued_pkgs, id:\.0.bundleid) { tweak in
                        TweakListRowView(tweak: tweak.0, navlink: false, installing: $installing)
                    }
                }.padding().padding(.top, 27)
            }
            Button(action: {
                withAnimation(.spring) {
                    installing = true
                }
            }, label: {
                HStack {
                    Spacer()
                    if installing {
                        ProgressView().tint(.accentColor)
                    } else {
                        Text("Install Tweaks").font(.headline.bold())
                    }
                    Spacer()
                }.padding()
            }).background(RoundedRectangle(cornerRadius: 25).foregroundColor(Color.accentColor.opacity(0.1))).padding()
        }
    }
}
