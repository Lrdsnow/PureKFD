//
//  Extensions.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/9/23.
//

import Foundation
import UIKit
import SwiftUI
import CoreGraphics
import CoreImage

struct CustomNavigationLink<D: View, L: View>: View {
  @ViewBuilder var destination: () -> D
  @ViewBuilder var label: () -> L
  
  @State private var isActive = false
  
  var body: some View {
      if #available(iOS 15.0, *) {
          Button {
              withAnimation {
                  isActive = true
              }
          } label: {
              label()
          }
          .borderedprombuttonc()
          .tintC(.accentColor.opacity(0.2))
          .onAppear {
              isActive = false
          }
          .overlay {
              NavigationLink(isActive: $isActive) {
                  destination()
              } label: {
                  EmptyView()
              }
              .opacity(0)
          }
      } else {
          NavigationLink(destination: destination()) {
              label()
          }
      }
  }
}

struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: effect)
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

func pkfdUpdated() -> Bool {
    
    let documentsURL = URL.documents.appendingPathComponent("config/build.txt")
    
    guard let bundleURL = Bundle.main.url(forResource: "build", withExtension: "txt") else {
        return false
    }
    
    var bundleContents = ""
    var documentsContents = ""
    
    do {
        bundleContents = try String(contentsOf: bundleURL)
    } catch {
        log("broken bundle?")
    }
    
    do {
        documentsContents = try String(contentsOf: documentsURL)
    } catch {}
    
    do {
        if bundleContents == documentsContents {
            return false
        } else {
            try bundleContents.write(to: documentsURL, atomically: true, encoding: .utf8)
            return true
        }
    } catch {
        print("Error: \(error)")
        return false
    }
}

func loadWallpapers(_ appData: AppData?) -> UIImage? {
    let frameworkPath: String = {
#if TARGET_OS_SIMULATOR
        "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks"
#else
        "/System/Library/PrivateFrameworks"
#endif
    }()
    
    if let appData = appData {
        if appData.bg != nil {
            return appData.bg
        }
    }
    
    func exists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    let lightData: NSData?
    let darkData: NSData?
    var dataList: [NSData] = []
    var cachePath = ""
    
    let contents = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/var/containers/Data/System/"), includingPropertiesForKeys: nil)
    if let contents = contents {
        for x0 in contents {
            let contents2 = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: x0.appendingPathComponent("Library/Caches/com.apple.PaperBoardUI").path), includingPropertiesForKeys: nil)
            cachePath = x0.appendingPathComponent("Library/Caches/com.apple.PaperBoardUI").path
            if let contents2 = contents2 {
                for x1 in contents2 {
                    let contents4 = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: x1.appendingPathComponent("MappedImageCache/Variant-home").path), includingPropertiesForKeys: nil)
                    if let contents4 = contents4 {
                        for x3 in contents4 {
                            let data = try? NSData(contentsOfFile: x3.path)
                            if let data = data {
                                dataList += [data]
                            }
                        }
                    }
                }
            }
        }
    }
    
    // load CPBitmapCreateImagesFromData
    let appSupport = dlopen(frameworkPath + "/AppSupport.framework/AppSupport", RTLD_LAZY)
    defer {
        dlclose(appSupport)
    }
    guard
        let pointer = dlsym(appSupport, "CPBitmapCreateImagesFromData"),
        let CPBitmapCreateImagesFromData = unsafeBitCast(
            pointer,
            to: (@convention(c) (_: NSData, _: UnsafeMutableRawPointer?, _: Int, _: UnsafeMutableRawPointer?) -> Unmanaged<CFArray>)?.self
        )
    else {
        return nil
    }
    
    // convert cpbitmap data to UIImage
    func bitmapDataToImage(data: NSData) -> UIImage? {
        let imageArray: [AnyObject]? = CPBitmapCreateImagesFromData(data, nil, 1, nil).takeRetainedValue() as [AnyObject]
        guard
            let imageArray = imageArray,
            imageArray.count > 0
        else {
            return nil
        }
        return UIImage(cgImage: imageArray[0] as! CGImage)
    }
    
    if let image = bitmapDataToImage(data: dataList.first ?? NSData()) {
        try? FileManager.default.removeItem(atPath: cachePath)
        try? FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: true)
        if let appData = appData {
            appData.bg = image
        }
        return image
    }
    
    if exists("/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap") {
        lightData = NSData(contentsOfFile: "/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap")
        if exists("/var/mobile/Library/SpringBoard/HomeBackgrounddark.cpbitmap") {
            darkData = NSData(contentsOfFile: "/var/mobile/Library/SpringBoard/HomeBackgrounddark.cpbitmap")
        } else {
            darkData = lightData
        }
    } else if exists("/var/mobile/Library/SpringBoard/LockBackground.cpbitmap") {
        lightData = NSData(contentsOfFile: "/var/mobile/Library/SpringBoard/LockBackground.cpbitmap")
        if exists("/var/mobile/Library/SpringBoard/LockBackgrounddark.cpbitmap") {
            darkData = NSData(contentsOfFile: "/var/mobile/Library/SpringBoard/LockBackgrounddark.cpbitmap")
        } else {
            darkData = lightData
        }
    } else {
        lightData = nil
        darkData = nil
    }
    
    if let image = bitmapDataToImage(data: darkData ?? NSData()) {
        if let appData = appData {
            appData.bg = image
        }
        return image
    }
    
    if let image = bitmapDataToImage(data: lightData ?? NSData()) {
        if let appData = appData {
            appData.bg = image
        }
        return image
    }
    
    return nil
}

func log(_ text: Any...) {
    let logFilePath = URL.documents.appendingPathComponent("config/purekfd_logs.txt").path
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    let timestamp = dateFormatter.string(from: Date())
    
    let logContent = text.map { "\($0)" }.joined(separator: " ")
    let logEntry = "\(timestamp): \(logContent)\n"
    NSLog(logContent)
    
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

extension URL {
    func isCustomUrlScheme() -> Bool {
        let webUrlPrefixes = ["http://", "https://", "about:"]
        
        let urlStringLowerCase = self.absoluteString.lowercased()
        for webUrlPrefix in webUrlPrefixes {
            if urlStringLowerCase.hasPrefix(webUrlPrefix) {
                return false
            }
        }
        return urlStringLowerCase.contains(":")
    }
}

// Images
let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit, compressionQuality quality: CGFloat = 0.4, completion: @escaping (UIImage?) -> Void) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data),
                let compressedData = image.jpegData(compressionQuality: quality),
                let compressedImage = UIImage(data: compressedData)
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.image = compressedImage
                completion(compressedImage)
            }
        }.resume()
    }
    
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit, compressionQuality quality: CGFloat = 0.4, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: link) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        if let pathExtension = URL(string: url.pathExtension.lowercased())?.absoluteString, pathExtension == "gif" {
            contentMode = mode
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data, error == nil,
                    let animatedImage = UIImage(data: data)
                else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    self?.image = animatedImage
                    completion(animatedImage)
                }
            }.resume()
        } else {
            downloaded(from: url, contentMode: mode, compressionQuality: quality, completion: completion)
        }
    }
}
