//
//  FileBrowser.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/2/23.
//

import SwiftUI
import UIKit
import MobileCoreServices
import TextFieldAlert
import Zip

struct FileBrowserView: View {
    @EnvironmentObject var appData: AppData
    @State var currentPath = ""
    @State var exploit_method: Int = 0
    @State var kfddata = SavedKFDData()
    @State var popover = false
    @State var pickerpath = ""
    
    var body: some View {
        Group {
            if !appData.UserData.allowroot {
                FileBrowser(appData: appData, currentFullPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path, pickerpath: $pickerpath, popover: $popover)
                    .navigationTitle("File Browser")
            } else {
                FileBrowser(appData: appData, currentFullPath: "", pickerpath: $pickerpath, popover: $popover)
                    .navigationTitle("File Browser")
                    .navigationBarItems(trailing: ToggleButtonView(kopened: $appData.kopened, exploit_method: $exploit_method, kfddata: $kfddata))
            }
        }.onAppear() {
            exploit_method = getExploitMethod(appData: appData).0
            kfddata = getExploitMethod(appData: appData).1
        }
    }
}

struct ToggleButtonView: View {
    @Binding var kopened: Bool
    @EnvironmentObject var appData: AppData
    @Binding var exploit_method: Int
    @Binding var kfddata: SavedKFDData
    
    var body: some View {
        if exploit_method == 0 {
            Button(action: {
                if kopened {
                    do_kclose()
                } else {
                    let exploit_result = do_kopen(UInt64(kfddata.puaf_pages), UInt64(kfddata.puaf_method), UInt64(kfddata.kread_method), UInt64(kfddata.kwrite_method))
                    if exploit_result == 0 {
                        return
                    }
                    fix_exploit()
                }
                kopened.toggle()
            }) {
                Text(kopened ? "kclose" : "kopen")
            }
        }
    }
}

struct FileBrowser: View {
    @State var appData: AppData
    @State private var searchText = ""
    @State private var dirContents: [String] = []
    @State private var isShowingContextMenu = false
    @State private var folder_vdata: UInt64 = 0
    @State private var isFolderRdird = false
    @State private var shouldRefresh = false
    @State private var newFileFolderName = ""
    @State private var newFileFolderType = "folder" // can also be "file"
    @State private var isNewFileFolderAlertPresented = false
    @State private var isNewFileFolderAlertPresented15 = false
    
    @State var currentPath = ""
    @State var currentFullPath = ""
    @State var isSubFolder = false
    
    @Binding var pickerpath: String
    @Binding var popover: Bool
    
