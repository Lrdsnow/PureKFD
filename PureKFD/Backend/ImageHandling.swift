//
//  ImageHandling.swift
//  purekfd
//
//  Created by Lrdsnow on 6/27/24.
//

import CoreImage
import UIKit
import SwiftUI

func averageColor(from image: UIImage) -> UIColor? {
    guard let ciImage = CIImage(image: image) else { return nil }
    
    let extentVector = CIVector(x: ciImage.extent.origin.x, y: ciImage.extent.origin.y,
                                z: ciImage.extent.size.width, w: ciImage.extent.size.height)
    
    let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage,
                                                             kCIInputExtentKey: extentVector])!
    
    guard let outputImage = filter.outputImage else { return nil }
    
    var bitmap = [UInt8](repeating: 0, count: 4)
    let context = CIContext(options: nil)
    
    context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: CIFormat.RGBA8, colorSpace: nil)
    
    return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                   green: CGFloat(bitmap[1]) / 255.0,
                   blue: CGFloat(bitmap[2]) / 255.0,
                   alpha: CGFloat(bitmap[3]) / 255.0)
}

var appIconImage: Image {
    if let alternateIconName = UIApplication.shared.alternateIconName,
       let alternateIconImage = UIImage(named: alternateIconName) {
        return Image(uiImage: alternateIconImage)
    } else if let primaryIconImage = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIconFiles = (primaryIconImage["CFBundlePrimaryIcon"] as? [String: Any])?["CFBundleIconFiles"] as? [String],
              let primaryIconName = primaryIconFiles.last,
              let primaryIconImage = UIImage(named: primaryIconName) {
        return Image(uiImage: primaryIconImage)
    }
    return Image(systemName: "photo")
}
