//
//  ObsoleteVersionView.swift
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

struct ObsoleteVersionView: View {
    @State private var showSetupScreen: Bool = true
    @StateObject private var viewModel = WorkViewModel()
    @Environment(\.openURL) private var openURLAction
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("icon")
                .resizable()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .font(.system(size: 10))
                .foregroundColor(Color("TextColor"))
            
            Text("Stai usando una versione obsoleta.")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            
            Text("Stai usando una versione non più supportata di LavoraMi, aggiorna all'ultima versione disponibile per avere accesso a nuove funzionalità e risolvere problemi.")
                .font(.system(size: 16))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 5)
            
            Text("Ultima versione supportata: \(viewModel.minimumVersion).")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 5)
            
            Button {
                let url = URL(string: "https://apps.apple.com/us/app/lavorami/id6760344298")!
                openURLAction(url)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.forward")
                    Text("Aggiorna ora")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red)
                .cornerRadius(8)
            }
            .padding(.top, 25)
            
            Spacer()
        }
        .onAppear(){
            viewModel.fetchRequirements()
        }
    }
}
