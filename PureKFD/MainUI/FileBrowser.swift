//
//  FileBrowser.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/2/23.
//

import SwiftUI

struct FileBrowser: View {
    @Binding var exploit_method: Int
    @State private var searchText = ""
    @State var currentPath = ""
    @State var currentFullPath = ""
    @State private var dirContents: [String] = []
    @State private var isShowingContextMenu = false
    @State private var folder_vdata: UInt64 = 0
    @State var isSubFolder = false
    @State var isFolderRdird = false
    
    var body: some View {
            VStack(spacing: 0) {
                TextField("Search Current Directory", text: $searchText)
                    .padding(7)
                    .background(Color.clear)
                    .foregroundColor(Color.purple)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.purple, lineWidth: 1)
                    )
                    .padding(.horizontal, 15)
                    .disableAutocorrection(true)
                    .onChange(of: searchText) { newValue in
                        // Implement directory search logic and update dirContents here
                        searchContents()
                    }
                
                List {
                    ForEach(dirContents, id: \.self) { item in
                        if item.hasPrefix("[Folder]") {
                            NavigationLink(destination: FileBrowser(exploit_method: $exploit_method, currentPath: item.replacingOccurrences(of: "[Folder]", with: ""), currentFullPath: currentFullPath+"/"+item.replacingOccurrences(of: "[Folder]", with: ""), isSubFolder: true).navigationBarTitle(currentFullPath+"/"+item.replacingOccurrences(of: "[Folder]", with: ""), displayMode: .large), label: {
                                Text(item.replacingOccurrences(of: "[Folder]", with: ""))
                            })
                        } else {
                            Text(item)
                                .contextMenu {
                                    Button(action: {
                                        // Implement sharing action
                                    }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button(action: {
                                        // Implement deleting action
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button(action: {
                                        // Implement renaming action
                                    }) {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    
                                    Button(action: {
                                        // Implement copying action
                                    }) {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                }
                        }
                    }.listRowBackground(Color.clear).foregroundColor(.purple)
                }
                .onAppear {
                    if exploit_method == 1 {
                        grant_full_disk_access() { error in
                            if (error != nil) {
                                UIApplication.shared.alert(title: "Access Error", body: "Error: \(String(describing: error!.localizedDescription))\nPlease close the app and retry.")
                            }
                        }
                    }
                    if currentFullPath.isEmpty {
                        loadContentsInDirectory(path: "/")
                    } else {
                        loadContentsInDirectory(path: currentFullPath)
                    }
                }
            }.onDisappear {
                if isFolderRdird && (exploit_method == 0) {
                    let mntPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("mounted")
                    UnRedirectAndRemoveFolder(folder_vdata, mntPathURL.path)
                }
            }
    }
    
    private func loadContentsInDirectory(path: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var folderURL = documentsURL.appendingPathComponent("mounted")
        let filepath = path
        print(filepath)
        
        if filepath.hasPrefix("/var") && (exploit_method == 0) {
            let cFileURL = filepath.withCString { ptr in
                return strdup(ptr)
            }
            let mutablecFileURL = UnsafeMutablePointer<Int8>(mutating: cFileURL)
            
            folder_vdata = createFolderAndRedirect(getVnodeAtPathByChdir(mutablecFileURL), folderURL.path)
            isFolderRdird = true
        } else {
            folderURL = URL(string: filepath)!
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            dirContents = contents.map { isDirectory(url: folderURL) ? "[Folder]\($0)" : $0 }
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
    
    private func searchContents() {
            do {
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let folderURL = documentsURL.appendingPathComponent("mounted")
                
                var contents = try FileManager.default.contentsOfDirectory(atPath: "/")
                
                if isFolderRdird {
                    contents = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
                } else if !currentFullPath.isEmpty {
                    contents = try FileManager.default.contentsOfDirectory(atPath: currentFullPath)
                }
                
                // Filter the contents based on the search text
                if !searchText.isEmpty {
                    dirContents = contents
                        .filter { $0.lowercased().contains(searchText.lowercased()) }
                        .map { isDirectory(url: folderURL) ? "[Folder]\($0)" : $0 }
                } else {
                    dirContents = contents
                        .map { isDirectory(url: folderURL) ? "[Folder]\($0)" : $0 }
                }
            } catch {
                print("Error searching directory contents: \(error)")
            }
    }
}
