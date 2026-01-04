//
//  MainMenuView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/29/25.
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var gameState: GameState
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @State private var showModeSelection: Bool = false
    @State private var showAchievements: Bool = false
    @State private var showSettings: Bool = false
    @State private var showQuests: Bool = false

    // MARK: - Localization (explicit bundle lookup for in-app language)
    private func L(_ key: String) -> String {
        if let path = Bundle.main.path(forResource: appLanguage, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return NSLocalizedString(key, tableName: nil, bundle: langBundle, value: key, comment: "")
        }
        return NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                Image("menu_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(.all)

                ZStack {
                    Image("menu_hamster")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width * 0.38)
                        .position(x: size.width * 0.16,
                                  y: size.height * 0.62)

                    // Localized title instead of a logo image
                    Text(L("menu.logo"))
                        .font(.system(size: max(28, min(84, size.height * 0.13)), weight: .heavy))
                        .foregroundStyle(Color(red: 250/255, green: 226/255, blue: 76/255))
                        .shadow(radius: 3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .allowsTightening(true)
                        .blueTextOutline()
                        .frame(width: size.width * 0.45)
                        .position(x: size.width * 0.50,
                                  y: size.height * 0.18)

                    CoinCounterView(coins: gameState.coins)
                        .frame(width: size.width * 0.22)
                        .position(x: size.width * 0.86,
                                  y: size.height * 0.11)

                    VStack(spacing: size.height * 0.025) {

                        MenuButtonBig(title: L("menu.play")) {
                            showModeSelection = true
                        }
                        .frame(width: size.width * 0.30)

                        HStack(spacing: size.width * 0.02) {
                            MenuButtonSmall(title: L("menu.achieve")) {
                                showAchievements = true
                            }
                            MenuButtonSmall(title: L("menu.settings")) {
                                showSettings = true
                            }
                            MenuButtonSmall(title: L("menu.quests")) {
                                showQuests = true
                            }
                        }
                        .frame(width: size.width * 0.55)
                    }
                    .position(x: size.width * 0.50,
                              y: size.height * 0.60)
                }
            }
        }
        .environment(\.locale, Locale(identifier: appLanguage))
        .id(appLanguage)
        .fullScreenCover(isPresented: $showModeSelection) {
            ModeSelectionView(showModeSelection: $showModeSelection)
                .environmentObject(gameState)
                .environment(\.locale, Locale(identifier: appLanguage))
                .id(appLanguage)
        }
        .fullScreenCover(isPresented: $showAchievements) {
            AchievementsView()
                .environmentObject(gameState)
                .environment(\.locale, Locale(identifier: appLanguage))
                .id(appLanguage)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(onClose: { showSettings = false })
                .environmentObject(gameState)
                .environment(\.locale, Locale(identifier: appLanguage))
                .id(appLanguage)
        }
        .fullScreenCover(isPresented: $showQuests) {
            QuestsView(onClose: {})
                .environmentObject(gameState)
                .environment(\.locale, Locale(identifier: appLanguage))
                .id(appLanguage)
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
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
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
            SoundManager.shared.playButton()
            action()
        } label: {
            ZStack {
                Image("button_bg")
                    .resizable()
                    .scaledToFit()

                // ✅ ADAPTIVE TEXT (one line, shrink-to-fit)
                Text(title)
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .allowsTightening(true)
                    .padding(.horizontal, 18)
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
            SoundManager.shared.playButton()
            action()
        } label: {
            ZStack {
                Image("button_bg")
                    .resizable()
                    .scaledToFit()

                // ✅ ADAPTIVE TEXT (one line, shrink-to-fit)
                Text(title)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .allowsTightening(true)
                    .padding(.horizontal, 14)
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

private extension View {
    func blueTextOutline() -> some View {
        self
            .overlay(
                self
                    .foregroundColor(.clear)
                    .shadow(color: Color(red: 42/255, green: 100/255, blue: 246/255), radius: 0, x: 2, y: 0)
                    .shadow(color: Color(red: 42/255, green: 100/255, blue: 246/255), radius: 0, x: -2, y: 0)
                    .shadow(color: Color(red: 42/255, green: 100/255, blue: 246/255), radius: 0, x: 0, y: 2)
                    .shadow(color: Color(red: 42/255, green: 100/255, blue: 246/255), radius: 0, x: 0, y: -2)
            )
    }
}

#Preview {
    MainMenuView()
        .environmentObject(GameState())
        .previewInterfaceOrientation(.landscapeLeft)
}
