//
//  PixelAccess.swift
//  Slater Jon CBIR
//
//  Created by Jon Caceres on 1/9/22.
//

import Foundation
import UIKit

extension UIImage {
    
    static func findColors(_ image: UIImage) -> [UIColor] {
        let pixelsWide = Int(image.size.width)
        let pixelsHigh = Int(image.size.height)

        guard let pixelData = image.cgImage?.dataProvider?.data else { return [] }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        var imageColors: [UIColor] = []
        for x in 0..<pixelsWide {
            for y in 0..<pixelsHigh {
                let point = CGPoint(x: x, y: y)
                let pixelInfo: Int = ((pixelsWide * Int(point.y)) + Int(point.x)) * 4
                let color = UIColor(red: CGFloat(data[pixelInfo]) / 255.0,
                                    green: CGFloat(data[pixelInfo + 1]) / 255.0,
                                    blue: CGFloat(data[pixelInfo + 2]) / 255.0,
                                    alpha: CGFloat(data[pixelInfo + 3]) / 255.0)
                imageColors.append(color)
            }
        }
        return imageColors
    }
}


class ColorHistogram {

    func test() {
        
        let poop = 5
    
        print(poop)
        
    }
}
