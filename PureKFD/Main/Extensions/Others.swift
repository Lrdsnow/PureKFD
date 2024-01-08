//
//  Others.swift
//  PureKFD
//
//  Created by Lrdsnow on 11/4/23.
//

import Foundation
import UIKit

func haptic() {
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
    impactFeedbackgenerator.impactOccurred()
}

func overwriteFile(at filePath: String, with newData: Data) throws {
    if FileManager.default.fileExists(atPath: URL.documents.appendingPathComponent("TempOverwriteFile").path) {
        try? FileManager.default.removeItem(at: URL.documents.appendingPathComponent("TempOverwriteFile"))
    }
    try newData.write(to: URL.documents.appendingPathComponent("TempOverwriteFile"))
    _ = try overwriteWithFileImpl(replacementURL: URL.documents.appendingPathComponent("TempOverwriteFile"), pathToTargetFile: filePath)
}

extension String {
    func removingFileExtensions(_ count: Int) -> String {
        let components = self.components(separatedBy: ".")
        if components.count > count {
            let lastIndex = components.index(components.endIndex, offsetBy: -count)
            let pathWithoutExtensions = components[..<lastIndex]
            return pathWithoutExtensions.joined(separator: ".")
        }
        return self
    }
}

class FileDownloader {
    var filePath: String?

    func downloadFile(from urlString: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectory.appendingPathComponent(UUID().uuidString)

        let downloadTask = URLSession.shared.downloadTask(with: url) { (location, _, error) in
            defer {
                completion(self.filePath != nil ? .success(self.filePath!) : .failure(error ?? NSError()))
            }

            if let error = error {
                NSLog("Error downloading file: %@", error.localizedDescription)
                return
            }

            do {
                try FileManager.default.moveItem(at: location!, to: temporaryFileURL)
                self.filePath = temporaryFileURL.path
            } catch {
                NSLog("Error moving file to temporary directory: %@", error.localizedDescription)
            }
        }

        downloadTask.resume()
    }
}

extension String {
    func downloadFile() -> String? {
        var filePath: String?
        let downloader = FileDownloader()

        downloader.downloadFile(from: self) { result in
            switch result {
            case .success(let path):
                filePath = path
            case .failure(let error):
                NSLog("Error downloading file: %@", error.localizedDescription)
            }
        }
        
        while filePath == nil {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        return filePath
    }
}

func cleanTemp() {
    do {
        let contents = try FileManager.default.contentsOfDirectory(at: FileManager.default.temporaryDirectory, includingPropertiesForKeys: nil, options: [])
        for fileURL in contents {
            try FileManager.default.removeItem(at: fileURL)
        }
    } catch {
        // Handle any errors that occur during the deletion process.
        NSLog("Error clearing temporary directory: %@", "\(error)")
    }
}

func getContentsOfFolder(folderURL: URL) -> [URL]? {
    do {
        let fileManager = FileManager.default
        let folderContents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        return folderContents
    } catch {
        NSLog("Error: %@","\(error)")
        return nil
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension String {
    func toJSON() -> [String: Any]? {
        let lines = self.components(separatedBy: "\n")
        var jsonObject: [String: Any] = [:]

        for line in lines {
            let components = line.components(separatedBy: ": ")
            if components.count == 2 {
                let key = components[0]
                let value = components[1]
                jsonObject[key] = value
            } else if components.count > 2 {
                let key = components[0]
                let value = components[1..<components.count].joined(separator: ": ")
                jsonObject[key] = value
            }
        }

        return jsonObject.isEmpty ? nil : jsonObject
    }
    func toJSONArray() -> [[String: Any]] {
        let packageStrings = self.components(separatedBy: "\n\n")
        var jsonArray: [[String: Any]] = []

        for packageString in packageStrings {
            let lines = packageString.components(separatedBy: "\n")
            var jsonObject: [String: Any] = [:]

            for line in lines {
                let components = line.components(separatedBy: ": ")
                if components.count == 2 {
                    let key = components[0]
                    let value = components[1]
                    jsonObject[key] = value
                } else if components.count > 2 {
                    let key = components[0]
                    let value = components[1..<components.count].joined(separator: ": ")
                    jsonObject[key] = value
                }
            }

            if !jsonObject.isEmpty {
                jsonArray.append(jsonObject)
            }
        }

        return jsonArray
    }
}

extension Array {
    func atIndex(_ index: Int) -> Element? {
        return index < count ? self[index] : nil
    }
}

extension Array {
    
    /**
     Attempt to convert a tuple into an Array.
     
     - Parameter tuple: The tuple to try and convert. All members must be of the same type.
     - Returns: An array of the tuple's values, or `nil` if any tuple members do not match the `Element` type of this array.
     */
    static func fromTuple<Tuple> (_ tuple: Tuple) -> [Element]? {
        let val = Array<Element>.fromTupleOptional(tuple)
        return val.allSatisfy({ $0 != nil }) ? val.map { $0! } : nil
    }
    
    /**
     Convert a tuple into an array.
     
     - Parameter tuple: The tuple to try and convert.
     - Returns: An array of the tuple's values, with `nil` for any values that could not be cast to the `Element` type of this array.
     */
    static func fromTupleOptional<Tuple> (_ tuple: Tuple) -> [Element?] {
        return Mirror(reflecting: tuple)
            .children
            .filter { child in
                (child.label ?? "x").allSatisfy { char in ".1234567890".contains(char) }
            }.map { $0.value as? Element }
    }
}

func refreshView(appData:AppData) {
    if getDeviceInfo(appData: nil).3.lowend == false {
        appData.UserData.refresh.toggle()
        appData.save()
    }
}

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    static var documents: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
