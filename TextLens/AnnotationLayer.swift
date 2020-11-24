//
//  AnnotationLayer.swift
//  TextLens
//
//  Created by Tricster on 2020/11/23.
//

import SwiftUI

struct AnnotationLayer: View {
    @Binding var data: [(CGRect, String)]
    var body: some View {

        Path{ path in
            data.forEach{ (rect, result) in
                path.addRect(rect)
            }
        }.fill(Color.red.opacity(0.3))
    }
}

struct AnnotationLayer_Previews: PreviewProvider {
    @State static var data: [(CGRect, String)] = [
        (CGRect(x: 10, y: 10, width: 200, height: 100), "hello"),
        (CGRect(x: 10, y: 200, width: 300, height: 100), "hello"),
    ]
    static var previews: some View {
        AnnotationLayer(data: $data)
    }
}
