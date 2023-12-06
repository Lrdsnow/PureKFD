//
//  encript.swift
//  MDCExplorer
//
//  Created by mini on 2023/02/27.
//

import Foundation
import CommonCrypto

func encrypt(str: String, key: String) -> String? {
    guard let data = str.data(using: .utf8) else {
        return nil
    }
    guard let keyData = key.data(using: .utf8) else {
        return nil
    }
    
    let cryptDataLength = Int(data.count + kCCBlockSizeAES128)
    var cryptData = Data(count: cryptDataLength)
    
    let keyLength = size_t(kCCKeySizeAES256)
    let options = CCOptions(kCCOptionPKCS7Padding)
    
    var numBytesEncrypted: size_t = 0
    
    let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
        data.withUnsafeBytes { dataBytes in
            keyData.withUnsafeBytes { keyBytes in
                CCCrypt(CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES128),
                        options,
                        keyBytes,
                        keyLength,
                        nil,
                        dataBytes,
                        data.count,
                        cryptBytes,
                        cryptDataLength,
                        &numBytesEncrypted)
            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
        return cryptData.base64EncodedString()
    }
    return nil
}

func decrypt(str: String, key: String) -> String? {
    guard let data = Data(base64Encoded: str) else {
        return nil
    }
    guard let keyData = key.data(using: .utf8) else {
        return nil
    }
    
    let cryptDataLength = Int(data.count + kCCBlockSizeAES128)
    var cryptData = Data(count: cryptDataLength)
    
    let keyLength = size_t(kCCKeySizeAES256)
    let options = CCOptions(kCCOptionPKCS7Padding)
    
    var numBytesEncrypted: size_t = 0
    
    let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
        data.withUnsafeBytes { dataBytes in
            keyData.withUnsafeBytes { keyBytes in
                CCCrypt(CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES128),
                        options,
                        keyBytes,
                        keyLength,
                        nil,
                        dataBytes,
                        data.count,
                        cryptBytes,
                        cryptDataLength,
                        &numBytesEncrypted)
            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
        return String(data: cryptData, encoding: .utf8)
    }
    return nil
}

func complexEncryption(plainText: String) -> String {
    let key = "ObservableObject.reloadIgnoringLocalCacheData"
    let shift = 5
    
    // Shift characters in plainText forward by shift amount
    var shiftedText = ""
    for character in plainText {
        if let unicode = character.unicodeScalars.first?.value {
            let shiftedUnicode = unicode + UInt32(shift)
            let shiftedCharacter = String(UnicodeScalar(shiftedUnicode)!)
            shiftedText += shiftedCharacter
        }
    }
    
    // XOR shiftedText with key
    var cipherText = ""
    let keyLength = key.count
    for (index, character) in shiftedText.enumerated() {
        let keyIndex = key.index(key.startIndex, offsetBy: index % keyLength)
        let keyCharacter = key[keyIndex]
        let encryptedUnicode = character.unicodeScalars.first!.value ^ keyCharacter.unicodeScalars.first!.value
        let encryptedCharacter = String(UnicodeScalar(encryptedUnicode)!)
        cipherText += encryptedCharacter
    }
    
    return cipherText
}
