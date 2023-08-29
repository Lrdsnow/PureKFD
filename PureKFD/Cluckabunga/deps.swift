//
//  deps.swift
//  PurityKFD
//
//  Created by Lrdsnow on 8/21/23.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

extension URL {
    static var documents: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

func overwriteWithFileImpl(
    replacementURL: URL,
    pathToTargetFile: String
) {
//    var replacementData: Data = try! Data(contentsOf: replacementURL)
        let cPathtoTargetFile = pathToTargetFile.withCString { ptr in
            return strdup(ptr)
        }
        
        let mutablecPathtoTargetFile = UnsafeMutablePointer<Int8>(mutating: cPathtoTargetFile)
        
        let cFileURL = replacementURL.path.withCString { ptr in
            return strdup(ptr)
        }
        let mutablecFileURL = UnsafeMutablePointer<Int8>(mutating: cFileURL)
        
        funVnodeOverwrite2(cPathtoTargetFile, mutablecFileURL) // the magic is here
}

func overwriteFile(at filePath: String, with newData: Data) throws {
    if FileManager.default.fileExists(atPath: URL.documents.appendingPathComponent("TempOverwriteFile").path) {
        try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("TempOverwriteFile"))
    }
    try newData.write(to: URL.documents.appendingPathComponent("TempOverwriteFile"))
    overwriteWithFileImpl(replacementURL: URL.documents.appendingPathComponent("TempOverwriteFile"), pathToTargetFile: filePath)
}
