//
//  GameViewModel.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/28/25.
//

import Foundation
import SwiftUI
import Combine 

@MainActor
final class GameViewModel: ObservableObject {
    @Published var leftScore: Int = 0
    @Published var rightScore: Int = 0
    @Published var timeLeft: Int = 30

    @Published var isGameOver: Bool = false
    @Published var winnerText: String = ""

    struct Player: Identifiable, Codable, Equatable {
        let id: UUID
        var name: String
        var iconAsset: String
    }

    struct MatchSetup: Codable, Equatable {
        var player1: Player
        var player2: Player
        var mode: Mode = .vsFriend

        /// Which side the human plays on (relevant for vsCPU).
        /// Default: human plays on the right side.
        var humanSide: HumanSide = .right

        enum Mode: String, Codable {
            case vsFriend
            case vsCPU
        }

        enum HumanSide: String, Codable {
            case left
            case right
        }
    }
    
    func setScore(left: Int, right: Int) {
        leftScore = left
        rightScore = right
    }

    func setTime(_ t: Int) { timeLeft = t }

    func endMatch(winner: Side, left: Int, right: Int, reason: String) {
        isGameOver = true
        winnerText = (winner == .left ? "Игрок 1 победил" : "Игрок 2 победил") + " • \(reason)"
        leftScore = left
        rightScore = right
    }

    func resetUI() {
        leftScore = 0; rightScore = 0; timeLeft = 30
        isGameOver = false; winnerText = ""
    }
    
}
