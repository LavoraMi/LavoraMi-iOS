//
//  AccountDatasInfoView.swift
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

struct AccountDatasInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var startImageTransition: Bool = false
    @StateObject var authManager: AuthManager
    
    @State var saveFavoritesData: Bool
    @State var saveYourLinesData: Bool
    @State var isLoading: Bool = true
    @State var errorFetching: Bool = false
    @Binding var currentSyncStatus: String
    @Binding var currentSyncStatusIcon: String
    @AppStorage("enableAnimations") var enableAnimations = true
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("linesSelected") private var linesSelected: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Image("cloudIcon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.red)
                        .padding(.top, 40)

                    Text("Scegli i tuoi Dati")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Scegli che tipologia di dati vuoi che vengano salvati nei nostri Database, per poterci accedere sempre dal tuo Account.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("I tuoi dati di LavoraMi sono completamente privati e protetti, potrai richiederli quando vuoi selezionando \"Richiedi i tuoi dati\".")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Text("Dati da Salvare")
                            .foregroundColor(.secondary)
                            .bold()
                        Spacer()
                    }
                    .padding(.bottom, -20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $saveFavoritesData) {
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                                
                                Text("Linee Preferite")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .disabled(isLoading || errorFetching)
                        .onChange(of: saveFavoritesData) {
                            Task {
                                let res: Bool
                                try await authManager.saveUserPreferences(enableFavorites: saveFavoritesData, enableYourLines: saveYourLinesData)
                                
                                if(saveFavoritesData) { res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected) }
                                else if(!saveFavoritesData && saveYourLinesData){ res = await authManager.saveDatasToDb(favorites: [], yourLines: linesSelected) }
                                else{res = await authManager.saveDatasToDb(favorites: [], yourLines: [])}
                                
                                if(!saveFavoritesData && !saveYourLinesData) {
                                    currentSyncStatus = String(localized: .nonSincronizzato)
                                    currentSyncStatusIcon = "cloudDisabled"
                                }
                                else {
                                    currentSyncStatus = String(localized: .sincronizzato)
                                    currentSyncStatusIcon = "cloudSynced"
                                }
                                
                                print("RESULT: \(res)")
                            }
                        }
                        .tint(.red)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        Toggle(isOn: $saveYourLinesData) {
                            HStack(spacing: 12) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                                
                                Text("Le tue linee")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .disabled(isLoading || errorFetching)
                        .onChange(of: saveYourLinesData) {
                            Task {
                                let res: Bool
                                
                                try await authManager.saveUserPreferences(enableFavorites: saveFavoritesData, enableYourLines: saveYourLinesData)
                                
                                if(saveYourLinesData) { res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected) }
                                else if(!saveYourLinesData && saveFavoritesData){ res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: []) }
                                else{res = await authManager.saveDatasToDb(favorites: [], yourLines: [])}
                                
                                if(!saveFavoritesData && !saveYourLinesData) {
                                    currentSyncStatus = String(localized: .nonSincronizzato)
                                    currentSyncStatusIcon = "cloudDisabled"
                                }
                                else {
                                    currentSyncStatus = String(localized: .sincronizzato)
                                    currentSyncStatusIcon = "cloudSynced"
                                }
                                
                                print("RESULT: \(res)")
                            }
                        }
                        .tint(.red)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        if(isLoading && !errorFetching) {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.red)
                                Text("Caricamento...")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 10)
                            .padding(.leading, 5)
                        }
                        if(errorFetching) {
                            HStack(spacing: 8) {
                                Image(systemName: "wifi.slash")
                                    .foregroundStyle(.red)
                                Text("Errore di connessione.")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 10)
                            .padding(.leading, 5)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Preferenze Dati")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear{
                Task {
                    let res: UserPreferencesDatas = await authManager.fetchUserPreferences()
                    
                    saveYourLinesData = res.enable_your_lines
                    saveFavoritesData = res.enable_favorites
                    errorFetching = res.user_email == ""
                    
                    isLoading = false
                }
            }
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}
