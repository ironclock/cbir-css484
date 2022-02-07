//
//  ProcessView.swift
//  Slater Jon CBIR
//
//  Created by Jon Caceres and Derek Slater on 1/15/22.
//

import SwiftUI
import SwiftImage

extension Array where Element: FloatingPoint {
    
    func sum() -> Element {
        return self.reduce(0, +)
    }
    
    func avg() -> Element {
        return self.sum() / Element(self.count)
    }
    
    func std() -> Element {
        let mean = self.avg()
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / (Element(self.count) - 1))
    }
    
}

struct ImageDetails: Hashable  {
    var imageName: String
    var intensityBinHistogram: [Int]?
    var colorCodeBinHistogram: [Int]?
    var combinedBinHistogram: [Double]?
    var distance: Double?
    var isChecked: Bool?
    
    init(
        imageName: String, intensityBinHistogram: [Int]?, colorCodeBinHistogram: [Int]?, combinedBinHistogram: [Double]?, distance: Double?, isChecked: Bool?) {
            self.imageName = imageName
            self.intensityBinHistogram = intensityBinHistogram
            self.colorCodeBinHistogram = colorCodeBinHistogram
            self.combinedBinHistogram = combinedBinHistogram
            self.distance = distance
            self.isChecked = isChecked
        }
}

extension View {
    @ViewBuilder func isHidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
}

struct ProcessFinishView: View {
    
    @Binding var image: String
    @Binding var selectedMethod: String
    @Binding var canceled: Bool
    @State var imageDetailsArray = [ImageDetails]()
    @State var isHidden = false
    @State var progress: Double = 0
    @State var progressText: String = ""
    @State private var relevantImages: [Int] = []
    @State var hideFirstImage: Bool = false
    
    var gridItemLayout = [GridItem(.adaptive(minimum: 100))]
    @State var weights = [Double](repeating: 0.01123596, count: 89)
    @State var mergedFeatureMatrix = [[Double]]()
    
    @State var listItems: [(image: String, checked: Bool)] = (1...100).map { (image: String($0), checked: false) }
    
