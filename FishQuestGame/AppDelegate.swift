//
//  AppDelegate.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 1/4/26.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    // По умолчанию разрешаем все (чтобы Loading мог быть везде)
    static var orientationLock: UIInterfaceOrientationMask = .all

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Self.orientationLock
    }
}
