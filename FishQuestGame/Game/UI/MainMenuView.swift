//
//  MainMenuView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/29/25.
//

import SwiftUI

struct MainMenuView: View {
    // Временно так. Потом привяжем к GameViewModel / сохранениям.
    @EnvironmentObject private var gameState: GameState
    @State private var showModeSelection: Bool = false
    @State private var showAchievements: Bool = false
    @State private var showSettings: Bool = false
    @State private var showQuests: Bool = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // Фон (всегда во весь экран, без safe area)
                Image("menu_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(.all)

                // Контент поверх
                ZStack {
                    // Хомяк слева
                    Image("menu_hamster")
                        .resizable()
                        .scaledToFit()
                        // подгони по вкусу: 0.40...0.55
                        .frame(width: size.width * 0.38)
                        .position(x: size.width * 0.16,
                                  y: size.height * 0.62)

                    // Заголовок
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width * 0.45)
                        .position(x: size.width * 0.50,
                                  y: size.height * 0.18)

                    // Счётчик монет справа сверху
                    CoinCounterView(coins: gameState.coins)
                        .frame(width: size.width * 0.22)
                        .position(x: size.width * 0.86,
                                  y: size.height * 0.11)

                    // Центральный блок кнопок
                    VStack(spacing: size.height * 0.025) {

                        // Большая PLAY
                        MenuButtonBig(title: "PLAY") {
                            showModeSelection = true
                        }
                        .frame(width: size.width * 0.30)

                        // Три маленькие
                        HStack(spacing: size.width * 0.02) {
                            MenuButtonSmall(title: "Achieve") {
                                showAchievements = true
                            }
                            MenuButtonSmall(title: "Settings") {
                                showSettings = true
                            }
                            MenuButtonSmall(title: "Quests") {
                                showQuests = true
                            }
                        }
                        .frame(width: size.width * 0.55)
                    }
                    // позиция как на скрине: чуть ниже центра
                    .position(x: size.width * 0.50,
                              y: size.height * 0.60)
                }
            }
        }
        .fullScreenCover(isPresented: $showModeSelection) {
            ModeSelectionView(showModeSelection: $showModeSelection)
                .environmentObject(gameState)
        }
        .fullScreenCover(isPresented: $showAchievements) {
            AchievementsView()
                .environmentObject(gameState)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(onClose: { showSettings = false })
                .environmentObject(gameState)
        }
        .fullScreenCover(isPresented: $showQuests) {
            QuestsView(onClose: {})
                .environmentObject(gameState)
        }
    }
}

// MARK: - Pieces

private struct CoinCounterView: View {
    let coins: Int

    var body: some View {
        ZStack {
            Image("user_balance")
                .resizable()
                .scaledToFit()

            Text("\(coins)")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(radius: 1)
                // небольшое смещение вправо, чтобы текст не залезал на иконку в ассете
                .offset(x: 12)
        }
    }
}

private struct MenuButtonBig: View {
    let title: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Image("button_bg")
                    .resizable()
                    .scaledToFit()

                Text(title)
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

private struct MenuButtonSmall: View {
    let title: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Image("button_bg")
                    .resizable()
                    .scaledToFit()

                Text(title)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    MainMenuView()
        .environmentObject(GameState())
        .previewInterfaceOrientation(.landscapeLeft)
}
