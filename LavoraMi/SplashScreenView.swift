//
//  SplashScreenView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 25/01/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var iconScale: CGFloat = 1.0
    @State private var panelScale: CGFloat = 1.0
    @State private var splashVisible = true
    @State private var contentOpacity: Double = 0
    @State private var contentLoaded = false
    @State private var showSetupScreen = false
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if contentLoaded {
                    ContentView(showSetupScreen: $showSetupScreen)
                        .opacity(contentOpacity)
                }
                if splashVisible {
                    ZStack {
                        Color.white.ignoresSafeArea()
                        Image("icon")
                            .resizable()
                            .frame(width: 150, height: 150)
                            .scaleEffect(iconScale)
                    }
                    .scaleEffect(panelScale)
                    .ignoresSafeArea()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    contentLoaded = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        startAnimation(screenSize: geo.size)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private func startAnimation(screenSize: CGSize) {
        ///In this function we optimize the Splah-Screen animation for better performance and fluidity
        withAnimation(.easeInOut(duration: 0.15).delay(0.4)) {
            iconScale = 0.82
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.55)) {
            iconScale = 1.0
        }
        let expandScale = (max(screenSize.width, screenSize.height) / 150) * 3
        withAnimation(.easeIn(duration: 0.3).delay(0.75)) {
            panelScale = expandScale
            contentOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            splashVisible = false
            if hasNotCompletedSetup {
                showSetupScreen = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