    var filteredContents: [String] {
        if searchText.isEmpty {
            return dirContents
        } else {
            return dirContents.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Search Current Directory", text: $searchText)
                .padding(.horizontal)
            
            List(filteredContents, id: \.self) { item in
                Group {
                    if item.hasPrefix("[Folder]") {
                        NavigationLink(destination: FileBrowser(appData: appData, currentPath: item.replacingOccurrences(of: "[Folder]", with: ""), currentFullPath: currentFullPath + "/" + item.replacingOccurrences(of: "[Folder]", with: ""), isSubFolder: true, pickerpath: $pickerpath, popover: $popover).navigationTitle(item.replacingOccurrences(of: "[Folder]", with: ""))) {
                            FileListItemView(path: currentFullPath, item: item, isFolder: true, kfd: (appData.UserData.exploit_method == 0 && appData.UserData.allowroot), shouldRefresh: $shouldRefresh)
                        }
                    } else {
                        if !popover {
                            FileListItemView(path: currentFullPath, item: item, isFolder: false, kfd: (appData.UserData.exploit_method == 0 && appData.UserData.allowroot), shouldRefresh: $shouldRefresh)
                        } else {
                            Button(action: {
                                pickerpath = "\(currentFullPath)/\(item)"
                                popover = false
                            }) {
                                FileListItemView(path: currentFullPath, item: item, isFolder: false, kfd: (appData.UserData.exploit_method == 0 && appData.UserData.allowroot), shouldRefresh: $shouldRefresh)
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
                .listRowSeparator(.hidden)
            }
        }
        .onDisappear() {
            if isFolderRdird {
                UnRedirectAndRemoveFolder2(folder_vdata)
                isFolderRdird=false
            }
        }
        .contextMenu {
            Button(action: {
                newFileFolderType = "folder"
                if #available(iOS 16, *) {
                    isNewFileFolderAlertPresented = true
                } else {
                    isNewFileFolderAlertPresented15 = true
                }
            }) {
                Text("Create Folder")
                Image("folder_icon").renderingMode(.template)
            }
            Button(action: {
                newFileFolderType = "file"
                if #available(iOS 16, *) {
                    isNewFileFolderAlertPresented = true
                } else {
                    isNewFileFolderAlertPresented15 = true
                }
            }) {
                Text("Create Empty File")
                Image("file_icon").renderingMode(.template)
            }
        }
        .onAppear {
            if currentFullPath.isEmpty {
                loadContentsInDirectory(path: "/")
            } else {
                loadContentsInDirectory(path: currentFullPath)
            }
        }
        .onChange(of: shouldRefresh, perform: {_ in
            if currentFullPath.isEmpty {
                loadContentsInDirectory(path: "/")
            } else {
                loadContentsInDirectory(path: currentFullPath)
            }
        })
        .alert("New File/Folder", isPresented: $isNewFileFolderAlertPresented, actions: {
            TextField("New File/Folder Name", text: $newFileFolderName).autocorrectionDisabled()
            Button("Save", action: {
                if newFileFolderType == "file" {
                    let filePath = currentFullPath + "/" + newFileFolderName
                    let data = Data()
                            
                    do {
                        try data.write(to: URL(fileURLWithPath: filePath))
                        shouldRefresh.toggle()
                    } catch {
                        print("Error creating empty file: \(error)")
                    }
                } else {
                    let folderPath = currentFullPath + "/" + newFileFolderName
                    do {
                        try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
                        shouldRefresh.toggle()
                    } catch {
                        print("Error creating empty folder: \(error)")
                    }
                }
            })
            Button("Cancel", role: .cancel, action: {
                isNewFileFolderAlertPresented = false
            })
        })
        .textFieldAlert(
            title: "New File/Folder",
            message: "Hit Done to rename or cancel",
            textFields: [
                .init(text: $newFileFolderName)
            ],
            actions: [
                .init(title: "Done")
            ],
            isPresented: $isNewFileFolderAlertPresented15
        )
        .onChange(of: isNewFileFolderAlertPresented15) { newValue in
            if !newValue {
                if newFileFolderType == "file" {
                    var fullpath = ""
                    if isFolderRdird {
                        fullpath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("mounted").path
                    } else {
                        fullpath = currentFullPath
                    }
                    let filePath = fullpath + "/" + newFileFolderName
                    let data = Data()
                    
                    do {
                        try data.write(to: URL(fileURLWithPath: filePath))
                        shouldRefresh.toggle()
                    } catch {
                        print("Error creating empty file: \(error)")
                    }
                } else {
                    var fullpath = ""
                    if isFolderRdird {
                        fullpath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("mounted").path
                    } else {
                        fullpath = currentFullPath
                    }
                    let folderPath = fullpath + "/" + newFileFolderName
                    do {
                        try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
                        shouldRefresh.toggle()
                    } catch {
                        print("Error creating empty folder: \(error)")
                    }
                }
            }
        }
    }
    
    private func loadContentsInDirectory(path: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var folderURL: URL = documentsURL.appendingPathComponent("mounted")
        
        if path.hasPrefix("/var") && appData.UserData.exploit_method == 0 && appData.UserData.allowroot {
            folder_vdata = createFolderAndRedirect2("/private"+path)
            isFolderRdird = true
        } else {
            folderURL = URL(string: path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "file:///")!
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            dirContents = contents.map { isDirectory(url: folderURL.appendingPathComponent($0)) ? "[Folder]\($0)" : $0 }
        } catch {
            print("Error loading directory contents: \(error)")
        }
    }
    
    func isDirectory(url: URL) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            return isDir.boolValue
        } else {
            return false
        }
    }
}

struct FileListItemView: View {
    let path: String
    let item: String
    let isFolder: Bool
    let kfd: Bool
    @Binding var shouldRefresh: Bool
    
    var body: some View {
        if isFolder {
            FileListFolderItemView(path: kfd ? URL.documents.appendingPathComponent("mounted").path : path, item: item.replacingOccurrences(of: "[Folder]", with: ""), shouldRefresh: $shouldRefresh)
        } else {
            FileListFileItemView(path: kfd ? URL.documents.appendingPathComponent("mounted").path : path, item: item, shouldRefresh: $shouldRefresh)
        }
    }
}

struct FileListFolderItemView: View {
    let path: String
    let item: String
    @Binding var shouldRefresh: Bool
    @State private var isCompressionCompleteAlertPresented = false
    @State private var compressionSuccess = true
    @State private var isDeleteAlertPresented = false
    
