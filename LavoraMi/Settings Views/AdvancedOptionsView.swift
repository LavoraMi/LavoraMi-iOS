//
//  AdvancedOptionsView.swift
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

struct AdvancedOptionsView: View {
    @AppStorage("showErrorMessages") var showErrorMessages: Bool = false
    @AppStorage("showStrikeBanner") var showStrikeBanner: Bool = true
    @AppStorage("requireFaceID") var requireFaceID: Bool = true
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("showTranslateButton") var showTranslateButton: Bool = false
    @AppStorage("showRecentSearches") var showRecentSearches: Bool = true
    @State private var openWidgetLine: Bool = DataManager.shared.getOpenWidgetLine()
    private var currentDeviceBiometric: BiometricType = BiometricAuth.getBiometricType()
    @State private var presentedCacheAlert = false
    
    var iphoneGenIcon: String {
        let height = UIScreen.main.bounds.height
        
        switch height {
            case 852, 932:
                return "iphone.gen3.radiowaves.left.and.right"
            case 812, 844, 896, 926:
                return "iphone.gen2.radiowaves.left.and.right"
            default:
                return "iphone.gen1.radiowaves.left.and.right"
        }
    }
    
    var body: some View {
        List{
            Section(footer: Text("Mostra il banner degli scioperi nella Home quando sono presenti.")){
                Toggle(isOn: $showStrikeBanner){
                    Label("Mostra banner Scioperi", systemImage: "megaphone.fill")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            Section(footer: Text("Mostra le tue ricerche recenti nella pagina delle Linee.")){
                Toggle(isOn: $showRecentSearches){
                    Label("Mostra Ricerche Recenti", systemImage: "text.magnifyingglass")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            Section(footer: Text("Attiva i Feedback di vibrazione su alcune schermate.")){
                Toggle(isOn: $feedbacksEnabled){
                    Label("Attiva Feedback Vibrazione", systemImage: iphoneGenIcon)
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            if(Locale.current.language.languageCode?.identifier == "it"){
                Section(footer: Text("Mostra il pulsante per tradurre i lavori anche nella lingua italiana.")){
                    Toggle(isOn: $showTranslateButton){
                        Label("Mostra Pulsante Traduci", systemImage: "translate")
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
            }
            Section(footer: Text("Apre la linea selezionata per il Widget quando ci clicchi sopra. Se disattivata, apre l'app nella schermata Home.")){
                Toggle(isOn: $openWidgetLine){
                    Label("Apri Linea Widget", systemImage: "arrow.branch")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            .onChange(of: openWidgetLine) { _, newValue in
                DataManager.shared.setOpenWidgetLine(newValue)
            }
            Section(footer: Text("Richiedi \(getBiometricTypeByEnum()) per bloccare e sbloccare la sezione del tuo Account. Per modificare questa opzione dovrai autenticarti con \(getBiometricTypeByEnum()).")){
                Toggle(isOn: $requireFaceID){
                    Label("Richiedi \(getBiometricTypeByEnum())", systemImage: (getBiometricTypeByEnum() == "Codice") ? "lock.fill" : getBiometricTypeByEnum().lowercased())
                }
                .onChange(of: requireFaceID) { oldValue, newValue in
                    if(newValue == false){
                        BiometricAuth.authenticate{
                            print("FaceID Recognized!")
                            requireFaceID = false
                        } onFailure: { error in
                            print("Error during read of FaceID")
                            requireFaceID = true
                        }
                    }
                    else{
                        requireFaceID = requireFaceID
                    }
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            Section(footer: Text("Seleziona la modalità in cui aprire i link.")){
                Label("Apri link:", systemImage: "network")
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Picker(selection: $howToOpenLinks, content: {
                    ForEach(linkOpenTypes.allCases) { filter in
                        Text(filter.localizedID).tag(filter)
                            .foregroundStyle(Color("TextColor"))
                    }
                }, label: {
                    Text("")
                })
                
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                .pickerStyle(.inline)
                .labelsHidden()
            }
            Section(footer: Text("Mostra messaggi di errore quando fallisce il Download dei dati.")){
                Toggle(isOn: $showErrorMessages){
                    Label("Mostra Messaggi Errore", systemImage: "exclamationmark.bubble.fill")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            Section(footer: Text("Elimina la memoria Cache dal dispositivo, liberando spazio su disco.")){
                Button(role: .destructive) {
                    if(feedbacksEnabled){
                        HapticManager.shared.trigger()
                    }
                    presentedCacheAlert = true
                } label: {
                    Label("Pulisci Memoria Cache", systemImage: "trash.fill")
                }
                .confirmationDialog("Sei sicuro?", isPresented: $presentedCacheAlert) {
                    Button("Annulla", role: .cancel) { }
                    Button("Continua", role: .destructive) {
                        clearAllCache()
                    }
                } message: {
                    Text("Sei sicuro di voler pulire la memoria Cache?")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
        }
        .padding(.bottom, 20)
        .navigationTitle("Opzioni Avanzate")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
    }
    
    func getBiometricTypeByEnum() -> String {
        switch(currentDeviceBiometric){
            case .touchID:
                return "TouchID"
            case .faceID:
                return "FaceID"
            default:
                return "Codice"
        }
    }
    
    func clearAllCache() {
        URLCache.shared.removeAllCachedResponses()
        
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}
