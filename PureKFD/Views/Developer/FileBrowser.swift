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
import SwiftKFD
import SwiftKFD_objc

@available(iOS 15.0, *)
struct FileBrowserView: View {
    let root: Bool
    @EnvironmentObject var appData: AppData
    @State var currentPath = ""
    @State var exploit_method: Int = 0
    @State var kfddata = SavedKFDData()
    @State var popover = false
    @State var pickerpath = ""
    
    var body: some View {
        Group {
            if !root {
                FileBrowser(appData: appData, currentFullPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path, root: root, pickerpath: $pickerpath, popover: $popover)
                    .navigationTitle("File Browser")
            } else {
                FileBrowser(appData: appData, currentFullPath: "", root: root, pickerpath: $pickerpath, popover: $popover)
                    .navigationTitle("File Browser")
                    .navigationBarItems(trailing: ToggleButtonView(kopened: $appData.kopened, exploit_method: $exploit_method, kfddata: $kfddata))
            }
        }.bgImage(appData).task() {
            exploit_method = getDeviceInfo(appData: appData).0
            kfddata = getDeviceInfo(appData: appData).1
            NSLog("%@", "\(root)")
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
                    let exploit_result = do_kopen(UInt64(kfddata.puaf_pages), UInt64(kfddata.puaf_method), UInt64(kfddata.kread_method), UInt64(kfddata.kwrite_method), size_t(256))
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

@available(iOS 15.0, *)
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
    let root: Bool
    
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
                        NavigationLink(destination: FileBrowser(appData: appData, currentPath: item.replacingOccurrences(of: "[Folder]", with: ""), currentFullPath: currentFullPath + "/" + item.replacingOccurrences(of: "[Folder]", with: ""), isSubFolder: true, root: root, pickerpath: $pickerpath, popover: $popover).navigationTitle(item.replacingOccurrences(of: "[Folder]", with: ""))) {
                            FileListItemView(path: currentFullPath, item: item, isFolder: true, kfd: (appData.UserData.exploit_method == 0 && root), shouldRefresh: $shouldRefresh)
                        }
                    } else {
                        if !popover {
                            FileListItemView(path: currentFullPath, item: item, isFolder: false, kfd: (appData.UserData.exploit_method == 0 && root), shouldRefresh: $shouldRefresh)
                        } else {
                            Button(action: {
                                pickerpath = "\(currentFullPath)/\(item)"
                                popover = false
                            }) {
                                FileListItemView(path: currentFullPath, item: item, isFolder: false, kfd: (appData.UserData.exploit_method == 0 && root), shouldRefresh: $shouldRefresh)
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
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
            let itempath = appData.UserData.lastCopiedFile.replacingOccurrences(of: "_PureKFDDocuments_", with: URL.documents.path)
            var copiedpathdirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: itempath, isDirectory: &copiedpathdirectory) {
                Button(action: {
                    do {
                        try FileManager.default.copyItem(atPath: appData.UserData.lastCopiedFile.replacingOccurrences(of: "_PureKFDDocuments_", with: URL.documents.path) , toPath: currentFullPath+"/"+itempath.components(separatedBy: "/").last!)
                    } catch {UIApplication.shared.alert(body: error.localizedDescription, withButton: true)}
                    shouldRefresh.toggle()
                }) {
                    Text(copiedpathdirectory.boolValue ? "Paste Folder" : "Paste File")
                    Image(copiedpathdirectory.boolValue ? "folder_icon" : "file_icon").renderingMode(.template)
                }
            }
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
        .task {
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
                        NSLog("%@", "Error creating empty file: \(error)")
                    }
                } else {
                    let folderPath = currentFullPath + "/" + newFileFolderName
                    do {
                        try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
                        shouldRefresh.toggle()
                    } catch {
                        NSLog("%@", "Error creating empty folder: \(error)")
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
                        NSLog("%@", "Error creating empty file: \(error)")
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
                        NSLog("%@", "Error creating empty folder: \(error)")
                    }
                }
            }
        }
    }
    
    private func loadContentsInDirectory(path: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var folderURL: URL = documentsURL.appendingPathComponent("mounted")
        
        NSLog(path)
        NSLog("KFD? %d",getDeviceInfo(appData: appData).0 == 0)
        NSLog("Root? %d",root)
        
        if path.hasPrefix("/var") && getDeviceInfo(appData: appData).0 == 0 && root && ((try? (FileManager.default.contentsOfDirectory(atPath: "/var"))) == nil) {
            folder_vdata = createFolderAndRedirect2("/private"+path)
            isFolderRdird = true
        } else {
            folderURL = URL(string: path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "file:///")!
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            dirContents = contents.map { isDirectory(url: folderURL.appendingPathComponent($0)) ? "[Folder]\($0)" : $0 }
        } catch {
            NSLog("%@", "Error loading directory contents: \(error)")
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

@available(iOS 15.0, *)
struct FileListItemView: View {
    let path: String
    let item: String
    let isFolder: Bool
    let kfd: Bool
    @Binding var shouldRefresh: Bool
    
    var body: some View {
        Group {
            if isFolder {
                FileListFolderItemView(path: kfd ? FileManager.default.temporaryDirectory.path : path, item: item.replacingOccurrences(of: "[Folder]", with: ""), kfd: kfd, shouldRefresh: $shouldRefresh)
            } else {
                FileListFileItemView(path: kfd ? FileManager.default.temporaryDirectory.path : path, item: item, shouldRefresh: $shouldRefresh)
            }
        }.task() {
            if kfd {
                do {
                    try FileManager.default.copyItem(at: URL(fileURLWithPath: path+item), to: FileManager.default.temporaryDirectory.appendingPathComponent(item))
                } catch {}
            }
        }.onChange(of: shouldRefresh, perform: { _ in
            if kfd {
                let pathCString = strdup(path+item)
                let tempPathCString = strdup(FileManager.default.temporaryDirectory.appendingPathComponent(item).path)
                if pathCString != nil && tempPathCString != nil {
                    funVnodeOverwrite2(pathCString, tempPathCString)
                    do {
                        try FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent(item))
                    } catch {}
                    free(pathCString)
                    free(tempPathCString)
                } else {
                    NSLog("Memory allocation failed for C strings.")
                }
            }

        })
    }
}

@available(iOS 15.0, *)
struct FileListFolderItemView: View {
    let path: String
    let item: String
    let kfd: Bool
    @Binding var shouldRefresh: Bool
    @State private var isCompressionCompleteAlertPresented = false
    @State private var compressionSuccess = true
    @State private var isDeleteAlertPresented = false
    @State private var isInfoPresented = false
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        HStack {
            Image("folder_icon")
                .resizable()
                .renderingMode(.template)
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                .aspectRatio(contentMode: .fit).frame(maxHeight: 50)
            VStack(alignment: .leading) {
                Text((UUID(uuidString: item) != nil) ? (try? getBundleID(path: path, uuid: item, exploit_method: kfd ? 0 : 1)) ?? "" : item)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .contextMenu {
                        Button(action: {
                            isInfoPresented = true
                        }) {
                            Text("Show Folder Info")
                            Image("copy_icon").renderingMode(.template)
                        }
                        
                        Button(action: {
                            appData.UserData.lastCopiedFile = (path+"/"+item).replacingOccurrences(of: URL.documents.path, with: "_PureKFDDocuments_")
                            appData.save()
                            shouldRefresh.toggle()
                        }) {
                            Text("Copy Folder")
                            Image("copy_icon").renderingMode(.template)
                        }
                        Button(action: {
                            compressFolder()
                        }) {
                            Text("Compress & Share Folder")
                            Image("zip_icon").renderingMode(.template)
                        }
                        Button(role: .destructive, action: {
                            isDeleteAlertPresented = true
                        }) {
                            Text("Delete Folder")
                            Image("trash_icon").renderingMode(.template)
                        }
                    }
                    .lineLimit(1)
                if UUID(uuidString: item) != nil {
                    Text(item).font(.footnote).opacity(0.7).lineLimit(1)
                }
            }
        }
        .sheet(isPresented: $isInfoPresented) {
            let fileurl = URL(fileURLWithPath: path+"/"+item)
            FileInfoView(fileURL: fileurl, popover: $isInfoPresented)
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
        .alert("Error", isPresented: $isCompressionCompleteAlertPresented) {
            Text("Folder failed to compress!")
            Button("OK", role: .cancel) {
                isCompressionCompleteAlertPresented = false
            }
        }
    }
    
    func compressFolder() {
        let folderPath = path + "/" + item
        let archivePath = FileManager.default.temporaryDirectory.path + "/" + item + ".zip"
        
        do {
            try Zip.zipFiles(paths: [URL(fileURLWithPath: folderPath)], zipFilePath: URL(fileURLWithPath: archivePath), password: nil, progress: nil)
            shouldRefresh.toggle()
            let av = UIActivityViewController(activityItems: [URL(fileURLWithPath: archivePath)], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
        } catch {
            isCompressionCompleteAlertPresented = true
            NSLog("%@", "Error compressing folder: \(error)")
        }
    }
    
    func deleteFolder() {
        do {
            let fileURL = URL(fileURLWithPath: path + "/" + item)
            try FileManager.default.removeItem(at: fileURL)
            shouldRefresh.toggle()
            isDeleteAlertPresented = false
        } catch {
            NSLog("%@", "Error deleting file: \(error)")
        }
    }
}

func isTextFile(at url: URL) -> Bool {
    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as NSString, nil)?.takeRetainedValue() {
        return UTTypeConformsTo(uti, kUTTypeText)
    }
    return false
}

func isPlistFile(at url: URL) -> Bool {
    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as NSString, nil)?.takeRetainedValue() {
        return UTTypeConformsTo(uti, kUTTypePropertyList)
    }
    return false
}

