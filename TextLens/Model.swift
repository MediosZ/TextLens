//
//  Model.swift
//  TextLens
//
//  Created by Tricster on 2020/11/8.
//

import Foundation
import Combine

class DataModel: ObservableObject {
    @Published var text: String = "Recognition"
    
    static let shared = DataModel()

}
class UserPreference: ObservableObject {
    @Published var startAtLaunch: Bool
        /*
        didSet{
            UserDefaults.standard.setValue(startAtLaunch, forKey: "startAtLaunch")
        }

    } */
    @Published var copyToPasteBoard: Bool
        /*
        didSet{
            UserDefaults.standard.setValue(copyToPasteBoard, forKey: "copyToPasteBoard")
        }

    } */
    @Published var useHotkey: Bool
        /*
        didSet{
            UserDefaults.standard.setValue(useHotkey, forKey: "useHotkey")
        }

    } */
    
    init(){
        startAtLaunch = UserDefaults.standard.bool(forKey: "startAtLaunch")
        copyToPasteBoard = UserDefaults.standard.bool(forKey: "copyToPasteBoard")
        useHotkey = UserDefaults.standard.bool(forKey: "useHotkey")
    }
    
}
