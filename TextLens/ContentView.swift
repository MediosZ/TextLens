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
    @ObservedObject var dataModel: DataModel
    
    var body: some View {
        VStack{
            TestImageDragDrop(text: $dataModel.text, image: $dataModel.image, hasImage: $dataModel.hasImage)
                .frame(width: 150, height: 150, alignment: .center)
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            
            Button(action: {
                
                let pb = NSPasteboard.general
                if let filepath = pb.string(forType: .fileURL), let url = URL(string: filepath), let image = NSImage(contentsOf: url){
                    print("detect file url")
                    DispatchQueue.main.async {
                        dataModel.image = image
                        dataModel.hasImage = true
                    }
                    //saveImageToDownload(image: image)
                    performOCR(image: image)
                }
                else if let data = pb.data(forType: .tiff), let image = NSImage(data: data){
                    print("detect image data")
                    DispatchQueue.main.async {
                        dataModel.image = image
                        dataModel.hasImage = true
                    }
                    //saveImageToDownload(image: image)
                    performOCR(image: image)
                }
                
            }, label: {
                Text("From PasteBoard")
                
            })
            if #available(OSX 11.0, *) {
                TextEditor(text: $dataModel.text).padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            } else {
                TextField("Recognition Result:", text: $dataModel.text).padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
            
        }.frame(width: 300, height: 400, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
    
    func performOCR(image: NSImage){
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, options: [:])
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        textRecognitionRequest.recognitionLanguages = ["en_US"]
        textRecognitionRequest.usesLanguageCorrection = true
        do {
            try requestHandler.perform([textRecognitionRequest])
        } catch _ {}
    }
    
    func saveImageToDownload(image: NSImage, name: String = "image.png"){
        let desktopURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let destinationURL = desktopURL.appendingPathComponent(name)
        if image.pngWrite(to: destinationURL) {
            print("File \(image) saved ro \(destinationURL)")
        }
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        if let results = request.results as? [VNRecognizedTextObservation]{
            var transcript: String = ""
            for observation in results {
                transcript.append(observation.topCandidates(1)[0].string)
                transcript.append("\n")
            }
            DispatchQueue.main.async {
                self.dataModel.text = transcript
            }
            
            if UserDefaults.standard.bool(forKey: "copyToPasteBoard") {
                NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                NSPasteboard.general.setString(transcript, forType: .string)
            }
        }
    }
}

struct TestImageDragDrop: View {
    @Binding var text: String
    @Binding var image: NSImage
    @Binding var hasImage: Bool
    @State private var dragOver = false
    
    @State private var imagePreviewWindow: NSWindow?
    
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                    if let data = data,
                       let path = NSString(data: data, encoding: 4),
                       let url = URL(string: path as String) {
                        if let image = NSImage(contentsOf: url){
                            DispatchQueue.main.async {
                                self.image = image
                                self.hasImage = true
                            }
                            performOCR(image: image)
                        }
                    }
                })
                
                return true
            }
            .onTapGesture{
                if hasImage{
                    openImagePreview()
                }
                
            }
            .colorMultiply(dragOver ? .white : .gray)
            
    }
    
    func performOCR(image: NSImage){
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, options: [:])
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        print(textRecognitionRequest.recognitionLanguages)
        textRecognitionRequest.recognitionLanguages = ["en_US"]
        textRecognitionRequest.usesLanguageCorrection = true
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
            DispatchQueue.main.async {
                self.text = transcript
            }
            if UserDefaults.standard.bool(forKey: "copyToPasteBoard") {
                NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                NSPasteboard.general.setString(transcript, forType: .string)
            }
        }
        
    }
    
    func openImagePreview(){
        let imagePreview = ImagePreviw(image: $image)
        if let window = imagePreviewWindow{
            window.contentView = NSHostingView(rootView: imagePreview)
            window.makeKeyAndOrderFront(nil)
        }
        else{
            imagePreviewWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
            imagePreviewWindow!.center()
            imagePreviewWindow!.setFrameAutosaveName("Image Preview")
            imagePreviewWindow!.isReleasedWhenClosed = false
            imagePreviewWindow!.contentView = NSHostingView(rootView: imagePreview)
            imagePreviewWindow!.makeKeyAndOrderFront(nil)
        }
    }
}

struct ImagePreviw: View{
    @Binding var image: NSImage
    var body: some View{
        Image(nsImage: image)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(dataModel: DataModel())
        }
    }
}
#endif
