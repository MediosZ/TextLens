//
//  Preference.swift
//  TextLens
//
//  Created by Tricster on 2020/11/8.
//

import SwiftUI
import Preferences
import Combine
import KeyboardShortcuts
import LaunchAtLogin

extension KeyboardShortcuts.Name {
    static let fromPasteBoard = Self("fromPasteBoard")
}

/**
Function wrapping SwiftUI into `PreferencePane`, which is mimicking view controller's default construction syntax.
*/
let GeneralPreferenceViewController: (_ userPreference: UserPreference) -> PreferencePane = {preference in
    /// Wrap your custom view into `Preferences.Pane`, while providing necessary toolbar info.
    let paneView = Preferences.Pane(
        identifier: .general,
        title: "General",
        toolbarIcon: NSImage(named: NSImage.userAccountsName)!
    ) {
        GeneralView(preference: preference)
    }

    return Preferences.PaneHostingController(pane: paneView)
}

struct GeneralView: View{
    private let contentWidth: Double = 500.0
    @ObservedObject var preference: UserPreference
    
    var body: some View{
        Preferences.Container(contentWidth: contentWidth){
            Preferences.Section(label: {
                Text("General:")
            }){
                Toggle("Copy Recognition Result to PasteBoard", isOn: $preference.copyToPasteBoard)
                Text("Copy recognition result to pasteboard automatically if recognition succeed.").preferenceDescription()
                //Toggle("Start at Launch", isOn: $preference.startAtLaunch)
                LaunchAtLogin.Toggle {
                    Text("Launch at login")
                }
            }
            Preferences.Section(label: {
                Toggle("Hotkey:", isOn: $preference.useHotkey)
            }){
                Text("Perform OCR on image from pasteboard")
                KeyboardShortcuts.Recorder(for: .fromPasteBoard)
            }
        }
    }
}

struct GeneralView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralView(preference: UserPreference())
    }
}
