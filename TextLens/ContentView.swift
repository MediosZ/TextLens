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


extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
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
                
                let pb = NSPasteboard.general
                if let filepath = pb.string(forType: .fileURL), let url = URL(string: filepath), let image = NSImage(contentsOf: url){
                    print("detect file url")
                    self.image = image
                    saveImageToDownload(image: image)
                    performOCR(image: image)
                }
                else if let data = pb.data(forType: .tiff), let image = NSImage(data: data){
                    print("detect image data")
                    self.image = image
                    saveImageToDownload(image: image)
                    performOCR(image: image)
                }
                
            }, label: {
                Text("From Clipboard")
                
            })
        }.frame(width: 200, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
    
    func performOCR(image: NSImage){
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, options: [:])
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        do {
            try requestHandler.perform([textRecognitionRequest])
        } catch _ {}
    }
    
    func saveImageToDownload(image: NSImage, name: String = "image"){
        let desktopURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let destinationURL = desktopURL.appendingPathComponent(name)
        if image.pngWrite(to: destinationURL) {
            print("File \(image) saved ro \(destinationURL)")
        }
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
