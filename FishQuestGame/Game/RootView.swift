//
//  RootView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/30/25.
//

import SwiftUI
import Combine

struct RootView: View {
    @StateObject private var gameState = GameState()

    var body: some View {
        MainMenuView()
            .environmentObject(gameState)
            .onAppear {
                AudioManager.shared.startBackgroundMusic(
                    fileName: "bg_music",
                    volume: 0.35
                )
            }
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
