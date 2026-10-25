//
//  FavoritesHeader.swift
//  LavoraMi
//
//  Created by Andrea Filice on 25/10/2026.
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

struct FavoritesHeader: View {
    @State private var showInfo = false
    
    var body: some View {
        HStack {
            Text("Preferiti")
            Button(action: { showInfo.toggle() }) {
                Image(systemName: "info.circle")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .buttonStyle(.borderless)
            .alert("Scegli i tuoi interessi", isPresented: $showInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Scegli i tuoi operatori di trasporti più usati e, mettendoli nei preferiti, riceverai subito le notifiche con nuovi lavori.")
            }
            .textCase(nil)
        }
    }
}
