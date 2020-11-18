//
//  AppDelegate.swift
//  TextLens
//
//  Created by Tricster on 2020/11/6.
//

import Cocoa
import SwiftUI
import Preferences
import KeyboardShortcuts
import LaunchAtLogin
import Vision

extension Preferences.PaneIdentifier {
    static let general = Self("general")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var statusBarMenu: NSMenu!
    
    let dataModel = DataModel()
    let userPreference = UserPreference()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
        // Add `@Environment(\.managedObjectContext)` in the views that will need the context.

        
        // create the propver
        let popover = NSPopover()
        let contentView = ContentView(dataModel: dataModel, userPreference: userPreference)
            .environment(\.managedObjectContext, persistentContainer.viewContext)
        
        popover.contentSize = NSSize(width: 400, height: 400)
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "Icon")
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp])
        }
        
        // hot keys
        KeyboardShortcuts.onKeyUp(for: .fromPasteBoard) {
            if self.userPreference.useHotkey{
                // The user pressed the keyboard shortcut for “unicorn mode”!
                print("perform ocr from pasteboard")
                self.performOCRFromPasteBoard()
            }
        }

    }
    
    func performOCRFromPasteBoard(){
        let pb = NSPasteboard.general
        if let filepath = pb.string(forType: .fileURL), let url = URL(string: filepath), let image = NSImage(contentsOf: url){
            performOCR(image: image)
        }
        else if let data = pb.data(forType: .tiff), let image = NSImage(data: data){
            performOCR(image: image)
        }
    }
    
    func performOCR(image: NSImage){
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, options: [:])
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        textRecognitionRequest.recognitionLanguages = ["en_US"]
        textRecognitionRequest.usesLanguageCorrection = true
        do {
            try requestHandler.perform([textRecognitionRequest])
            DispatchQueue.main.async {
                self.dataModel.image = image
                self.dataModel.hasImage = true
            }
        } catch _ {}
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
            
            if userPreference.copyToPasteBoard {
                NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                NSPasteboard.general.setString(transcript, forType: .string)
            }
        }
    }
    
    @objc func togglePopover(_ sender: NSStatusBarButton) {
        if let button = self.statusBarItem.button, let event = NSApp.currentEvent {
            if event.type == NSEvent.EventType.rightMouseUp{
                statusBarItem.menu = statusBarMenu // add menu to button...
                statusBarItem.button?.performClick(nil) // ...and click
            }
            else{
                if self.popover.isShown {
                    self.popover.performClose(sender)
                    
                } else {
                    self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                    self.popover.contentViewController?.view.window?.becomeKey()
                }
            }

        }
    }

    @objc func menuDidClose(_ menu: NSMenu) {
        statusBarItem.menu = nil // remove menu so button works as before
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TextLens")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}
