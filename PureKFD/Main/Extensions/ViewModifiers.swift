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
    func hideListRowSeparator() -> some View {
        if #available(iOS 15.0, *) {
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
    func mainViewTweaks() -> some View {
        if #available(iOS 15.0, *) {
            self.foregroundStyle(Color.accentColor).tint(Color.accentColor)
        } else {
            self.foregroundColor(Color.accentColor)
        }
    }
}
