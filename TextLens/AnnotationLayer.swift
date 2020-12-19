//
//  AnnotationLayer.swift
//  TextLens
//
//  Created by Tricster on 2020/11/23.
//

import SwiftUI

struct AnnotationLayer: View {
    @EnvironmentObject var data: DataModel
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    var body: some View {
        Path{ path in
            data.RecognitionResults.forEach{ (rect, result, selected) in
                if(selected){
                    path.addRect(CGRect(x: rect.minX * screenWidth,
                                        y: (1 - rect.minY - rect.height) * screenHeight,
                                        width: rect.width * screenWidth,
                                        height: rect.height * screenHeight))
                }
            }
        }.fill(Color.red.opacity(0.3))
    }
}

