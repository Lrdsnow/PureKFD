//
//  Developer.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/24/23.
//

import Foundation
import SwiftUI

struct DeveloperView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: FileBrowserView(), label: {Image("folder_icon").renderingMode(.template); Text("File Browser")})
                NavigationLink(destination: TweakCreatorView(), label: {Image("gear_icon").renderingMode(.template); Text("Tweak Creator")})
            }.navigationBarTitle("Developer", displayMode: .large)
        }
    }
}
