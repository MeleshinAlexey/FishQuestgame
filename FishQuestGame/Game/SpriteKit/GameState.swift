//
//  GameState.swift
//  FishQuestGame
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class GameState: ObservableObject {

    // MARK: - Stored values
    @AppStorage("coins") private var storedCoins: Int = 0
    @AppStorage("hamstersDestroyed") private var storedHamstersDestroyed: Int = 0
    @AppStorage("friendMatchesPlayed") private var storedFriendMatchesPlayed: Int = 0
    @AppStorage("claimedAchievements") private var storedClaimedAchievements: String = ""

    // MARK: - Published state
    @Published var coins: Int = 0 {
        didSet { storedCoins = coins }
    }

    @Published var hamstersDestroyed: Int = 0 {
        didSet { storedHamstersDestroyed = hamstersDestroyed }
    }

    @Published var friendMatchesPlayed: Int = 0 {
        didSet { storedFriendMatchesPlayed = friendMatchesPlayed }
    }

    @Published private(set) var claimedAchievements: Set<AchievementID> = [] {
        didSet {
            storedClaimedAchievements = claimedAchievements
                .map { $0.rawValue }
                .sorted()
                .joined(separator: ",")
        }
    }

    // MARK: - Init
    init() {
        coins = storedCoins
        hamstersDestroyed = storedHamstersDestroyed
        friendMatchesPlayed = storedFriendMatchesPlayed

        let parts = storedClaimedAchievements
            .split(separator: ",")
            .map(String.init)

        claimedAchievements = Set(
            parts.compactMap { AchievementID(rawValue: $0) }
        )
    }

    // MARK: - Economy
    func addCoins(_ amount: Int) {
        coins += amount
    }

    func spendCoins(_ amount: Int) {
        coins = max(0, coins - amount)
    }

    // MARK: - Gameplay stats
    func recordHamsterDestroyed(count: Int = 1) {
        hamstersDestroyed += max(0, count)
    }

    func recordFriendMatchPlayed(count: Int = 1) {
        friendMatchesPlayed += max(0, count)
    }

    // MARK: - Achievements logic
    func progress(for achievement: Achievement) -> Int {
        switch achievement.id {
        case .destroy100, .destroy200, .destroy1000:
            return hamstersDestroyed
        case .collect25000:
            return coins
        case .play100WithFriend:
            return friendMatchesPlayed
        }
    }

    func isCompleted(_ achievement: Achievement) -> Bool {
        progress(for: achievement) >= achievement.target
    }

    func isClaimed(_ achievement: Achievement) -> Bool {
        claimedAchievements.contains(achievement.id)
    }

    func claim(_ achievement: Achievement) {
        guard isCompleted(achievement),
              !isClaimed(achievement) else { return }

        addCoins(achievement.reward)
        claimedAchievements.insert(achievement.id)
    }
}
