//
//  SplashScreenView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 25/01/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity = 1.0
    @State private var scaleEffect = 1.0
    @State private var contentOpacity: Double = 0
    @State private var contentLoaded = false
    @State private var showSetupScreen: Bool = false
    @State private var showWhatsNewScreen: Bool = false
    @State private var showMaintenance: Bool = false
    @State private var showNoConnection: Bool = false 
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    @StateObject private var viewModel = WorkViewModel()

    var body: some View {
        ZStack {
            if contentLoaded {
                if(showMaintenance){
                    MaintenanceView(maintenanceDeps: viewModel.maintenanceDeps, maintenanceDepsEn: viewModel.maintenanceDepsEn) {
                        showMaintenance = false
                    }
                    .opacity(contentOpacity)
                }
                else {
                    ContentView(showSetupScreen: $showSetupScreen, showWhatsNewScreen: $showWhatsNewScreen)
                        .opacity(contentOpacity)
                }
            }
            VStack(spacing: 12) {
                Image("icon")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .scaleEffect(scaleEffect)
                
                if(showNoConnection){
                    Label("Bloccato qui? Controlla la tua connessione.", systemImage: "wifi.exclamationmark")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
            }
            .opacity(opacity)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if !contentLoaded {
                    withAnimation {
                        showNoConnection = true
                    }
                }
            }
            viewModel.fetchRequirements {
                showMaintenance = viewModel.maintenanceModeEnabled
                contentLoaded = true
                showNoConnection = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startAnimation()
                }
            }
        }
    }

    private func startAnimation() {
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            scaleEffect = 0.5
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.8)) {
            scaleEffect = 1000
        }
        withAnimation(.easeIn(duration: 0.2).delay(0.95)) {
            contentOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.15).delay(1.05)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if hasNotCompletedSetup {
                showSetupScreen = true
            }
            showWhatsNewScreen = true
        }
    }
}

#Preview {
    SplashScreenView()
}
