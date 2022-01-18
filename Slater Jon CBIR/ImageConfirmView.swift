//
//  ImageConfirmView.swift
//  Slater Jon CBIR
//
//  Created by Jon Caceres and Derek Slater on 1/11/22.
//

import SwiftUI

struct ImageConfirmView: View {
    
    @Binding var image: String
    @Binding var selectedMethod: String
    @State var isProcessImageView: Bool = false
    @State var selectedImage: String = ""
    @State var canceled: Bool = false
    
    var body: some View {
        VStack {
            Image("\(image)")
                .cornerRadius(10)
            Button(action: {
                self.isProcessImageView = true
                self.selectedImage = "\(image)"
            }, label: {
                Text("Use This Image")
                    .padding()
                    .background(Color.uwPurple)
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(5)
            })
                .sheet(isPresented: $isProcessImageView, onDismiss: {
                    canceled = true
                },
                content: {
                ProcessFinishView(image: $image, selectedMethod: $selectedMethod, canceled: $canceled)
            })
        }
    }
}
