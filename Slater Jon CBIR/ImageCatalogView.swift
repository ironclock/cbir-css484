//
//  ImageCatalogVuew.swift
//  Slater Jon CBIR
//
//  Created by Jon Caceres and Derek Slater on 1/7/22.
//

import SwiftUI

struct ImageCatalogView: View {
    
    var gridItemLayout = [GridItem(.adaptive(minimum: 100))]
    
    @Binding var selectedMethod: String
    
    @State var isModalImageView: Bool = false
    @State var selectedImage: String = ""
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 5) {
                ForEach((1...100), id: \.self) { image in
                    Button(action: {
                        self.isModalImageView = true
                        self.selectedImage = "\(image)"
                    }, label: {
                        Image("\(image)")
                            .resizable()
                            .font(.system(size:30))
                            .frame(width: 100, height: 100)
                            .cornerRadius(10)
                            .overlay(
                                ZStack {
                                    Text("\(image).jpg")
                                        .font(.caption)
                                        .padding(6)
                                        .foregroundColor(.white)
                                }
                                .background(Color.black)
                                .opacity(0.8)
                                .cornerRadius(10.0)
                                    .padding(6), alignment: .bottom)
                    })
                    .sheet(isPresented: $isModalImageView, content: {
                        ImageConfirmView(image: $selectedImage, selectedMethod: $selectedMethod)
                    })
                }
            }
            .padding()
        }
    }
}
