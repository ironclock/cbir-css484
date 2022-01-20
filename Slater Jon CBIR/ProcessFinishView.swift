//
//  ProcessView.swift
//  Slater Jon CBIR
//
//  Created by Jon Caceres and Derek Slater on 1/15/22.
//

import SwiftUI
import SwiftImage

struct ImageDetails: Hashable  {
    var imageName: String
    var intensityBinHistogram: [Int]?
    var colorCodeBinHistogram: [Int]?
    var distance: Double?
    
    init(
        imageName: String, intensityBinHistogram: [Int]?,
        colorCodeBinHistogram: [Int]?, distance: Double?) {
            self.imageName = imageName
            self.intensityBinHistogram = intensityBinHistogram
            self.colorCodeBinHistogram = colorCodeBinHistogram
            self.distance = distance
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
    
    var gridItemLayout = [GridItem(.adaptive(minimum: 100))]
    
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
                    Image("\(image)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:200)
                    Spacer()
                }
                .frame(height:100, alignment: .top)
                
                ScrollView {
                    LazyVGrid(columns: gridItemLayout, spacing: 5) {
                        ForEach(imageDetailsArray, id: \.self) { image in
                            Image("\(image.imageName)")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                .overlay(
                                    ZStack {
                                        Text("\(image.imageName).jpg")
                                            .font(.caption)
                                            .padding(6)
                                            .foregroundColor(.white)
                                    }
                                    .background(Color.black)
                                    .opacity(0.8)
                                    .cornerRadius(10.0)
                                    .padding(6), alignment: .bottomTrailing)
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
    // Because the image processing is resource intensive, it's completed in the background thread
    // and the main thread displays the progress as the tasks are processing.
    //
    // The processing starts by creating a loop and checking to see which processing method was
    // selected by the user (intensity or color-code). It thens run the respective tasks to process
    // the colors of a pixel in each image and stores them in their respective bins. Afterwards
    // the distances are calculated.
    //
    // The main thread then displays the images according to distance on the UI.
    //
    // - Parameters:
    //      - None
    // - Returns:
    //      - None
    func processImages() -> Void {
        let backgroundProcess = DispatchQueue(label: "cbir.concurrent.queue", attributes: .concurrent)
        guard let selectedImage = SwiftImage.Image<RGBA<UInt8>>(named: "\(image)") else {
            print("Image could not be found")
            return
        }
        let selectedImageIndex = Int("\(image)")!
        
        backgroundProcess.async {
            for index in 1...100 {
                if !canceled {
                    progressText = "Processing image \(index)..."
                    let image = SwiftImage.Image<RGBA<UInt8>>(named: "\(index)")!
                    let colorsFromImage = ColorHistogram.colorFromImage(image)
                    
                    if(self.selectedMethod == "Intensity Method") {
                        let intensityArray = ColorHistogram.getIntensity(colorsFromImage)
                        let intensityBinHistogram = ColorHistogram.putInsideIntensityBins(intensityArray)
                        
                        imageDetailsArray.append(
                            ImageDetails(
                                imageName: "\(index)",
                                intensityBinHistogram: intensityBinHistogram,
                                colorCodeBinHistogram: nil,
                                distance: nil)
                        )
                    } else {
                        let colorCodeArray = ColorHistogram.getColorCode(colorsFromImage)
                        let colorCodeBinHistogram = ColorHistogram.putInsideColorCodeBins(colorCodeArray)
                        
                        imageDetailsArray.append(
                            ImageDetails(
                                imageName: "\(index)",
                                intensityBinHistogram: nil,
                                colorCodeBinHistogram: colorCodeBinHistogram,
                                distance: nil)
                        )
                    }
                    progress += 0.5
                }
            }
            
            for index in 1...100 {
                if !canceled {
                    progressText = "Calculating distances..."
                    guard let nextImage = SwiftImage.Image<RGBA<UInt8>>(named: "\(index)") else {
                        print("next image could not be found")
                        return
                    }
                    
                    if(self.selectedMethod == "Intensity Method") {
                        let distance = ColorHistogram.getDistance(
                            selectedImage,
                            nextImage,
                            imageDetailsArray[selectedImageIndex-1].intensityBinHistogram!,
                            imageDetailsArray[index-1].intensityBinHistogram!
                        )
                        imageDetailsArray[index-1].distance = distance
                    }
                    else {
                        let distance = ColorHistogram.getDistance(
                            selectedImage,
                            nextImage,
                            imageDetailsArray[selectedImageIndex-1].colorCodeBinHistogram!,
                            imageDetailsArray[index-1].colorCodeBinHistogram!
                        )
                        imageDetailsArray[index-1].distance = distance
                    }
                    progress += 0.5
                }
            }
            
            DispatchQueue.main.async {
                if !canceled {
                    self.isHidden.toggle()
                    imageDetailsArray = imageDetailsArray.sorted(by: {$0.distance! < $1.distance!})
                    imageDetailsArray.removeFirst()
                }
            }
        }
    }
}
