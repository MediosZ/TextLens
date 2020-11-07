//
//  ContentView.swift
//  TextLens
//
//  Created by Tricster on 2020/11/6.
//

import SwiftUI
import Vision

class OCRManager{
    var text: String
    
    private init() {
        text = ""
    }
    
    static let instance: OCRManager = OCRManager()
    
    func performOCR(image: NSImage){
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, options: [:])
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        do {
            try requestHandler.perform([textRecognitionRequest])
        } catch _ {}
    }

    func recognizeTextHandler(request: VNRequest, error: Error?) {
        /*
        if let results = request.results as? [VNRecognizedTextObservation]{
            var displayResults: [((CGPoint, CGPoint, CGPoint, CGPoint), String)] = []
            for observation in results {
                let candidate: VNRecognizedText = observation.topCandidates(1)[0]
                let candidateBounds = (observation.bottomLeft, observation.bottomRight, observation.topRight, observation.topLeft)
                displayResults.append((candidateBounds, candidate.string))
            }
        }
        */
        // Update transcript view.
        if let results = request.results as? [VNRecognizedTextObservation]{
            var transcript: String = ""
            for observation in results {
                transcript.append(observation.topCandidates(1)[0].string)
                transcript.append("\n")
            }
            self.text = transcript
            NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            NSPasteboard.general.setString(transcript, forType: .string)
        }
        
    }
}





struct ContentView: View {
    
    @State var text: String = "recognition"
    @State var image: NSImage = NSImage(named: "DragBackground") ?? NSImage()
    
    var body: some View {
        VStack{
            TestImageDragDrop(text: $text, image: $image)
                .frame(width: 100, height: 100, alignment: .center)
            Text(text)
            Button(action: {
                print("click")
                let pb = NSPasteboard.general
                if let imgData = pb.data(forType: .tiff){
                    self.image = NSImage(data: imgData) ?? NSImage()
                    /*
                    let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                    let destinationURL = desktopURL.appendingPathComponent("my-image.png")
                    if self.image.pngWrite(to: destinationURL, options: .withoutOverwriting) {
                        print("File saved")
                    }
                    */
                    let requestHandler = VNImageRequestHandler(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, options: [:])
                    let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
                    do {
                        try requestHandler.perform([textRecognitionRequest])
                    } catch _ {}
                }
                
            }, label: {
                Text("From Clipboard")
                
            })
        }.frame(width: 200, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        /*
        if let results = request.results as? [VNRecognizedTextObservation]{
            var displayResults: [((CGPoint, CGPoint, CGPoint, CGPoint), String)] = []
            for observation in results {
                let candidate: VNRecognizedText = observation.topCandidates(1)[0]
                let candidateBounds = (observation.bottomLeft, observation.bottomRight, observation.topRight, observation.topLeft)
                displayResults.append((candidateBounds, candidate.string))
            }
        }
        */
        // Update transcript view.
        if let results = request.results as? [VNRecognizedTextObservation]{
            var transcript: String = ""
            for observation in results {
                transcript.append(observation.topCandidates(1)[0].string)
                transcript.append("\n")
            }
            self.text = transcript
            NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            NSPasteboard.general.setString(transcript, forType: .string)
        }
        
    }
}

struct TestImageDragDrop: View {
    @Binding var text: String
    @Binding var image: NSImage
    @State private var dragOver = false
    
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                    if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                        let image = NSImage(contentsOf: url)
                        DispatchQueue.main.async {
                            self.image = image!
                        }
                        let requestHandler = VNImageRequestHandler(cgImage: image!.cgImage(forProposedRect: nil, context: nil, hints: nil)!, options: [:])
                        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
                        do {
                            try requestHandler.perform([textRecognitionRequest])
                        } catch _ {}
                        
                    }
                })
                
                return true
            }
            .border(dragOver ? Color.red : Color.clear)
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        /*
        if let results = request.results as? [VNRecognizedTextObservation]{
            var displayResults: [((CGPoint, CGPoint, CGPoint, CGPoint), String)] = []
            for observation in results {
                let candidate: VNRecognizedText = observation.topCandidates(1)[0]
                let candidateBounds = (observation.bottomLeft, observation.bottomRight, observation.topRight, observation.topLeft)
                displayResults.append((candidateBounds, candidate.string))
            }
        }
        */
        // Update transcript view.
        if let results = request.results as? [VNRecognizedTextObservation]{
            var transcript: String = ""
            for observation in results {
                transcript.append(observation.topCandidates(1)[0].string)
                transcript.append("\n")
            }
            self.text = transcript
            NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            NSPasteboard.general.setString(transcript, forType: .string)
        }
        
    }
    

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
