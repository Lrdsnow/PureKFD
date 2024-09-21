//
//  Debug.swift
//  purekfd
//
//  Created by Lrdsnow on 7/1/24.
//

import Foundation

func log(_ text: Any...) {
    let logFilePath = URL.documents.appendingPathComponent("logs.txt").path
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    let timestamp = dateFormatter.string(from: Date())
    
    let logContent = text.map { "\($0)" }.joined(separator: " ")
    let logEntry = "\(timestamp): \(logContent)\n"
    NSLog(logContent)
    print(logContent)
    
    if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
        fileHandle.seekToEndOfFile()
        if let logData = logEntry.data(using: .utf8) {
            fileHandle.write(logData)
        }
        fileHandle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
            fileHandle.seekToEndOfFile()
            if let logData = logEntry.data(using: .utf8) {
                fileHandle.write(logData)
            }
            fileHandle.closeFile()
        }
    }
}
