//
//  AnnotationLayer.swift
//  TextLens
//
//  Created by Tricster on 2020/11/23.
//

import SwiftUI

struct AnnotationLayer: View {
    @EnvironmentObject var data: DataModel
    //@Binding var screenWidth: CGFloat
    //@Binding var screenHeight: CGFloat
    var body: some View {
        Path{ path in
            data.RecognitionResults.forEach{ (rect, result, selected) in
                if(selected){
                    path.addRect(CGRect(x: rect.minX * data.image.size.width,
                                        y: (1 - rect.minY - rect.height) * data.image.size.height,
                                        width: rect.width * data.image.size.width,
                                        height: rect.height * data.image.size.height))
                }
            }
        }.fill(Color.red.opacity(0.3))
    }
}