@available(iOS 15.0, *)
struct FileListFileItemView: View {
    let path: String
    @State var item: String
    @Binding var shouldRefresh: Bool
    @State private var isRenameAlertPresented = false
    @State private var isRenameAlertPresented15 = false
    @State private var newFileName = ""
    @State private var isDeleteAlertPresented = false
    @State private var isInfoPresented = false
    @State private var isPlistEditPresented = false
    @State private var isTextEditPresented = false
    @EnvironmentObject var appData: AppData

    var body: some View {
        HStack {
            Image("file_icon")
                .resizable()
                .renderingMode(.template)
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                .aspectRatio(contentMode: .fit).frame(maxHeight: 50)
            Text(item)
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                .contextMenu {
                    Button(action: {
                        isInfoPresented = true
                    }) {
                        Text("Show File Info")
                        Image("copy_icon").renderingMode(.template)
                    }
                    
                    Button(action: {
                        appData.UserData.lastCopiedFile = (path+"/"+item).replacingOccurrences(of: URL.documents.path, with: "_PureKFDDocuments_")
                        appData.save()
                        shouldRefresh.toggle()
                    }) {
                        Text("Copy File")
                        Image("copy_icon").renderingMode(.template)
                    }
                    
                    Button(action: {
                        let av = UIActivityViewController(activityItems: [URL(fileURLWithPath: path+"/"+item)], applicationActivities: nil)
                        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                    }) {
                        Text("Share File")
                        Image("share_icon").renderingMode(.template)
                    }
                    
                    if isPlistFile(at: URL(fileURLWithPath: path+"/"+item)) {
                        Button(action: {
                            isPlistEditPresented = true
                        }) {
                            Text("Edit as Plist")
                            Image("edit_icon").renderingMode(.template)
                        }
                    }
                    
                    if isTextFile(at: URL(fileURLWithPath: path+"/"+item)) {
                        Button(action: {
                            isTextEditPresented = true
                        }) {
                            Text("Edit as Text")
                            Image("edit_icon").renderingMode(.template)
                        }
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
                }.task() {
                    newFileName = item
                }
        }
        .sheet(isPresented: $isInfoPresented) {
            let fileurl = URL(fileURLWithPath: path+"/"+item)
            FileInfoView(fileURL: fileurl, popover: $isInfoPresented)
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
                NSLog("Error renaming file: \(error)")
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
            NSLog("Error deleting file: %@", "\(error)")
        }
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
        }.navigationViewStyle(.stack)
    }
    