    var body: some View {
        HStack {
            Image("folder_icon")
                .renderingMode(.template)
            Text(item.replacingOccurrences(of: "[Folder]", with: ""))
                .contextMenu {
                    Button(action: {
                        compressFolder()
                    }) {
                        Text("Compress Folder")
                        Image("zip_icon").renderingMode(.template)
                    }
                    Button(role: .destructive, action: {
                        isDeleteAlertPresented = true
                    }) {
                        Text("Delete Folder")
                        Image("trash_icon").renderingMode(.template)
                    }
                }
        }
        .alert("Delete Folder", isPresented: $isDeleteAlertPresented, actions: {
            Text("Are you sure you want to delete this folder?")
            Button("Delete", role: .destructive, action: {
                deleteFolder()
            })
            Button("Cancel", role: .cancel, action: {
                isDeleteAlertPresented = false
            })
        })
        .alert("Compression Complete", isPresented: $isCompressionCompleteAlertPresented) {
            Text(compressionSuccess ? "Folder compressed successfully!" : "Folder failed to compress!")
            Button("OK", role: .cancel) {
                isCompressionCompleteAlertPresented = false
            }
        }
    }
    
    func compressFolder() {
        let folderPath = path + "/" + item
        let archivePath = path + "/" + item + ".zip"
        
        do {
            try Zip.zipFiles(paths: [URL(fileURLWithPath: folderPath)], zipFilePath: URL(fileURLWithPath: archivePath), password: nil, progress: nil)
            shouldRefresh.toggle()
            compressionSuccess = true
            isCompressionCompleteAlertPresented = true
        } catch {
            compressionSuccess = false
            isCompressionCompleteAlertPresented = true
            print("Error compressing folder: \(error)")
        }
    }
    
    func deleteFolder() {
        do {
            let fileURL = URL(fileURLWithPath: path + "/" + item)
            try FileManager.default.removeItem(at: fileURL)
            shouldRefresh.toggle()
            isDeleteAlertPresented = false
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}

struct FileListFileItemView: View {
    let path: String
    @State var item: String
    @Binding var shouldRefresh: Bool
    @State private var isShareSheetPresented = false
    @State private var isRenameAlertPresented = false
    @State private var isRenameAlertPresented15 = false
    @State private var newFileName = ""
    @State private var isDeleteAlertPresented = false
    @State private var isPlistEditPresented = false
    @State private var isTextEditPresented = false
    @EnvironmentObject var appData: AppData

    var body: some View {
        HStack {
            Image("file_icon")
                .renderingMode(.template)
            Text(item)
                .contextMenu {
                    Button(action: {
                        isShareSheetPresented = true
                    }) {
                        Text("Share File")
                        Image("share_icon").renderingMode(.template)
                    }
                    
                    if item.hasSuffix(".plist") {
                        Button(action: {
                            isPlistEditPresented = true
                        }) {
                            Text("Edit as Plist")
                            Image("edit_icon").renderingMode(.template)
                        }
                    }
                    
                    Button(action: {
                        isTextEditPresented = true
                    }) {
                        Text("Edit as Text")
                        Image("edit_icon").renderingMode(.template)
                    }
                    
                    Button(action: {
                        if #available(iOS 16, *) {
                            isRenameAlertPresented = true
                        } else {
                            isRenameAlertPresented15 = true
                        }
                    }) {
                        Text("Rename File")
                        Image("edit_icon").renderingMode(.template)
                    }
                    
                    Button(role: .destructive, action: {
                        isDeleteAlertPresented = true
                    }) {
                        Text("Delete File")
                        Image("trash_icon").renderingMode(.template)
                    }
                }.onAppear() {
                    newFileName = item
                }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(filePath: path + "/" + item)
        }
        .sheet(isPresented: $isTextEditPresented) {
            TextEditorView(isPresented: $isTextEditPresented, fileURL: URL(fileURLWithPath: path + "/" + item))
        }
        .sheet(isPresented: $isPlistEditPresented) {
            PlistEditorView(isPresented: $isPlistEditPresented, fileURL: URL(fileURLWithPath: path + "/" + item))
        }
        .alert("Rename File", isPresented: $isRenameAlertPresented, actions: {
            TextField("New File Name", text: $newFileName).autocorrectionDisabled()
            Button("Save", action: {
                renameFile()
            })
            Button("Cancel", role: .cancel, action: {
                isRenameAlertPresented = false
            })
        })
        .alert("Delete File", isPresented: $isDeleteAlertPresented, actions: {
            Text("Are you sure you want to delete this file?")
            Button("Delete", role: .destructive, action: {
                deleteFile()
            })
            Button("Cancel", role: .cancel, action: {
                isDeleteAlertPresented = false
            })
        })
        .textFieldAlert(
            title: "Rename File",
            message: "Hit Done to rename or cancel",
            textFields: [
                .init(text: $newFileName)
            ],
            actions: [
                .init(title: "Done")
            ],
            isPresented: $isRenameAlertPresented15
        )
        .onChange(of: isRenameAlertPresented15) { newValue in
            if !newValue {
                renameFile()
            }
        }
    }

    func renameFile() {
        if !newFileName.isEmpty {
            do {
                let sourceURL = URL(fileURLWithPath: path + "/" + item)
                let destinationURL = URL(fileURLWithPath: path + "/" + newFileName)
                try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                item = newFileName
                isRenameAlertPresented = false
            } catch {
                print("Error renaming file: \(error)")
            }
        }
    }

    func deleteFile() {
        do {
            if appData.UserData.exploit_method == 0 && !path.hasPrefix("/var") {
                funVnodeHide(strdup(path + "/" + item))
            } else {
                let fileURL = URL(fileURLWithPath: path + "/" + item)
                try FileManager.default.removeItem(at: fileURL)
                shouldRefresh.toggle()
                isDeleteAlertPresented = false
            }
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var filePath: String

    func makeUIViewController(context: Context) -> UIViewController {
        let activityItems: [Any] = [URL(fileURLWithPath: filePath)]
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        return activityViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the view controller if needed
    }
}




// Editors

struct TextEditorView: View {
    @Binding var isPresented: Bool
    @State private var text = ""
    var fileURL: URL?

    var body: some View {
        NavigationView {
            TextEditor(text: $text)
                .padding()
                .navigationTitle("Text Editor")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveText()
                            isPresented = false
                        }
                    }
                }.onAppear {
                    loadText()
                }
        }
    }
    
