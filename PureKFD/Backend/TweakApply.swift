//
//  TweakApply.swift
//  purekfd
//
//  Created by Lrdsnow on 7/1/24.
//

import Foundation

public class TweakHandler {
    
    public enum ApplyMode {
        case overwrite
        case restore
    }
    
    public static func processOverwrite(_ dir: URL, _ ogDir: URL, _ exploit: Int, _ saveEnv: [String:String] = [:]) throws {
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
                let processedPath = TweakPath.processPath(rootPath, ogDir.deletingLastPathComponent(), exploit, saveEnv)
                if let processedPath = processedPath {
                    ExploitHandler.overwriteFile(processedPath.from ?? item, URL(fileURLWithPath: processedPath.toPath), exploit)
                }
            }
        }
    }
    
    public static func applyTweak(pkg: Package, _ exploit: Int, _ mode: ApplyMode = .overwrite, _ saveEnv: [String:String] = [:]) {
        //try? Data().write(to: URL.documents.appendingPathComponent("apply.lock"))
        
        let overwriteDir = pkg.pkgpath.appendingPathComponent(mode == .overwrite ? "Overwrite" : "Restore")
        if FileManager.default.fileExists(atPath: overwriteDir.path) {
            do {
                try processOverwrite(overwriteDir, overwriteDir, exploit, saveEnv)
            } catch {
                log("[!] Error applying tweak \(pkg.name) (\(pkg.bundleid)): \(error)")
            }
        } else if mode == .overwrite {
            log("[!] Error applying tweak \(pkg.name) (\(pkg.bundleid)): No Overwrite Folder!!!")
        } else if mode == .restore {
            log("[!] No Restore folder for tweak \(pkg.name) (\(pkg.bundleid)), Skipping")
        }
        
        //try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("apply.lock"))
    }
    
    public static func applyTweaks(pkgs: [Package], _ exploit: Int, _ mode: ApplyMode = .overwrite, _ json: [String: String], _ saveEnv: [String:String] = [:]) {
        try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("temp"))
        try? FileManager.default.createDirectory(at: URL.documents.appendingPathComponent("temp"), withIntermediateDirectories: true)
        let loadingPopup = showLoadingPopup()
        Task.detached {
            log("[i] Starting Apply using \(ExploitHandler.exploits[exploit].name)")
            if let start_result = ExploitHandler.startExploit(exploit, json: json) {
                DispatchQueue.main.async {
                    loadingPopup.dismiss(animated: true) {
                        showPopup("Error", start_result)
                    }
                }
            } else {
                for pkg in pkgs {
                    if !(pkg.disabled ?? false) {
                        self.applyTweak(pkg: pkg, exploit, mode, saveEnv)
                    }
                }
                log("[i] Ending Apply")
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
                log("[i] Finished Apply")
            }
        }
    }
    
}