    private func loadText() {
        guard let fileURL = fileURL else {
            return
        }

        do {
            NSLog("%@", "\(fileURL)")
            text = try String(contentsOf: fileURL)
        } catch {
            NSLog("Error loading text: %@", "\(error)")
        }
    }
    
    private func saveText() {
        guard let fileURL = fileURL else {
            return
        }

        do {
            try text.write(to: fileURL, atomically: false, encoding: .utf8)
            NSLog("Text saved successfully!")
        } catch {
            NSLog("Error saving text: %@", "\(error)")
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
        }.navigationViewStyle(.stack)
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
            NSLog("%@", "Error loading plist: \(error)")
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
            NSLog("Plist saved successfully!")
        } catch {
            NSLog("%@", "Error saving plist: \(error)")
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
                                updatedValue[index] = newValue ?? ""
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

struct FileInfoView: View {
    let fileURL: URL
    @Binding var popover: Bool

    var body: some View {
        NavigationView {
            VStack {
                if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
                    if let fileType = fileAttributes[.type] as? String,
                       let fileSize = fileAttributes[.size] as? Int {
                        List {
                            VStack(alignment: .leading) {
                                // Display icon based on file type
                                Image(systemName: iconNameForFileType(fileType))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                Text("\(fileURL.lastPathComponent)").font(.title)
                            }.hideListRowSeparator()
                            
                            Section(header: Text("Info").font(.footnote)) {
                                if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
                                    VStack(alignment: .leading) {
                                        Text("\(itemType(fileType)) Extension: \(fileURL.pathExtension)")
                                        Text("\(itemType(fileType)) Type: \(userFriendlyFileType(from: fileType))")
                                        Text("\(itemType(fileType)) Size: \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)) (\(fileAttributes[.size] as? Int64 ?? 0) bytes)")
                                        let dateFormatter: DateFormatter = {
                                            let formatter = DateFormatter()
                                            formatter.dateFormat = "h:mma MM/dd/yy zzz"
                                            return formatter
                                        }()
                                        Text("Creation Date: \(dateFormatter.string(from: fileAttributes[.creationDate] as? Date ?? Date()))")
                                        Text("Modification Date: \(dateFormatter.string(from: fileAttributes[.modificationDate] as? Date ?? Date()))")
                                        Text("Full Path: \(fileURL.path)")
                                    }
                                } else {Text("Permission Denied")}
                            }
                        }.padding()
                    }
                } else {
                    Text("Invalid file or folder")
                }
            }.navigationBarTitle("info", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {popover = false}) {
                Text("Done").bold()
            })
        }.navigationViewStyle(.stack)
    }

    // Function to convert NSFileType to a user-friendly string
    private func userFriendlyFileType(from fileType: String) -> String {
        switch fileType {
        case FileType.regular.rawValue:
            return "Regular File"
        case FileType.directory.rawValue:
            return "Directory"
        case FileType.symbolicLink.rawValue:
            return "Symbolic Link"
        // Add more cases as needed
        default:
            return "Unknown"
        }
    }
    
    // Function to map file extensions to system icons
    private func iconNameForFileType(_ fileType: String) -> String {
        switch fileType {
        case FileType.regular.rawValue:
            return "doc"
        case FileType.symbolicLink.rawValue:
            return "link"
        case FileType.directory.rawValue:
            return "folder"
        default:
            return "questionmark"
        }
    }
    
    private func itemType(_ fileType: String) -> String {
        switch fileType {
        case FileType.regular.rawValue:
            return "File"
        case FileType.symbolicLink.rawValue:
            return "Link"
        case FileType.directory.rawValue:
            return "Folder"
        default:
            return "questionmark"
        }
    }
}

enum FileType: String {
    case regular = "NSFileTypeRegular"
    case directory = "NSFileTypeDirectory"
    case symbolicLink = "NSFileTypeSymbolicLink"
    // Add more cases as needed
}
