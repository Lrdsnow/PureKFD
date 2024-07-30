//
//  ViewModifiers.swift
//  PureKFD
//
//  Created by Lrdsnow on 11/4/23.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func tintC(_ color: Color) -> some View {
        if #available(iOS 15.0, *) {
            self.tint(color)
        } else {
            self
        }
    }
    @ViewBuilder
    func borderedprombuttonc() -> some View {
        if #available(iOS 15.0, *) {
            self.buttonStyle(.borderedProminent)
        } else {
            self
        }
    }
    @ViewBuilder
    func interactiveDismissDisabledC() -> some View {
        if #available(iOS 15.0, *) {
            self.interactiveDismissDisabled()
        } else {
            self
        }
    }
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
    @ViewBuilder
    func iconImg() -> some View {
        if self is Image {
            AnyView((self as! Image).resizable().renderingMode(.template).frame(maxWidth: 32, maxHeight: 32))
        } else {
            AnyView(self)
        }
    }
    @ViewBuilder
    func listBG() -> some View {
        if #available(iOS 15.0, *) {
            self.listRowBackground(
                VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial)).ignoresSafeArea().opacity(0.2).tintC(Color(uiColor: .systemFill))
            )
        } else {
            self
        }
    }
    @ViewBuilder
    func plainList() -> some View {
        if !UserDefaults.standard.bool(forKey: "noClearRows") {
            self.listStyle(.plain)
        } else {
            self
        }
    }
    @ViewBuilder
    func plainList(_ e: Bool) -> some View {
        if e {
            self.listStyle(.plain)
        } else {
            self.listStyle(.insetGrouped)
        }
    }
    @ViewBuilder
    func clearBackground() -> some View {
        if !UserDefaults.standard.bool(forKey: "noClearRows") {
            self.background(Color.clear)
        } else {
            self
        }
    }
    @ViewBuilder
    func hideListRowSeparator() -> some View {
        if !UserDefaults.standard.bool(forKey: "noClearRows"),
           #available(iOS 15.0, *) {
            self.listRowSeparator(.hidden)
        } else {
            self
        }
    }
    @ViewBuilder
    func refreshableBrowseView(browseview: BrowseView, appData: AppData) -> some View {
        if #available(iOS 15.0, *) {
            self.refreshable {
                Task {
                    await browseview.triggerReload()
                }
            }
        } else {
            self
        }
    }
    @ViewBuilder
    func blurredBG() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(.ultraThinMaterial)
        } else {
            self
        }
    }
    @ViewBuilder
    func clearBG() -> some View {
        if #available(iOS 16.4, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
    @ViewBuilder
    func bgImage(_ appData: AppData? = nil) -> some View {
//        if hasEntitlement("com.apple.private.security.no-sandbox" as CFString),
//           let bg = loadWallpapers(appData) {
//            self.background(
//                    Image(uiImage: bg)
//                        .resizable()
//                        .scaledToFill()
//                        .edgesIgnoringSafeArea(.top)
//                        .edgesIgnoringSafeArea(.bottom)
//                        .overlay(
//                            VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial)).ignoresSafeArea()
//                        )
//            )
//        } else {
//            self.background(
//                VStack {
//                    Image("Default_BG")
//                        .resizable()
//                        .scaledToFill()
//                        .edgesIgnoringSafeArea(.top)
//                        .edgesIgnoringSafeArea(.bottom)
//                        .overlay(
//                            VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial)).ignoresSafeArea()
//                        )
//                }.edgesIgnoringSafeArea(.top)
//                    .edgesIgnoringSafeArea(.bottom)
//                    .frame(width: UIScreen.main.bounds.width)
//            )
//        }
        self
    }
    @ViewBuilder
    func mainViewTweaks() -> some View {
        if #available(iOS 15.0, *) {
            self.foregroundStyle(Color.accentColor).tintC(Color.accentColor)
        } else {
            self.foregroundColor(Color.accentColor)
        }
    }
}
