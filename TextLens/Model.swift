//
//  Model.swift
//  TextLens
//
//  Created by Tricster on 2020/11/8.
//

import Foundation
import Combine
import SwiftUI



class DataModel: ObservableObject {
    @Published var text: String = "Recognition result will be here."
    @Published var image: NSImage = NSImage(named: "DragBackground") ?? NSImage()
    @Published var width: CGFloat = 0.0
    @Published var height: CGFloat = 0.0
    @Published var hasImage: Bool = false
    @Published var RecognitionResults: [(CGRect, String, Bool)] = []
}

class UserPreference: ObservableObject {
    @Published var startAtLaunch: Bool{
        didSet{
            UserDefaults.standard.setValue(startAtLaunch, forKey: "startAtLaunch")
            //LaunchAtLogin.isEnabled = startAtLaunch
        }

    }
    @Published var copyToPasteBoard: Bool{
        didSet{
            UserDefaults.standard.setValue(copyToPasteBoard, forKey: "copyToPasteBoard")
        }
    }
    @Published var useHotkey: Bool{
        didSet{
            UserDefaults.standard.setValue(useHotkey, forKey: "useHotkey")
        }
    }
    
    init(){
        startAtLaunch = UserDefaults.standard.bool(forKey: "startAtLaunch")
        copyToPasteBoard = UserDefaults.standard.bool(forKey: "copyToPasteBoard")
        useHotkey = UserDefaults.standard.bool(forKey: "useHotkey")
    }
    
}
