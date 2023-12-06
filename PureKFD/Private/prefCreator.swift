//
//  prefCreator.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/24/23.
//

import Foundation
import SwiftUI

import SwiftUI

struct PrefCreator: View {
    @State private var preferenceSections: [PreferenceSection] = []
    @State private var savedPreferences: [[String: Any]] = []

    var body: some View {
        List {
            ForEach(preferenceSections.indices, id: \.self) { sectionIndex in
                Section(header: Text("Preference Section \(sectionIndex + 1)")) {
                    Picker("Preference Type", selection: $preferenceSections[sectionIndex].type) {
                        ForEach(PreferenceType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    preferenceSections[sectionIndex].content
                }
            }.listRowBackground(Color.accentColor.opacity(0.2))
            Section {
                Button("Add Pref Item") {
                    addPreferenceSection()
                }
            }.listRowBackground(Color.accentColor.opacity(0.2))
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Pref Creator")
        .navigationBarItems(
            trailing: Button(action: {
                savePreferences()
            }) {
                Text("Save")
            }
        )
    }

    func addPreferenceSection() {
        let newSection = PreferenceSection(type: .label)
        preferenceSections.append(newSection)
    }

    func savePreferences() {
        savedPreferences = preferenceSections.map { section in
            var preferenceDict: [String: Any] = [:]
            
            print(section)

            switch section.type {
            case .label:
                if let labelPreferenceView = section.content as? LabelPreferenceView {
                    preferenceDict["\(labelPreferenceView.labelText):label"] = ""
                }
            case .link:
                if let linkPreferenceView = section.content as? LinkPreferenceView {
                    preferenceDict["\(linkPreferenceView.linkLabel):link"] = linkPreferenceView.linkURL
                }
            case .image:
                if let imagePreferenceView = section.content as? ImagePreferenceView {
                    preferenceDict["\(UUID()):image"] = imagePreferenceView.imageURL
                }
            }
            
            print(preferenceDict)

            return preferenceDict
        }
    }
}

enum PreferenceType: String, CaseIterable, Identifiable {
    case label
    case link
    case image

    var id: String { self.rawValue }
}

struct PreferenceSection {
    var type: PreferenceType
    var content: AnyView

    init(type: PreferenceType) {
        self.type = type

        switch type {
        case .label:
            self.content = AnyView(LabelPreferenceView())
        case .link:
            self.content = AnyView(LinkPreferenceView())
        case .image:
            self.content = AnyView(ImagePreferenceView())
        }
    }
}

struct LabelPreferenceView: View {
    @State var labelText = ""

    var body: some View {
        TextField("Label Text", text: $labelText)
    }
}

struct LinkPreferenceView: View {
    @State var linkLabel = ""
    @State var linkURL = ""

    var body: some View {
        TextField("Link Label", text: $linkLabel)
        TextField("Link URL", text: $linkURL)
    }
}

struct ImagePreferenceView: View {
    @State var imageURL = ""

    var body: some View {
        TextField("Image URL", text: $imageURL)
    }
}
