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
        self.listRowBackground(
            VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial)).ignoresSafeArea().opacity(0.2).tint(Color(uiColor: .systemFill))
        )
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
        if !UserDefaults.standard.bool(forKey: "noClearRows") {
            self.listRowSeparator(.hidden)
        } else {
            self
        }
    }
    @ViewBuilder
    func addRepoAlert(browseview: BrowseView, adding16: Binding<Bool>, adding: Binding<Bool>, newRepoURL: Binding<String>) -> some View {
        if #available(iOS 16.0, *) {
            self.alert("Add Repo", isPresented: adding16, actions: {
                TextField("URL", text: newRepoURL)
                Button("Save", action: {
                    Task {
                        await browseview.addRepo()
                    }
                })
                Button("Cancel", role: .cancel, action: {})
            })
        } else {
            self.textFieldAlert(
                title: "Add Repo",
                message: "Hit Done to add repo or cancel",
                textFields: [
                    .init(text: newRepoURL)
                ],
                actions: [
                    .init(title: "Done")
                ],
                isPresented: adding
            )
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
            self.background(
                VStack {
                    Image("Default_BG")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.top)
                        .edgesIgnoringSafeArea(.bottom)
                        .overlay(
                            VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial)).ignoresSafeArea()
                        )
                }.edgesIgnoringSafeArea(.top)
                    .edgesIgnoringSafeArea(.bottom)
                    .frame(width: UIScreen.main.bounds.width)
            )
//        }
    }
    @ViewBuilder
    func mainViewTweaks() -> some View {
        if #available(iOS 15.0, *) {
            self.foregroundStyle(Color.accentColor).tint(Color.accentColor)
        } else {
            self.foregroundColor(Color.accentColor)
        }
    }
}
