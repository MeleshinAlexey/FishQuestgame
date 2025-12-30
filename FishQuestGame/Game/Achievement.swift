//
//  Achievement.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/30/25.
//

import Foundation

enum AchievementID: String, CaseIterable, Identifiable {
    case destroy100
    case destroy200
    case destroy1000
    case collect25000
    case play100WithFriend

    var id: String { rawValue }
}

struct Achievement: Identifiable {
    let id: AchievementID
    let title: String
    let target: Int
    let reward: Int
}
