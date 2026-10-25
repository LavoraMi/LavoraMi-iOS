//
//  MaintenanceView.swift
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

// MARK: MAINTENANCE VIEW
struct MaintenanceView: View {
    var maintenanceDeps: String = ""
    var maintenanceDepsEn: String = ""
    var maintenanceDepsEs: String = ""
    var onResolved: () -> Void = {}
    
    @State private var showSetupScreen: Bool = true
    @StateObject private var viewModel = WorkViewModel()
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(Color("TextColor"))
            
            Text("Manutenzione in corso.")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            
            Text("I server di LavoraMi non sono attualmente disponibili. Ci scusiamo per il disagio.")
                .font(.system(size: 16))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 5)
            
            if !maintenanceDeps.isEmpty && Bundle.main.preferredLocalizations.first?.hasPrefix("it") == true {
                Text(maintenanceDeps)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            else if !maintenanceDepsEn.isEmpty && Bundle.main.preferredLocalizations.first?.hasPrefix("en") == true {
                Text(maintenanceDepsEn)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            else if !maintenanceDepsEs.isEmpty && Bundle.main.preferredLocalizations.first?.hasPrefix("es") == true {
                Text(maintenanceDepsEs)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            
            Button {
                guard !isLoading else { return }
                isLoading = true
                
                viewModel.fetchRequirements {
                    if (!viewModel.maintenanceModeEnabled){
                        onResolved()
                    }
                    
                    stopLoading()
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isLoading ? "Caricamento..." : "Riprova")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isLoading ? Color.gray : Color.red)
                .cornerRadius(8)
            }
            .padding(.top, 25)
            
            Spacer()
        }
    }
    
    func stopLoading() {
        isLoading = false
    }
}