    var body: some View {
        ZStack {
            ProgressView("\(progressText)", value: progress, total: 100)
                .accentColor(.white)
                .frame(width: 200)
                .isHidden(isHidden)
                .onAppear {
                    canceled = false
                    self.processImages()
                }
            VStack {
                VStack {
                    HStack {
                        Image("\(image)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width:200)
                        Text("Recalculate")
                            .foregroundColor(relevantImages.count > 0 ? Color.white : Color.gray)
                            .isHidden(selectedMethod != "Both")
                            .onTapGesture {
                                if relevantImages.count > 0 {
                                    if !relevantImages.contains(Int(image)!) {
                                        relevantImages.append(Int(image)!)
                                    }
                                    print($relevantImages)
                                    self.processImages(relevantImages: relevantImages)
                                    self.isHidden = false
                                }
                            }
                    }
                }
                .frame(height:100, alignment: .top)
                
                ScrollView {
                    LazyVGrid(columns: gridItemLayout, spacing: 5) {
                        if isHidden {
                            ForEach(1..<imageDetailsArray.count) { i in
                                Image("\(imageDetailsArray[i].imageName)")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(10)
                                    .overlay(
                                        ZStack {
                                            CheckBoxView(checked: listItems[i].checked, checkBoxId: Int(listItems[i].image)!)
                                                .simultaneousGesture(
                                                    TapGesture()
                                                        .onEnded { _ in
                                                            if let imageIndex = self.relevantImages.firstIndex(of: Int(imageDetailsArray[i].imageName)!) {
                                                                self.relevantImages.remove(at: imageIndex)
                                                                print("removed \(Int(imageDetailsArray[i].imageName)!)")
                                                                print("relevant images: \(self.relevantImages)")
                                                            } else {
                                                                self.relevantImages.append(Int(imageDetailsArray[i].imageName)!)
                                                                print("appended \(Int(imageDetailsArray[i].imageName)!) to relevant images")
                                                                print("relevant images: \(self.relevantImages)")
                                                            }
                                                            listItems[i].checked.toggle()
                                                        }
                                                )
                                                .isHidden(selectedMethod != "Both")
                                                .frame(alignment: .center)
                                            Text("\(imageDetailsArray[i].imageName).jpg")
                                                .font(.caption)
                                                .padding(6)
                                                .foregroundColor(.white)
                                                .background(Color.black)
                                                .opacity(0.8)
                                                .cornerRadius(10.0)
                                                .padding(.top, 70)
                                                .frame(alignment: .bottomTrailing)
                                                .id(imageDetailsArray[i])
                                        }
                                            .contentShape(Rectangle())
                                    )
                            }
                        }
                    }
                }
            }
            .isHidden(!isHidden)
        }
    }
    
    // This function processes all of the functions in the ColorHistogram class.
    //
    // It ensures that the image exists before continuing, then store's the image name
    // for later use when getting the index of the image array.
    //
    // DispatchQueue is a built-in object that manages the execution of tasks on background threads
    // to prevent hanging or interruption of the main thread (eg. the UI).
    //
    // Unlike the previous version of this app, there is no image processing because the bins for
    // each image have already been calculated and stored locally.
    //
    // The processing starts by creating a loop and checking to see which processing method was
    // selected by the user (intensity or color-code). It thens run the respective tasks to get the
    // bin values from a CSV file. Afterwards the distances are calculated.
    //
    // If a user selects "both" methods then the same logic as above is performed however both
    // "intensity" and "color-code" bins are concatenated for each image.
    //
    // Afterwards, a merged feature matrix is created as a 2x2 array and each bin is stored inside.
    // The averages and standard deviations are then calculated along with weights and weighted distances.
    //
    // The main thread then displays the images according to distance on the UI.
    //
    // - Parameters:
    //      - relevantImages: An array containing relevant images that were checked by the user
    // - Returns:
    //      - None
    func processImages(relevantImages: [Int]? = nil) -> Void {
        let backgroundProcess = DispatchQueue(label: "cbir.concurrent.queue", attributes: .concurrent)
        guard let selectedImage = SwiftImage.Image<RGBA<UInt8>>(named: "\(image)") else {
            print("Image could not be found")
            return
        }
        let selectedImageIndex = Int("\(image)")!
        print("selected method is \(self.selectedMethod)")
        
        let imageCount = 100
        
        backgroundProcess.async {
            for index in 1...imageCount {
                if !canceled {
                    progressText = "Processing image \(index)..."
                    let image = SwiftImage.Image<RGBA<UInt8>>(named: "\(index)")!
                    
                    if self.selectedMethod == "Intensity" {
                        let intensityBinHistogram = ColorHistogram.readFromIntensityCSV(index)
                        
                        imageDetailsArray.append(
                            ImageDetails(
                                imageName: "\(index)",
                                intensityBinHistogram: intensityBinHistogram,
                                colorCodeBinHistogram: nil,
                                combinedBinHistogram: nil,
                                distance: nil,
                                isChecked: false)
                        )
                    } else if self.selectedMethod == "Color-Code" {
                        let colorCodeBinHistogram = ColorHistogram.readFromColorCodeCSV(index)
                        
                        imageDetailsArray.append(
                            ImageDetails(
                                imageName: "\(index)",
                                intensityBinHistogram: nil,
                                colorCodeBinHistogram: colorCodeBinHistogram,
                                combinedBinHistogram: nil,
                                distance: nil,
                                isChecked: false)
                        )
                    } else {
                        if relevantImages == nil {
                            let intensityBinHistogram = ColorHistogram.readFromIntensityCSV(index)
                            
                            let colorCodeBinHistogram = ColorHistogram.readFromColorCodeCSV(index)
                            
                            var combinedBinHistogram = intensityBinHistogram.map { Double($0) } + colorCodeBinHistogram.map { Double($0) }
                            
                            ColorHistogram.normalizeBinsToFeatures(image, &combinedBinHistogram)
                            
                            mergedFeatureMatrix.append(combinedBinHistogram)
                            
                            imageDetailsArray.append(
                                ImageDetails(
                                    imageName: "\(index)",
                                    intensityBinHistogram: nil,
                                    colorCodeBinHistogram: nil,
                                    combinedBinHistogram: nil,
                                    distance: nil,
                                    isChecked: listItems[index-1].checked)
                            )
                        }
                    }
                    progress += 0.5
                }
            }
            
            if self.selectedMethod == "Both" {
                var sum: Double = 0.0
                var featureAverages = [Double]()
                var featureStDevs = [Double]()
                
                if relevantImages == nil {
                    for element in 0...88 {
                        for image in 0...imageCount-1 {
                            sum += Double(mergedFeatureMatrix[image][element])
                        }
                        featureAverages.append(sum/Double(mergedFeatureMatrix.count))
                        sum = 0
                    }
                    
                    for element in 0...88 {
                        var featureColumn = [Double]()
                        for image in 0...imageCount-1 {
                            featureColumn.append(mergedFeatureMatrix[image][element])
                        }
                        featureStDevs.append(featureColumn.std())
                        featureColumn.removeAll()
                    }
                    
                    for element in 0...88 {
                        for image in 0...imageCount-1 {
                            var result = (mergedFeatureMatrix[image][element] - featureAverages[element]) / featureStDevs[element]
                            result = result.isNaN ? 0 : result
                            mergedFeatureMatrix[image][element] = result
                        }
                    }
                    
                    for index in 0...imageCount-1 {
                        imageDetailsArray[index].combinedBinHistogram = mergedFeatureMatrix[index]
                    }
                }
            }
            
            for index in 1...imageCount {
                if !canceled {
                    progressText = "Calculating distances..."
                    guard let nextImage = SwiftImage.Image<RGBA<UInt8>>(named: "\(index)") else {
                        print("next image could not be found")
                        return
                    }
                    
                    if self.selectedMethod == "Intensity" {
                        let distance = ColorHistogram.getDistance(
                            selectedImage,
                            nextImage,
                            imageDetailsArray[selectedImageIndex-1].intensityBinHistogram!,
                            imageDetailsArray[index-1].intensityBinHistogram!
                        )
                        imageDetailsArray[index-1].distance = distance
                    }
                    
                    else if self.selectedMethod == "Color-Code" {
                        let distance = ColorHistogram.getDistance(
                            selectedImage,
                            nextImage,
                            imageDetailsArray[selectedImageIndex-1].colorCodeBinHistogram!,
                            imageDetailsArray[index-1].colorCodeBinHistogram!
                        )
                        imageDetailsArray[index-1].distance = distance
                    }
                    
                    else {
                        if relevantImages == nil {
                            let weightedDistance = ColorHistogram.getNormalizedDistance(
                                imageDetailsArray[selectedImageIndex-1].combinedBinHistogram!,
                                imageDetailsArray[index-1].combinedBinHistogram!,
                                weights
                            )
                            
                            imageDetailsArray[index-1].distance = weightedDistance
                            
                        } else {
                            
                            imageDetailsArray[index-1].isChecked = listItems[index-1].checked
                            
                            var tempFeatureMatrix: [[Double]] = []
                            var sum: Double = 0.0
                            var featureAverages = [Double]()
                            var featureStDevs = [Double]()
                            
                            for image in 0...relevantImages!.count-1 {
                                tempFeatureMatrix.append(mergedFeatureMatrix[relevantImages![image]-1])
                            }
                            
                            for element in 0...88 {
                                for image in 0...tempFeatureMatrix.count-1 {
                                    sum += Double(tempFeatureMatrix[image][element])
                                }
                                featureAverages.append(sum/Double(tempFeatureMatrix.count))
                                sum = 0.0
                            }
                            
                            for element in 0...88 {
                                var featureColumn = [Double]()
                                for image in 0...tempFeatureMatrix.count-1 {
                                    featureColumn.append(tempFeatureMatrix[image][element])
                                }
                                var std = featureColumn.std()
                                if(std < 0.0000000000000001) {
                                    std = 0.0
                                }
                                featureStDevs.append(std)
                                featureColumn.removeAll()
                            }
                            
                            let minStDev = featureStDevs.filter{ $0 > 0 }.min()
                            
                            for index in 0...featureStDevs.count-1 {
                                if featureStDevs[index] == 0.0 && featureAverages[index] != 0.0 {
                                    featureStDevs[index] = (1/2) * minStDev!
                                }
                            }
                            
                            var weightSum = 0.0
                            
                            for index in 0...weights.count-1 {
                                if featureStDevs[index] != 0 {
                                    weights[index] = (1 / featureStDevs[index])
                                    weightSum += weights[index]
                                } else {
                                    weights[index] = 0
                                }
                            }
                            
                            for index in 0...weights.count-1 {
                                weights[index] = weights[index] / weightSum
                            }
                            
                            let weightedDistance = ColorHistogram.getNormalizedDistance(
                                imageDetailsArray[selectedImageIndex-1].combinedBinHistogram!,
                                imageDetailsArray[index-1].combinedBinHistogram!,
                                weights
                            )
                            
                            imageDetailsArray[index-1].distance = weightedDistance
                            
                        }
                    }
                    progress += 0.5
                }
            }
            
            DispatchQueue.main.async {
                if !canceled {
                    self.progress = 0.0
                    self.isHidden = true
                    imageDetailsArray = imageDetailsArray.sorted(by: {$0.distance! < $1.distance!})
                    
                    for index in 0...99 {
                        listItems[index].checked = imageDetailsArray[index].isChecked!
                    }
                    
                    removeSelectedImageFromRelevantImages(index: selectedImageIndex-1)
                }
            }
        }
    }
    
    // The selected image should only appear in relevant images
    // when the images are being processed. This ensures that.
    //
    // - Parameters:
    //      - index: The user's selected image index
    // - Returns:
    //      - None
    func removeSelectedImageFromRelevantImages(index: Int) -> Void {
        if let imageIndex = self.relevantImages.firstIndex(of: Int(imageDetailsArray[index].imageName)!) {
            self.relevantImages.remove(at: imageIndex)
        }
    }
}
