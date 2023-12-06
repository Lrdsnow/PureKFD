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
