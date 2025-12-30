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

    private let quests: [QuestDefinition] = [
        .init(id: .day1, title: "Day 1\nReward", reward: 100),
        .init(id: .day2, title: "Day 2\nReward", reward: 100),
        .init(id: .day3, title: "Day 3\nReward", reward: 100),
        .init(id: .day4, title: "Day 4\nReward", reward: 100),
        .init(id: .day5, title: "Day 5\nReward", reward: 100)
    ]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let insets = geo.safeAreaInsets

            // Safe-area aware layout (everything except background)
            let contentWidth = size.width - insets.leading - insets.trailing
            let contentHeight = size.height - insets.top - insets.bottom

            let horizontalPadding = contentWidth * 0.045
            let topPadding = max(10.0, contentHeight * 0.03)
            let bottomPadding = max(10.0, contentHeight * 0.04)

            // Cards: make them large and evenly distributed across the width
            let spacing = max(14.0, min(28.0, contentWidth * 0.03))
            let availableWidth = contentWidth - (horizontalPadding * 2)
            let slotWidth = (availableWidth - spacing * 4) / 5

            // Prefer bigger cards (like the reference), but clamp so it fits any device
            let cardWidth = min(max(120.0, slotWidth), min(200.0, contentWidth * 0.24))
            let cardHeight = min(max(150.0, contentHeight * 0.50), 260.0)

            ZStack {
                Image("menu_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    topBar(size: size)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, insets.top + topPadding)
                        .padding(.bottom, contentHeight * 0.04)

                    Spacer(minLength: 0)
                        .frame(height: contentHeight * 0.06)

                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(quests) { q in
                            QuestCard(quest: q, cardWidth: cardWidth, cardHeight: cardHeight)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: cardHeight + (cardHeight * 0.30))
                    .padding(.horizontal, horizontalPadding)

                    Spacer(minLength: 0)
                        .frame(height: bottomPadding)
                }
            }
        }
    }

    @ViewBuilder
    private func topBar(size: CGSize) -> some View {
        let iconWidth = size.width * 0.07
        let balanceWidth = size.width * 0.22

        HStack(alignment: .center) {
            Button {
                // If MainMenu passed a close hook, run it, then dismiss.
                onClose()
                dismiss()
            } label: {
                Image("home_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Text("Quests")
                .font(.system(size: min(size.width, size.height) * 0.085, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(radius: 3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            CoinCounterView(coins: gameState.coins)
                .frame(width: balanceWidth)
        }
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

    var body: some View {
        let titleFont = max(10, min(20, cardWidth * 0.11))
        let rewardWidth = cardWidth * 0.85

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
                        .padding(.bottom, cardHeight * 0.2)
                }
            }

            let isCompleted = gameState.isQuestCompleted(quest.id)
            let isClaimed = gameState.isQuestClaimed(quest.id)

            Button {
                gameState.claimQuest(quest.id, reward: quest.reward)
            } label: {
                RewardButton(value: quest.reward, width: rewardWidth)
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

    var body: some View {
        let fontSize = max(12, width * 0.27)

        return ZStack {
            Image("button_bg")
                .resizable()
                .scaledToFit()

            Text("\(value)")
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .shadow(radius: 2)
                .padding(.horizontal, width * 0.10)
        }
        .frame(width: width)
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
