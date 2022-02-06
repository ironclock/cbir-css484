//
//  CheckBoxView.swift
//  Slater Jon CBIR
//
//  Created by Jon Caceres on 1/23/22.
//

import SwiftUI

struct CheckBoxView: View {
    @State var checked: Bool
    var checkBoxId: Int

    var body: some View {
        Image(systemName: checked ? "checkmark.square.fill" : "square")
            .resizable()
            .foregroundColor(checked ? Color(UIColor.white) : Color.secondary)
            .frame(width: 50, height: 50, alignment: .center)
            .contentShape(Rectangle())
            .padding(30)
//            .background(Color.black)
            .border(Color.white, width: 0.1)
            .opacity(0.5)
            .cornerRadius(5)
            .onTapGesture {
                self.checked.toggle()
            }
    }
    
    func toggleCheckBox() {
        self.checked.toggle()
    }
}



//struct CheckBoxView_Previews: PreviewProvider {
//    struct CheckBoxViewHolder: View {
//        @State var checked = false
//
//        var body: some View {
//            CheckBoxView(checked: $checked, checkBoxId: $checkBoxId)
//        }
//    }
//
//    static var previews: some View {
//        CheckBoxViewHolder()
//    }
//}