    private func loadText() {
        guard let fileURL = fileURL else {
            return
        }

        do {
            print(fileURL)
            text = try String(contentsOf: fileURL)
        } catch {
            print("Error loading text: \(error)")
        }
    }
    
    private func saveText() {
        guard let fileURL = fileURL else {
            return
        }

        do {
            try text.write(to: fileURL, atomically: false, encoding: .utf8)
            print("Text saved successfully!")
        } catch {
            print("Error saving text: \(error)")
        }
    }
}

struct Expandable {
    var isExpanded: Bool = false
}

struct PlistEditorView: View {
    @State private var plistData: Any?
    @Binding var isPresented: Bool
    var fileURL: URL?
    @State private var sectionStates: [Expandable] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Plist Data")) {
                    PlistRowView(key: "Root", value: $plistData, isSectionExpanded: $sectionStates)
                }
            }
            .navigationTitle("Plist Editor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePlist()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                loadPlist()
            }
        }
    }

    // Load plist data from the file
    private func loadPlist() {
        guard let plistPath = fileURL else {
            return
        }
        
        do {
            let rawPlistData = try Data(contentsOf: plistPath)
            plistData = try PropertyListSerialization.propertyList(from: rawPlistData, options: [], format: nil)
            sectionStates = Array(repeating: Expandable(), count: 1) // Initialize with one section expanded
        } catch {
            print("Error loading plist: \(error)")
        }
    }

    // Save plist data to the file
    private func savePlist() {
        guard let plistPath = fileURL else {
            return
        }
        
        do {
            let plistDataToSave = try PropertyListSerialization.data(fromPropertyList: plistData!, format: .xml, options: 0)
            try plistDataToSave.write(to: plistPath)
            print("Plist saved successfully!")
        } catch {
            print("Error saving plist: \(error)")
        }
    }
}

struct PlistRowView: View {
    let key: String
    @Binding var value: Any?
    @Binding var isSectionExpanded: [Expandable]

    var body: some View {
        VStack(alignment: .leading) {
            if let dictValue = value as? [String: Any] {
                DisclosureGroup(isExpanded: $isSectionExpanded[0].isExpanded) {
                    ForEach(Array(dictValue.keys), id: \.self) { nestedKey in
                        PlistRowView(key: nestedKey, value: Binding(
                            get: { dictValue[nestedKey] },
                            set: { newValue in
                                var updatedValue = dictValue
                                updatedValue[nestedKey] = newValue
                                value = updatedValue
                            }
                        ), isSectionExpanded: $isSectionExpanded)
                    }
                } label: {
                    Text(key)
                        .font(.headline)
                }
            } else if let arrayValue = value as? [Any] {
                DisclosureGroup(isExpanded: $isSectionExpanded[0].isExpanded) {
                    ForEach(0..<arrayValue.count, id: \.self) { index in
                        PlistRowView(key: "\(index)", value: Binding(
                            get: { arrayValue[index] },
                            set: { newValue in
                                var updatedValue = arrayValue
                                updatedValue[index] = newValue
                                value = updatedValue
                            }
                        ), isSectionExpanded: $isSectionExpanded)
                    }
                } label: {
                    Text(key)
                        .font(.headline)
                }
            } else if let stringValue = value as? String {
                TextField("Enter \(key)", text: Binding(
                    get: { stringValue },
                    set: { newValue in
                        value = newValue
                    }
                ))
            } else if let intValue = value as? Int {
                Stepper(value: Binding(
                    get: { intValue },
                    set: { newValue in
                        value = newValue
                    }
                )) {
                    Text("Value: \(intValue)")
                }
            }
        }
    }
}
