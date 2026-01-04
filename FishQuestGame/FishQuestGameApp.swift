//
//  FishQuestGameApp.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/28/25.
//

import SwiftUI

@main
struct FishQuestGameApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
