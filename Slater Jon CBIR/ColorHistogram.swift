//
//  PixelAccess.swift
//  Slater Jon CBIR
//
//  Created by Jon Caceres and Derek Slater on 1/9/22.
//

import Foundation
import UIKit
import SwiftImage

// Object to store the RGB values of each individual pixel
struct PixelColor {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    
    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

// Extension that prefixes zeroes to binary values
extension String {
    func leftPad(with character: Character, length: UInt) -> String {
        let maxLength = Int(length) - count
        guard maxLength > 0 else {
            return self
        }
        return String(repeating: String(character), count: maxLength) + self
    }
}

// Helper extension for the extension above
extension UInt8 {
    var bin: String {
        String(self, radix: 2).leftPad(with: "0", length: 8)
    }
}

class ColorHistogram {
    
    // Using this function, we create an array of all the RGB values of each pixel
    // in an image, and return an array of PixelColor objects
    //
    // - Parameters:
    //      - image: Any image file
    // - Returns:
    //      - An array of PixelColor objects
    static func colorFromImage(_ image: Image<RGBA<UInt8>>) -> [PixelColor] {
        var colorArray: [PixelColor] = []
        
        for pixel in image {
            let pixelColor = PixelColor(red: pixel.red, green: pixel.green, blue: pixel.blue)
            colorArray.append(pixelColor)
        }
        return colorArray
    }
    
    // Using the formula provided, we calculate the intensity of a single pixel
    // in an image and add it to an array of CGFloats which is then returned
    //
    // (A CGFloat is a 64-Bit IEEE double-precision floating point type equivalent to a Double)
    //
    // - Parameters:
    //      - colorArray: An array of PixelColor objects
    // - Returns:
    //      - An array of CGFloats containing the intensity of an image
    static func getIntensity(_ colorArray: [PixelColor]) -> [CGFloat] {
        var intensityArray: [CGFloat] = []
        
        for color in colorArray {
            let i = (0.299 * Double(color.red)) + (0.587 * Double(color.green)) + (0.114 * Double(color.blue))
            intensityArray.append(i)
        }
        return intensityArray
    }
    
    // Using the formula provided, we calculate the color code of a single pixel
    // in an image and add it to an array of Ints which is then returned
    //
    // - Parameters:
    //      - colorArray: An array of PixelColor objects
    // - Returns:
    //      - An array of Ints containing the color codes of an image
    static func getColorCode(_ colorArray: [PixelColor]) -> [Int] {
        var colorCodeArray: [Int] = []
        
        for color in colorArray {
            let rBit = color.red.bin.prefix(2)
            let gBit = color.green.bin.prefix(2)
            let bBit = color.blue.bin.prefix(2)
            guard let sixBits = Int(rBit + gBit + bBit, radix: 2) else {
                print("could not get colors as binary")
                return []
            }
            colorCodeArray.append(sixBits)
        }
        return colorCodeArray
    }
    
    // An empty array is created with 25 values beginning with 0
    // Each intensity is stored in its respective bin according to its value and then returned
    //
    // - Parameters:
    //      - intensityArray: An array of CGFloats containing intensity values
    // - Returns:
    //      - An array of Ints containing the sizes of each bin
    static func putInsideIntensityBins(_ intensityArray: [CGFloat]) -> [Int] {
        var binArray: [Int] = []
        
        for _ in 0...24 {
            binArray.append(0)
        }
        
        for element in intensityArray {
            let index = Int(element / 10)
            if index == 25 {
                binArray[24] += 1
            }
            else {
                binArray[index] += 1
            }
        }
        return binArray
    }
    
    // An empty array is created with 64 values beginning with 0
    // Each color code is stored in its respective bin according to its value and then returned
    //
    // - Parameters:
    //      - colodeCodeArray: An array of Ints containing intensity values
    // - Returns:
    //      - An array of Ints containing the sizes of each bin
    static func putInsideColorCodeBins(_ colorCodeArray: [Int]) -> [Int] {
        var binArray: [Int] = []
        
        for _ in 0...63 {
            binArray.append(0)
        }
        
        for element in colorCodeArray {
            binArray[element] += 1
        }
        
        return binArray
    }
    
