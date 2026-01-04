//
//  QuestsView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/29/25.
//

import SwiftUI
import Combine

// MARK: - Day-based quests (simple daily login/streak)
// We unlock rewards by the number of days played (1...5).
// Claimed state is persisted in UserDefaults so rewards are one-time.

private let kDaysPlayedKey = "daysPlayed"
private let kClaimedDailyQuestsKey = "claimedDailyQuests"

private enum QuestID: String, CaseIterable, Identifiable {
    case day1
    case day2
    case day3
    case day4
    case day5

    var id: String { rawValue }

    var requiredDay: Int {
        switch self {
        case .day1: return 1
        case .day2: return 2
        case .day3: return 3
        case .day4: return 4
        case .day5: return 5
        }
    }
}

private extension GameState {
    /// How many days the user has played (you can increment this elsewhere when the user launches/returns daily).
    var daysPlayed: Int {
        get { UserDefaults.standard.integer(forKey: kDaysPlayedKey) }
        set { UserDefaults.standard.set(newValue, forKey: kDaysPlayedKey) }
    }

    func isQuestCompleted(_ questID: QuestID) -> Bool {
        daysPlayed >= questID.requiredDay
//        true
    }

    func isQuestClaimed(_ questID: QuestID) -> Bool {
        let claimed = Set(UserDefaults.standard.stringArray(forKey: kClaimedDailyQuestsKey) ?? [])
        return claimed.contains(questID.rawValue)
    }

    func claimQuest(_ questID: QuestID, reward: Int) {
        guard isQuestCompleted(questID), !isQuestClaimed(questID) else { return }

        // Add coins
        coins += reward

        // Persist claimed state
        var claimed = Set(UserDefaults.standard.stringArray(forKey: kClaimedDailyQuestsKey) ?? [])
        claimed.insert(questID.rawValue)
        UserDefaults.standard.set(Array(claimed), forKey: kClaimedDailyQuestsKey)
    }
}

struct QuestsView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var gameState: GameState
    let onClose: () -> Void

    @AppStorage("appLanguage") private var appLanguage: String = "en"

    // MARK: - Localization (explicit bundle lookup for in-app language)
    private func L(_ key: String) -> String {
        if let path = Bundle.main.path(forResource: appLanguage, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return NSLocalizedString(key, tableName: nil, bundle: langBundle, value: key, comment: "")
        }
        return NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    }

    private var quests: [QuestDefinition] {
        [
            .init(id: .day1, title: L("quests.day1"), reward: 100),
            .init(id: .day2, title: L("quests.day2"), reward: 100),
            .init(id: .day3, title: L("quests.day3"), reward: 100),
            .init(id: .day4, title: L("quests.day4"), reward: 100),
            .init(id: .day5, title: L("quests.day5"), reward: 100)
        ]
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // Match AchievementsView layout approach
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
                    // Top bar (home + balance)
                    HStack {
                        Button {
                            SoundManager.shared.playButton()
                            onClose()
                            dismiss()
                        } label: {
                            Image("home_button")
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)

                        ZStack {
                            Image("user_balance")

                            Text("\(gameState.coins)")
                                .font(.system(size: min(34, h * 0.055), weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                                .offset(x: min(26, w * 0.02))
                        }
                    }

                    // Title (same style pattern as AchievementsView)
                    Text(L("quests.title"))
                        .font(.system(size: min(64, h * 0.10), weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(radius: 6)
                        .padding(.top, max(6, h * 0.01))
                        .padding(.bottom, max(10, h * 0.02))

                    // Cards row
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(quests) { q in
                            QuestCard(
                                quest: q,
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

private struct QuestDefinition: Identifiable {
    let id: QuestID
    let title: String
    let reward: Int
}

private struct QuestCard: View {
    @EnvironmentObject private var gameState: GameState
    let quest: QuestDefinition
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let buttonHeight: CGFloat

    var body: some View {
        let titleFont = max(10, min(20, cardWidth * 0.11))
        let rewardWidth = cardWidth * 0.95

        return VStack(spacing: max(10, cardHeight * 0.08)) {
            ZStack {
                Image("quest_frame")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cardWidth, height: cardHeight)

                // Title block (kept inside the lower paper area)
                VStack {
                    Spacer(minLength: 0)

                    Text(quest.title)
                        .font(.system(size: titleFont, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .minimumScaleFactor(0.65)
                        .allowsTightening(true)
                        .lineSpacing(-2)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 2)
                        .frame(maxWidth: cardWidth * 0.80)
                        .padding(.bottom, cardHeight * 0.27)
                }
            }

            let isCompleted = gameState.isQuestCompleted(quest.id)
            let isClaimed = gameState.isQuestClaimed(quest.id)

            Button {
                SoundManager.shared.playButton()
                gameState.claimQuest(quest.id, reward: quest.reward)
            } label: {
                RewardButton(value: quest.reward, width: rewardWidth, height: buttonHeight)
                    .opacity(isCompleted ? (isClaimed ? 0.5 : 1.0) : 0.35)
            }
            .buttonStyle(.plain)
            .disabled(!isCompleted || isClaimed)
        }
        .frame(width: cardWidth)
    }
}

private struct RewardButton: View {
    let value: Int
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let fontSize = max(22, height * 0.45)

        return ZStack {
            Image("button_bg")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)

            Text("\(value)")
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .shadow(radius: 2)
                .padding(.horizontal, width * 0.10)
        }
        .frame(width: width, height: height)
    }
}

private struct CoinCounterView: View {
    let coins: Int

    var body: some View {
        ZStack {
            Image("user_balance")
                .resizable()
                .scaledToFit()

            Text("\(coins)")
                .font(.system(size: 22, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
                .shadow(radius: 1)
                .offset(x: 12)
        }
    }
}

#Preview {
    QuestsView(onClose: {})
        .environmentObject(GameState())
        .previewInterfaceOrientation(.landscapeLeft)
}
