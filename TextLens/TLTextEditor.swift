//
//  TLTextEditor.swift
//  TextLens
//
//  Created by Tricster on 2020/12/18.
//

import SwiftUI

struct TLTextEditor: View {
    @EnvironmentObject var data: DataModel
    //@EnvironmentObject var imageModel: ImageModel
    var image: NSImage
    //@Binding var image: NSImage
    //@Binding var data: [(CGRect, String, Bool)]
    var body: some View{
        ZStack{
            Image(nsImage: image)
            AnnotationLayer(screenWidth: image.size.width, screenHeight: image.size.height)
                .environmentObject(data)
                .onClickWithLocation(coordinateSpace: .local){position in
                    let clickPosition = position.normalize(width: image.size.width, height: image.size.height)
                    for index in data.RecognitionResults.indices{
                        if data.RecognitionResults[index].0.contains(clickPosition) {
                            print("click at \(clickPosition) in \(index)")
                            data.RecognitionResults[index].2.toggle()
                            data.text = data.RecognitionResults.reduce("", {acc, item in
                                if item.2{
                                    return "\(acc)\(item.1)\n"
                                }
                                else{
                                    return acc
                                }
                            })
                        }
                    }
                }
            /*
            TappableView{ (point, type) in
                if type == 1 {
                    let clickPosition = point.normalize(width: image.size.width, height: image.size.height)
                    for index in data.RecognitionResults.indices{
                        if data.RecognitionResults[index].0.contains(clickPosition) {
                            //print("click at \(clickPosition) in \(index)")
                            data.RecognitionResults[index].2.toggle()
                            data.text = data.RecognitionResults.reduce("", {acc, item in
                                if item.2{
                                    return "\(acc)\(item.1)\n"
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
            */
        }.frame(width: image.size.width, height: image.size.height, alignment: .center)
        
        
    }
}

extension CGPoint{
    func normalize(width: CGFloat, height: CGFloat) -> CGPoint{
        return CGPoint(x: self.x / width, y: self.y / height)
    }
}

public extension View {
  func onClickWithLocation(coordinateSpace: CoordinateSpace = .local, _ clickHandler: @escaping (CGPoint) -> Void) -> some View {
    modifier(TapLocationViewModifier(clickHandler: clickHandler, coordinateSpace: coordinateSpace))
  }
}

fileprivate struct TapLocationViewModifier: ViewModifier {
  let clickHandler: (CGPoint) -> Void
  let coordinateSpace: CoordinateSpace

  func body(content: Content) -> some View {
    content.overlay(
      TapLocationBackground(clickHandler: clickHandler, coordinateSpace: coordinateSpace)
    )
  }
}

fileprivate struct TapLocationBackground: NSViewRepresentable {
  var clickHandler: (CGPoint) -> Void
  let coordinateSpace: CoordinateSpace

  func makeNSView(context: NSViewRepresentableContext<TapLocationBackground>) -> NSView {
    let v = NSView(frame: .zero)
    let gesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
    v.addGestureRecognizer(gesture)
    return v
  }

  class Coordinator: NSObject {
    var tapHandler: (CGPoint) -> Void
    let coordinateSpace: CoordinateSpace

    init(handler: @escaping ((CGPoint) -> Void), coordinateSpace: CoordinateSpace) {
      self.tapHandler = handler
      self.coordinateSpace = coordinateSpace
    }

    @objc func tapped(gesture: NSClickGestureRecognizer) {
      let point = coordinateSpace == .local
        ? gesture.location(in: gesture.view)
        : gesture.location(in: nil)
      tapHandler(point)
    }
  }

  func makeCoordinator() -> TapLocationBackground.Coordinator {
    Coordinator(handler: clickHandler, coordinateSpace: coordinateSpace)
  }

  func updateNSView(_: NSView, context _: NSViewRepresentableContext<TapLocationBackground>) {
    /* nothing */
  }
}
