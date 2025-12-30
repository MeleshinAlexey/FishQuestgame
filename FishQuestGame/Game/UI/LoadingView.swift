//
//  LoadingView.swift
//  FishQuestGame
//
//  Created by Alexey Meleshin on 12/30/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var progress: CGFloat = 0.0
    @State private var isPortrait: Bool = true

    var body: some View {
        ZStack {
            Image(isPortrait ? "bg_load_portret" : "bg_load_horizonntal")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {

                Image("logo_load")
        
                Image("text_load")
                
                // капсула загрузки
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            Color(
                                red: 74 / 255,
                                green: 74 / 255,
                                blue: 74 / 255
                            )
                        )
                        .frame(height: 14)
                        .overlay(
                            Capsule()
                                .stroke(Color.white, lineWidth: 2)
                        )

                    Capsule()
                        .fill(
                            Color(
                                red: 48 / 255,
                                green: 111 / 255,
                                blue: 135 / 255
                            )
                        )
                        .frame(width: progress * 240, height: 14)
                        .animation(.linear(duration: 0.2), value: progress)
                }
                .frame(width: 240)
            }
        }
        .onAppear {
            updateOrientation()
            startFakeLoading()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIDevice.orientationDidChangeNotification
            )
        ) { _ in
            updateOrientation()
        }
    }

    private func updateOrientation() {
        let orientation = UIDevice.current.orientation
        isPortrait = orientation.isPortrait || orientation == .unknown
    }

    private func startFakeLoading() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if progress >= 1 {
                timer.invalidate()
            } else {
                progress += 0.01
            }
        }
    }
}

#Preview {
    LoadingView()
}
