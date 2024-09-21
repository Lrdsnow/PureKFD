//
//  TweakApply.swift
//  purekfd
//
//  Created by Lrdsnow on 7/1/24.
//

import Foundation

public class TweakHandler {
    
    public static func processOverwrite(_ dir: URL, _ ogDir: URL, _ exploit: Int) throws {
        let fm = FileManager.default
        let items = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        for item in items {
            var isDir: ObjCBool = false
            fm.fileExists(atPath: item.path, isDirectory: &isDir)
            
            if isDir.boolValue {
                try processOverwrite(item, ogDir, exploit)
            } else {
                let relativePath = item.path.replacingOccurrences(of: ogDir.path, with: "")
                let rootPath = URL(fileURLWithPath: "/").appendingPathComponent(relativePath)
                let processedPath = TweakPath.processPath(rootPath, ogDir.deletingLastPathComponent(), exploit)
                if let processedPath = processedPath {
                    ExploitHandler.overwriteFile(processedPath.from ?? item, URL(fileURLWithPath: processedPath.toPath), exploit)
                }
            }
        }
    }
    
    public static func applyTweak(pkg: Package, _ exploit: Int) {
        try? Data().write(to: URL.documents.appendingPathComponent("apply.lock"))
        
        do {
            let overwriteDir = pkg.pkgpath.appendingPathComponent("Overwrite")
            try processOverwrite(overwriteDir, overwriteDir, exploit)
        } catch {
            print("error: \(error)")
        }
        
        try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("apply.lock"))
    }
    
    public static func applyTweaks(pkgs: [Package], _ exploit: Int, _ json: [String: String]) {
        try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("temp"))
        try? FileManager.default.createDirectory(at: URL.documents.appendingPathComponent("temp"), withIntermediateDirectories: true)
        let loadingPopup = showLoadingPopup()
        Task.detached {
            if let start_result = ExploitHandler.startExploit(exploit, json: json) {
                DispatchQueue.main.async {
                    loadingPopup.dismiss(animated: true) {
                        showPopup("Error", start_result)
                    }
                }
            } else {
                for pkg in pkgs {
                    if !(pkg.disabled ?? false) {
                        self.applyTweak(pkg: pkg, exploit)
                    }
                }
                if let end_result = ExploitHandler.endExploit(exploit, json: json) {
                    DispatchQueue.main.async {
                        loadingPopup.dismiss(animated: true) {
                            showPopup("Error", end_result)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        loadingPopup.dismiss(animated: true) {
                            showPopup("Success", "Successfully applied")
                        }
                    }
                }
            }
        }
    }
    
}
