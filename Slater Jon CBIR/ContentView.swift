//
//  ContentView.swift
//  Slater Jon CBIR
//
//  Created by Jon Caceres and Derek Slater on 1/7/22.
//

import SwiftUI
import UIKit
import SwiftImage

extension Color {
    static let uwPurple = Color(red: 74 / 255, green: 46 / 255, blue: 131 / 255)
}

struct ContentView: View {
    var methods = ["Intensity Method", "Color-Code Method"]
    @State var selectedMethod: String = "Intensity Method"
    @State var showImagePicker: Bool = false
    @State var isModal: Bool = false
    
    var body: some View {
        VStack {
            VStack {
                Text("CBIR")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("by Derek Slater & Jon Caceres")
                Text("CSS 484 - Winter 2022 UWB")
                Spacer()
            }
            .frame(minWidth: 0, maxHeight: 200, alignment: .topLeading)
            VStack {
                Button("Choose Image") {
                    self.isModal = true
                }
                .padding()
                .background(Color.uwPurple)
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(5)
                .sheet(isPresented: $isModal, content: {
                    ImageCatalogView(selectedMethod: $selectedMethod)
                })
            }
            VStack {
                Picker(selection: $selectedMethod, label: Text("Select Method")) {
                    ForEach(methods, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .frame(width: 300)
            .padding()
        }
    }
}
