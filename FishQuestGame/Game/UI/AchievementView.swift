//
//  AchievementView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/30/25.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    // MARK: - Localization (explicit bundle lookup for in-app language)
    private func L(_ key: String) -> String {
        if let path = Bundle.main.path(forResource: appLanguage, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return NSLocalizedString(key, tableName: nil, bundle: langBundle, value: key, comment: "")
        }
        return NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    }

    private var achievements: [Achievement] {
        [
            .init(id: .destroy100, title: L("achievements.destroy100"), target: 100, reward: 100),
            .init(id: .destroy200, title: L("achievements.destroy200"), target: 200, reward: 100),
            .init(id: .collect25000, title: L("achievements.collect25000"), target: 25_000, reward: 100),
            .init(id: .destroy1000, title: L("achievements.destroy1000"), target: 1_000, reward: 100),
            .init(id: .play100WithFriend, title: L("achievements.play100WithFriend"), target: 100, reward: 100)
        ]
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // Layout tuned for landscape like the screenshot
            let horizontalPadding: CGFloat = max(16, w * 0.03)
            let spacing: CGFloat = max(14, w * 0.02)
            let cardWidth: CGFloat = (w - horizontalPadding * 2 - spacing * 4) / 5
            let cardHeight: CGFloat = min(h * 0.62, cardWidth * 1.55)
            let buttonHeight: CGFloat = max(44, h * 0.09)

            ZStack {
                Image("menu_background")
                    .resizable()

                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button {
                            SoundManager.shared.playButton()
                            dismiss()
                        } label: {
                            Image("home_button")
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)

                        ZStack {
                            Image("user_balance")

                            // Number sits on top of the balance plate
                            Text("\(gameState.coins)")
                                .font(.system(size: min(34, h * 0.055), weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                                .offset(x: min(26, w * 0.02))
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, max(8, h * 0.02))

                    // Title
                    Text(L("achievements.title"))
                        .font(.system(size: min(64, h * 0.10), weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(radius: 6)
                        .padding(.top, max(6, h * 0.01))
                        .padding(.bottom, max(10, h * 0.02))

//                    // DEBUG: quick achievement testing (remove later)
//                    HStack(spacing: 12) {
//                        Button("+100 hamsters") {
//                            gameState.recordHamsterDestroyed(count: 100)
//                        }
//
//                        Button("+10k coins") {
//                            gameState.addCoins(10_000)
//                        }
//
//                        Button("+1 friend") {
//                            gameState.recordFriendMatchPlayed(count: 1)
//                        }
//                    }
//                    .font(.system(size: 16, weight: .heavy))
//                    .buttonStyle(.borderedProminent)
//                    .tint(.white.opacity(0.18))
//                    .foregroundStyle(.white)
//                    .padding(.bottom, max(10, h * 0.01))
                    // Cards row
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(Array(achievements.enumerated()), id: \.element.id) { index, a in
                            AchievementCard(
                                achievement: a,
                                frameImageName: "achievements_frame\(index + 1)",
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                buttonHeight: buttonHeight
                            )
                        }
                    }
                    .padding(.horizontal, horizontalPadding)

                    Spacer(minLength: 0)
                }
            }
        }
        .environment(\.locale, Locale(identifier: appLanguage))
        .id(appLanguage)
    }
}

private struct AchievementCard: View {
    @EnvironmentObject private var gameState: GameState

    let achievement: Achievement
    let frameImageName: String
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let buttonHeight: CGFloat

    var body: some View {
        let progress = gameState.progress(for: achievement)
        let completed = gameState.isCompleted(achievement)
        let claimed = gameState.isClaimed(achievement)
        let canClaim = completed && !claimed

        VStack(spacing: max(10, cardHeight * 0.04)) {
            ZStack {
                Image(frameImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: cardWidth, height: cardHeight)

                // Text block (bottom area like the screenshot)
                VStack {
                    Spacer()

                    Text(achievement.title)
                        // Smaller base size + shrink-to-fit for long translations
                        .font(.system(size: max(13, cardWidth * 0.085), weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(radius: 3)
                        .lineLimit(4)
                        .minimumScaleFactor(0.55)
                        .allowsTightening(true)
                        .frame(maxWidth: cardWidth * 0.80)
                        .padding(.horizontal, 8)
                        .padding(.bottom, max(10, cardHeight * 0.10))
                        .offset(y: -cardHeight * 0.087)
                }
                .frame(width: cardWidth, height: cardHeight)
            }

            Button {
                SoundManager.shared.playButton()
                gameState.claim(achievement)
            } label: {
                ZStack {
                    Image("button_bg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: cardWidth * 0.95, height: buttonHeight)

                    Text("\(achievement.reward)")
                        .font(.system(size: max(22, buttonHeight * 0.45), weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(radius: 3)
                }
            }
            .disabled(!canClaim)
            .opacity(canClaim ? 1.0 : 0.45)
        }
        .frame(width: cardWidth)
    }
}

#Preview {
    AchievementsView()
        .environmentObject(GameState())
}
