//
//  SparseRestore.swift
//  PureKFD
//
//  Created by Lrdsnow on 10/5/24.
//

import Foundation

class SparseRestore: NSObject {
    
    @objc public static func overwriteFile(_ from: URL, to: URL) {
        let fm = FileManager.default
        let venv = URL.documents.appendingPathComponent("venv")
        try? fm.createDirectory(at: venv.appendingPathComponent(to.deletingLastPathComponent().path), withIntermediateDirectories: true)
        try? fm.copyItem(at: from, to: venv.appendingPathComponent(to.path))
    }
    
}
