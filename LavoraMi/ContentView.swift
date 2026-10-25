//
//  ContentView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 05/01/26.
//

import SwiftUI
import MapKit
import SafariServices
import WidgetKit
import LocalAuthentication
import SwiftUIMailView
import AuthenticationServices
import CryptoKit
import FirebaseCore
import FirebaseMessaging
import Translation
import StoreKit
import Combine
import SystemConfiguration
import CoreLocation
import FoundationModels

internal import Auth

//MARK: MAIN VIEW
struct ContentView: View {
    @StateObject private var viewModel = WorkViewModel()
    @Binding var showSetupScreen: Bool
    @State private var showUpdatePopUp: Bool = false
    @State private var selectedTab: Int = 0
    @State private var deepLinkedLine: DeepLinkLine? = nil
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("showWhatsNewScreen") var showWhatsNewScreenToggle: Bool = true

    @Environment(\.openURL) private var openURLAction

    var body: some View {
        TabView(selection: $selectedTab){
            MainView(viewModel: viewModel)
                .tabItem {Label("Home", image: "homeIcon")}
                .tag(0)
            LinesView(viewModel: viewModel)
                .tabItem{Label("Linee", systemImage: "arrow.branch")}
                .tag(1)
            SettingsView(viewModel: viewModel)
                .tabItem{Label("Impostazioni", systemImage: "gear")}
                .tag(2)
        }
        .tint(.red)
        .onChange(of: selectedTab) {
            if(feedbacksEnabled){
                HapticManager.shared.trigger()
            }
        }
        .sheet(isPresented: $showSetupScreen){
            SetupView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openLineDetailFromWidget)) { notification in
            guard let nome = notification.object as? String else { return }
            selectedTab = 1
            deepLinkedLine = DeepLinkLine(name: nome)
        }
        .fullScreenCover(item: $deepLinkedLine) { link in
            DeepLinkLineDetailWrapper(lineName: link.name, viewModel: viewModel)
        }
    }
}

#Preview{
    @Previewable @State var showSetupScreen: Bool = false
    ContentView(showSetupScreen: $showSetupScreen)
}
