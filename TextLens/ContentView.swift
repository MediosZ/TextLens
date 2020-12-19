//
//  ContentView.swift
//  TextLens
//
//  Created by Tricster on 2020/11/6.
//

import SwiftUI
import Vision
import Preferences


struct ContentView: View {
    @ObservedObject var dataModel: DataModel
    @ObservedObject var imageModel: ImageModel
    @ObservedObject var userPreference: UserPreference
    
    @State var imageWidth: CGFloat = 0.0
    @State var imageHeight: CGFloat = 0.0
    
    lazy var preferencesWindowController: PreferencesWindowController = PreferencesWindowController(
        preferencePanes: [GeneralPreferenceViewController(userPreference)],
        style: .segmentedControl,
        animated: true,
        hidesToolbarForSingleItem: true
    )
    
    var body: some View {
        
        VStack{
            HStack{
                Spacer()
                Menu {
                    Button("Preferences", action: openPreferencePanel)
                    Button("Quit", action: quit)
                } label: {
                    Image(systemName: "gearshape")
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(minWidth: 0, maxWidth: 30, minHeight: 0, maxHeight: 30, alignment: .trailing)
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
            }

            
            TestImageDragDrop(imageModel: imageModel)
                .frame(width: 150, height: 150, alignment: .center)
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20))
                .environmentObject(dataModel)
                //.environmentObject(imageModel)
            
            Button(action: {
                
                let pb = NSPasteboard.general
                if let filepath = pb.string(forType: .fileURL), let url = URL(string: filepath), let image = NSImage(contentsOf: url){
                    print("detect file url")
                    print(image.size.width, image.size.height)
                    self.imageWidth = image.size.width
                    self.imageHeight = image.size.height
                    DispatchQueue.main.async {
                        self.imageModel.image = image
                        self.dataModel.hasImage = true
                        self.dataModel.width = image.size.width
                        self.dataModel.height = image.size.height

                    }
                    //saveImageToDownload(image: image)
                    performOCR(image: image)
                }
                else if let data = pb.data(forType: .tiff), let image = NSImage(data: data){
                    print("detect image data")
                    print(image.size.width, image.size.height)
                    self.imageWidth = image.size.width
                    self.imageHeight = image.size.height
                    DispatchQueue.main.async {
                        self.imageModel.image = image
                        self.dataModel.hasImage = true
                        self.dataModel.width = image.size.width
                        self.dataModel.height = image.size.height
                    }
                    //saveImageToDownload(image: image)
                    performOCR(image: image)
                }
                
            }, label: {
                Text("From PasteBoard")
                
            })
            Divider()
            if #available(OSX 11.0, *) {
                TextEditor(text: $dataModel.text)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    
            } else {
                TextField("Recognition Result:", text: $dataModel.text).padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
            
        }.frame(width: 300, height: 400, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
    
    func performOCR(image: NSImage){
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, options: [:])
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        textRecognitionRequest.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR"]
        do {
            try requestHandler.perform([textRecognitionRequest])
        } catch _ {}
    }
    
    func convert(rect: CGRect) -> CGRect{
        
        let width = self.imageWidth
        let height = self.imageHeight
        //print(width, height)
        return CGRect(x: rect.minX * width, y: (1 - rect.minY - rect.height) * height, width: rect.width * width, height: rect.height * height)
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        if let results = request.results as? [VNRecognizedTextObservation]{
            var displayResults: [(CGRect, String, Bool)] = []
            for observation in results {
                //print(observation.boundingBox)
                let candidate: VNRecognizedText = observation.topCandidates(1)[0]
                displayResults.append((observation.boundingBox, candidate.string, true))
            }
            
            dataModel.RecognitionResults = displayResults
        }
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

    func openPreferencePanel() {
        print("Open Preference")
        var mutatableSelf = self
        mutatableSelf.preferencesWindowController.show()
        //getPreferencePanel().show()
    }

    func quit() {
        print("Application Terminate")
        NSApplication.shared.terminate(self)
    }
}

struct TestImageDragDrop: View {
    @EnvironmentObject var data: DataModel
    var imageModel: ImageModel
    //@Binding var text: String
    //@Binding var image: NSImage
    @State var width: CGFloat = 0.0
    @State var height: CGFloat = 0.0
    //@Binding var hasImage: Bool
    //@Binding var recogResults: [(CGRect, String, Bool)]
    @State private var dragOver = false
    
    @State private var imagePreviewWindow: NSWindow?
    
    var body: some View {
        Image(nsImage: imageModel.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                    if let data = data,
                       let path = NSString(data: data, encoding: 4),
                       let url = URL(string: path as String) {
                        if let image = NSImage(contentsOf: url){
                            self.width = image.size.width
                            self.height = image.size.height
                            DispatchQueue.main.async {
                                self.imageModel.image = image
                                self.data.hasImage = true
                            }
                            performOCR(image: image)
                        }
                    }
                })
                
                return true
            }
            .onTapGesture{
                print("tep")
                if data.hasImage{
                    openImagePreview()
                }
                
            }
            .colorMultiply(dragOver ? .white : .gray)
            
    }
    
    func performOCR(image: NSImage){
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, options: [:])
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        textRecognitionRequest.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR"]
        do {
            try requestHandler.perform([textRecognitionRequest])
        } catch _ {}
    }
    func convert(rect: CGRect) -> CGRect{
        let width = self.width
        let height = self.height
        //print(width, height)
        return CGRect(x: rect.minX * width, y: (1 - rect.minY - rect.height) * height, width: rect.width * width, height: rect.height * height)
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        
        if let results = request.results as? [VNRecognizedTextObservation]{
            var displayResults: [(CGRect, String, Bool)] = []
            for observation in results {
                let candidate: VNRecognizedText = observation.topCandidates(1)[0]
                displayResults.append((observation.boundingBox, candidate.string, true))
            }
            DispatchQueue.main.async {
                data.RecognitionResults = displayResults
            }
            
        }
        
        // Update transcript view.
        if let results = request.results as? [VNRecognizedTextObservation]{
            var transcript: String = ""
            for observation in results {
                transcript.append(observation.topCandidates(1)[0].string)
                transcript.append("\n")
            }
            DispatchQueue.main.async {
                self.data.text = transcript
            }
            if UserDefaults.standard.bool(forKey: "copyToPasteBoard") {
                NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                NSPasteboard.general.setString(transcript, forType: .string)
            }
        }
        
    }
    
    func openImagePreview(){
        print("open image preview")
        print(data.RecognitionResults)
        let imagePreview = TLTextEditor(image: imageModel.image)
            .environmentObject(data)
            //.environmentObject(imageModel)
        if let window = imagePreviewWindow{
            window.contentView = NSHostingView(rootView: imagePreview)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        else{
            imagePreviewWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: imageModel.image.size.width, height: imageModel.image.size.height),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
            imagePreviewWindow!.center()
            imagePreviewWindow!.setFrameAutosaveName("Image Preview")
            imagePreviewWindow!.isReleasedWhenClosed = false
            imagePreviewWindow!.contentView = NSHostingView(rootView: imagePreview)
            imagePreviewWindow!.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(dataModel: DataModel(), imageModel: ImageModel(), userPreference: UserPreference())
        }
    }
}
#endif
