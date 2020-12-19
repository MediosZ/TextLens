//
//  TLTextEditor.swift
//  TextLens
//
//  Created by Tricster on 2020/12/18.
//

import SwiftUI

struct TLTextEditor: View {
    @EnvironmentObject var data: DataModel
    //@Binding var image: NSImage
    //@Binding var data: [(CGRect, String, Bool)]
    var body: some View{
        ZStack{
            Image(nsImage: data.image)
            AnnotationLayer().environmentObject(data)
            TappableView{ (point, type) in
                if type == 1 {
                    let clickPosition = point.normalize(width: data.image.size.width, height: data.image.size.height)
                    for index in data.RecognitionResults.indices{
                        if data.RecognitionResults[index].0.contains(clickPosition) {
                            print("click at \(clickPosition) in \(index)")
                            data.RecognitionResults[index].2.toggle()
                            data.text = data.RecognitionResults.reduce("", {acc, item in
                                if item.2{
                                    return "\(acc)\(item.1)"
                                }
                                else{
                                    return acc
                                }
                            })
                        }
                    }
                }
                else if(type == 2){
                    
                }
            }
        }.frame(width: data.image.size.width, height: data.image.size.height, alignment: .center)
        
    }
}

extension CGPoint{
    func normalize(width: CGFloat, height: CGFloat) -> CGPoint{
        return CGPoint(x: self.x / width, y: self.y / height)
    }
}

struct TappableView: NSViewRepresentable {

    var tappedCallback: ((CGPoint, Int) -> Void)

    func makeNSView(context: NSViewRepresentableContext<TappableView>) -> NSView {
        let v = NSView(frame: .zero)
        context.coordinator.configure(view: v)
        return v
    }

    class Coordinator: NSObject, NSGestureRecognizerDelegate {
        var tappedCallback: ((CGPoint, Int) -> Void)
        private var gesture: NSClickGestureRecognizer!
        private var gesture2: NSClickGestureRecognizer!

        init(tappedCallback: @escaping ((CGPoint, Int) -> Void)) {
            self.tappedCallback = tappedCallback
        }
        func configure(view: NSView) {
            gesture = NSClickGestureRecognizer(target: self, action: #selector(Coordinator.tapped))
            gesture.delegate = self
            gesture.numberOfClicksRequired = 1
            gesture2 = NSClickGestureRecognizer(target: self, action: #selector(Coordinator.doubleTapped))
            gesture2.delegate = self
            gesture2.numberOfClicksRequired = 2
            view.addGestureRecognizer(gesture)
            view.addGestureRecognizer(gesture2)
        }
        @objc func tapped(gesture:NSClickGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.tappedCallback(point, 1)
        }
        @objc func doubleTapped(gesture:NSClickGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.tappedCallback(point, 2)
        }

        func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: NSGestureRecognizer) -> Bool {
            return gestureRecognizer === gesture && otherGestureRecognizer === gesture2
        }
    }

    func makeCoordinator() -> TappableView.Coordinator {
        return Coordinator(tappedCallback:self.tappedCallback)
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<TappableView>) {
    }

}
