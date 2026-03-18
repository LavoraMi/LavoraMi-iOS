//
//  SplashScreenView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 25/01/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 1.0
    @State private var scaleEffect = 1.0
    @State private var contentOpacity: Double = 0
    @State private var showSetupScreen: Bool = false
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    
    var body: some View {
        ZStack {
            ContentView(showSetupScreen: $showSetupScreen)
                .opacity(contentOpacity)
            VStack {
                Image("icon")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .scaleEffect(scaleEffect)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.4).delay(0.7)){
                    scaleEffect = 0.5
                }
                withAnimation(.easeIn(duration: 0.4).delay(1)){
                    scaleEffect = 180
                }
                withAnimation(.easeIn(duration: 0.15).delay(1.25)) {
                    opacity = 0
                }
                withAnimation(.easeIn(duration: 0.2).delay(1.15)) {
                    contentOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if hasNotCompletedSetup {
                        showSetupScreen = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
