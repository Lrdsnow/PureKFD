//
//  SparseRestore.swift
//  PureKFD
//
//  Created by Lrdsnow on 10/5/24.
//

import Foundation
import PythonKit

class SparseRestore: NSObject {
    
    @objc public static func overwriteFile(_ from: URL, to: URL) {
        if to.path.contains("/var") {
            let target = URL.documents.appendingPathComponent("temp").appendingPathComponent(to.path)
            let targetDir = target.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
            
            try? FileManager.default.copyItem(at: from, to: target)
            
            let backupInfoURL = URL.documents.appendingPathComponent("temp/backup_info.json")
            var backupInfo: [String] = []
            if let data = try? Data(contentsOf: backupInfoURL),
               let existingInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
                backupInfo = existingInfo
            }
            backupInfo.append(to.path)
            if let data = try? JSONSerialization.data(withJSONObject: backupInfo, options: .prettyPrinted) {
                try? data.write(to: backupInfoURL)
            }
        }
    }
    
    @objc public static func endExploit(_ json: [String:String]) -> String? {
        let tempBackupDir = URL.documents.appendingPathComponent("temp")
        let backupPath = URL.documents.appendingPathComponent("backup")
        let fm = FileManager.default
        if fm.fileExists(atPath: tempBackupDir.path) {
            setenv("PYTHON_LIBRARY", "/Library/Frameworks/Python.framework/Versions/3.12/lib/libpython3.12.dylib", 1)
            let sys = Python.import("sys")
            sys.path.append(Bundle.main.resourcePath)
            let exploit = Python.import("exploit")
            exploit.apply_purekfd(tempBackupDir.path)
        }
        return nil
    }
}
