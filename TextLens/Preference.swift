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

extension KeyboardShortcuts.Name {
    static let fromPasteBoard = Self("fromPasteBoard")
}

/**
Function wrapping SwiftUI into `PreferencePane`, which is mimicking view controller's default construction syntax.
*/
let GeneralPreferenceViewController: () -> PreferencePane = {
    /// Wrap your custom view into `Preferences.Pane`, while providing necessary toolbar info.
    let paneView = Preferences.Pane(
        identifier: .general,
        title: "General",
        toolbarIcon: NSImage(named: NSImage.userAccountsName)!
    ) {
        GeneralView().environmentObject(UserPreference.shared)
    }

    return Preferences.PaneHostingController(pane: paneView)
}

struct GeneralView: View{
    private let contentWidth: Double = 500.0
    @EnvironmentObject var preference: UserPreference
    
    var body: some View{
        Preferences.Container(contentWidth: contentWidth){
            Preferences.Section(label: {
                Text("General:")
            }){
                Toggle("Copy Recognition Result to PasteBoard", isOn: $preference.copyToPasteBoard)
                    .onReceive(Just(preference.copyToPasteBoard), perform: { value in
                        preference.copyToPasteBoard = value
                    })
                Text("Copy recognition result to pasteboard automatically if recognition succeed.").preferenceDescription()
                Toggle("Start at Launch", isOn: $preference.startAtLaunch)
                    .onReceive(Just(preference.startAtLaunch), perform: { value in
                        preference.startAtLaunch = value
                })
            }
            Preferences.Section(label: {
                Toggle("Hotkey:", isOn: $preference.useHotkey)
                    .onReceive(Just(preference.useHotkey), perform: { value in
                        preference.useHotkey = value
                })
            }){
                Text("Perform OCR on image from pasteboard")
                KeyboardShortcuts.Recorder(for: .fromPasteBoard)
            }
        }
    }
}

struct GeneralView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralView()
    }
}
