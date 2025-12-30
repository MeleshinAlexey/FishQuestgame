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
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