    // comment later
    static func readFromIntensityCSV(_ index: Int) -> [Int] {
        let bundle = Bundle.main
        let path = bundle.path(forResource: "intensityBins", ofType: "csv")!
        do {
            let content = try String(contentsOfFile: path)
            
            let rows = content.components(separatedBy: "\r\n")
            
            
            let parsedCSV = rows[index-1].components(separatedBy: ",")

            let binArray = parsedCSV.map { Int($0)!}
            return binArray
        }
            catch {
                return []
            }
        }
    
    // comment later
    static func readFromColorCodeCSV(_ index: Int) -> [Int] {
        let bundle = Bundle.main
        let path = bundle.path(forResource: "colorCodeBins", ofType: "csv")!
        do {
            let content = try String(contentsOfFile: path)
            
            let rows = content.components(separatedBy: "\r\n")
            
            
            let parsedCSV = rows[index-1].components(separatedBy: ",")

            let binArray = parsedCSV.map { Int($0)!}
            return binArray
        }
            catch {
                return []
            }
        }
    
    // The width and height of both images entered are calculated, and then
    // used in the formula provided to calculate the distance and returned as a Double
    //
    // - Parameters:
    //      - image: The user's selected image
    //      - imageTwo: The image being compared
    //      - binOne: The bin of the selected image
    //      - binTwo: The bin of the image being compared
    // - Returns:
    //      - The distance between two images as a Double
    static func getDistance(_ image: SwiftImage.Image<RGBA<UInt8>>, _ imageTwo: SwiftImage.Image<RGBA<UInt8>>, _ binOne: [Int], _ binTwo: [Int]) -> Double {
          
        let imageOneTotalSize = image.width * image.height
        let imageTwoTotalSize = image.width * image.height
        var distance: Double = 0
        
        for index in 0...binOne.count-1 {
            distance += abs((Double(binOne[index])/Double(imageOneTotalSize)) - (Double(binTwo[index])/Double(imageTwoTotalSize)))
        }
        
        return distance
    }
    
    static func doTheThingWithCombinedBin(_ image: SwiftImage.Image<RGBA<UInt8>>, _ combinedBin: inout [Double]) -> Void {
        
        let imageTotalSize = Double(image.width * image.height)
        
        for index in 0...combinedBin.count-1 {
            combinedBin[index] = combinedBin[index] / imageTotalSize
        }
    }
    
    static func getNormalizedDistance(_ image: SwiftImage.Image<RGBA<UInt8>>, _ imageTwo: SwiftImage.Image<RGBA<UInt8>>, _ imageOneFeatures: [Double], _ imageTwoFeatures: [Double], _ weights: [Double]) -> Double {
          
        var distance: Double = 0
        
        for index in 0...imageOneFeatures.count-1 {
            distance += (weights[index] * abs(imageOneFeatures[index] - imageTwoFeatures[index]))
        }
        return distance
    }
    
    static func standardDevOfRelevance(_ selectedImage: SwiftImage.Image<RGBA<UInt8>>, _ relevantImages: [Int], _ mergedFeatureMatrix: [[Double]]) -> [Double] {
        var tempFeatureMatrix: [[Double]] = []
        var sum: Double = 0.0
        var featureAverages = [Double]()
        var featureStDevs = [Double]()
        
        for image in relevantImages {
            tempFeatureMatrix.append(mergedFeatureMatrix[image])
        }
        
        for element in 0...88 {
            for image in 0...tempFeatureMatrix.count-1 {
                sum += Double(tempFeatureMatrix[image][element])
            }
            featureAverages.append(sum/100.0)
            sum = 0
        }
        
        for element in 0...88 {
            var featureColumn = [Double]()
            for image in 0...tempFeatureMatrix.count-1 {
                featureColumn.append(tempFeatureMatrix[image][element])
            }
            featureStDevs.append(featureColumn.std())
            featureColumn.removeAll()
        }
        
        return featureStDevs
    }
}
