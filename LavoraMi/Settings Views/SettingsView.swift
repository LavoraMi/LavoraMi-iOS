//
//  SettingsView.swift
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

//MARK: SETTINGS VIEW
struct SettingsView: View{
    @State private var expandedTrenord = false
    @State private var expandedATM = false
    @State private var expandedATMLines = false
    @State private var presentedAlertReset = false
    @State private var showBuildNumber = false
    @State private var selectedURL: URL?
    @State private var showErrorDBSavePopUp = false
    @State private var showInfoMapDeviations: Bool = false
    @State private var showWrapped: Bool = false
    @AppStorage("hasOpenedWrapped") private var hasOpenedWrapped: Bool = false
    @StateObject var viewModel: WorkViewModel
    @StateObject var authManager = AuthManager()
    
    ///APP DATAS
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("selectedWidgetLine") private var selectedWidgetLine: String = ""
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    @AppStorage("appearanceSelection") private var appearanceSelection: AppearanceType = .system
    @AppStorage("showErrorMessages") var showErrorMessages: Bool = false
    @AppStorage("showStrikeBanner") var showStrikeBanner: Bool = true
    @AppStorage("requireFaceID") var requireFaceID: Bool = true
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("showTranslateButton") var showTranslateButton: Bool = false
    @AppStorage("showRecentSearches") var showRecentSearches: Bool = true
    @AppStorage("recentlySearchedLinesData") private var recentlySearchedLinesData: Data = Data()
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURLAction
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    NavigationLink(destination: AccountView(auth: authManager)) {
                        HStack(spacing: 12) {
                            if authManager.isLoggedIn() {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 44, height: 44)
                                    
                                    Text(authManager.getInitialIconName())
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            else {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 35))
                                    .foregroundStyle(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if authManager.isLoggedIn() {
                                    Text(authManager.getFullName())
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Il tuo Account")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                                
                                Text("Gestisci il tuo Account")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    if(viewModel.wrappedEnabled && hasOpenedWrapped) {
                        Button(action: {
                            if feedbacksEnabled { HapticManager.shared.trigger() }
                            showWrapped = true
                        }) {
                            HStack(spacing: 8) {
                                Image("iconAppAndroid")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))

                                Text("RIGUARDA IL WRAPPED DEL MESE")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .tracking(0.5)

                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(Color(red: 224/255, green: 32/255, blue: 34/255))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .padding(.bottom, 10)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }
                Section(content: {
                    DisclosureGroup(isExpanded: $expandedTrenord){
                        HStack{
                            Label {
                                Text("Linee Suburbane")
                            } icon: {
                                Image("sLinesIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color("TextColor"))
                                    .tint(Color("TextColor"))
                            }
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                
                                if linesFavorites.contains("S") {
                                    linesFavorites.removeAll { $0 == "S" }
                                } else {
                                    linesFavorites.append("S")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("S") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("S") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label {
                                Text("Linee Regionali")
                            } icon: {
                                Image("rLinesIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color("TextColor"))
                                    .tint(Color("TextColor"))
                            }
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("R") {
                                    linesFavorites.removeAll { $0 == "R" }
                                } else {
                                    linesFavorites.append("R")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("R") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("R") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label {
                                Text("Linee Regio Express")
                            } icon: {
                                Image("reLinesIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color("TextColor"))
                                    .tint(Color("TextColor"))
                            }
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("RE") {
                                    linesFavorites.removeAll { $0 == "RE" }
                                } else {
                                    linesFavorites.append("RE")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("RE") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("RE") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    label: {
                        Label("Linee Trenord", systemImage: "train.side.front.car")
                    }
                    .onChange(of: expandedTrenord) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                    }
                    DisclosureGroup(isExpanded: $expandedATM){
                        HStack{
                            Label("Linee Metropolitane", systemImage: "tram.fill.tunnel")
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("Metro") {
                                    linesFavorites.removeAll { $0 == "Metro" }
                                } else {
                                    linesFavorites.append("Metro")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("Metro") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("Metro") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label("Linee Tram", systemImage: "tram.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("Tram") {
                                    linesFavorites.removeAll { $0 == "Tram" }
                                } else {
                                    linesFavorites.append("Tram")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("Tram") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("Tram") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label("Linee Bus", systemImage: "bus.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("Bus") {
                                    linesFavorites.removeAll { $0 == "Bus" }
                                } else {
                                    linesFavorites.append("Bus")
                                }
                                
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("Bus") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("Bus") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    label: {
                        Label("Linee ATM", systemImage: "tram.fill")
                    }
                    .onChange(of: expandedATM) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                    }
                    HStack{
                        Label("Linee TILO", systemImage: "train.side.front.car")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("Tilo") {
                                linesFavorites.removeAll { $0 == "Tilo" }
                            } else {
                                linesFavorites.append("Tilo")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("Tilo") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("Tilo") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee Movibus", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("z6") {
                                linesFavorites.removeAll { $0 == "z6" }
                            } else {
                                linesFavorites.append("z6")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("z6") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z6") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee NET", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("z3") {
                                linesFavorites.removeAll { $0 == "z3" }
                            } else {
                                linesFavorites.append("z3")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("z3") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z3") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee STAV", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("z55") {
                                linesFavorites.removeAll { $0 == "z55" }
                            } else {
                                linesFavorites.append("z55")
                            }
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("z55") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z55") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee STAR", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("z50") {
                                linesFavorites.removeAll { $0 == "z50" }
                            } else {
                                linesFavorites.append("z50")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("z50") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z50") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee Autoguidovie", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("Autoguidovie") {
                                linesFavorites.removeAll { $0 == "Autoguidovie" }
                            } else {
                                linesFavorites.append("Autoguidovie")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("Autoguidovie") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("Autoguidovie") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                }, header: {
                    FavoritesHeader()
                })
                Section("Generali"){
                    NavigationLink(destination: NotificationsView(viewModel: viewModel)){
                        Label("Notifiche", systemImage: "bell.fill")
                    }
                    Picker(selection: $preferredFilter){
                        ForEach(FilterBy.allCases) { filter in
                            Text(filter.localizedTitle).tag(filter)
                                .foregroundStyle(Color("TextColor"))
                        }
                    } label: {
                        Label("Filtro Predefinito", systemImage: "line.3.horizontal.decrease")
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: preferredFilter) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                    }
                    NavigationLink(destination: AppearancePickerView()) {
                        HStack {
                            Label("Aspetto e Lingua", systemImage: "circle.righthalf.filled")
                        }
                    }
                    NavigationLink(destination: AdvancedOptionsView()){
                        Label("Opzioni Avanzate", systemImage: "gearshape.fill")
                    }
                }
                Section("Aiuto"){
                    NavigationLink(destination: InfoView()){
                        Label("Fonti & Sviluppo", systemImage: "person.crop.circle.badge.questionmark")
                    }
                    NavigationLink(destination: HowAppWorksView()){
                        Label("Funzioni dell'App", systemImage: "questionmark.circle.fill")
                    }
                    HStack{
                        Button(action: {
                            showBuildNumber = !showBuildNumber
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                        }){
                            Label {
                                Text("Versione")
                                    .foregroundColor(Color("TextColor"))
                            } icon: {
                                Image(systemName: "info.circle.fill")
                            }
                        }
                        Spacer()
                        if(showBuildNumber){Text("\(Bundle.main.shortVersion) (\(Bundle.main.buildVersion))")
                            .textSelection(.enabled)}
                        else{Text("\(Bundle.main.shortVersion)")
                            .textSelection(.enabled)}
                    }
                }
                Section("Collegamenti") {
                    ShareLink(item: URL(string: "https://apps.apple.com/us/app/lavorami/id6760344298")!) {
                        Label("Condividi LavoraMi", systemImage: "arrowshape.turn.up.right.fill")
                    }
                    Button(action: {
                        Task {@MainActor in
                            requestReview()
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                        }
                    }){
                        Label {
                            Text("Valuta LavoraMi")
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "star.fill")
                        }
                    }
                    Button(action: {
                        showInfoMapDeviations = true
                    }){
                        Label {
                            Text("Info sulle Mappe")
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "location.fill")
                        }
                    }
                }
                Section(footer: Text("Le impostazioni vengono salvate automaticamente.")) {
                    Button(role: .destructive) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                        presentedAlertReset = true
                    } label: {
                        Label("Ripristina Impostazioni", systemImage: "arrow.counterclockwise")
                    }
                }
                Section() {} footer: {
                    HStack(spacing: 30) {
                            Spacer()
                            Link(destination: URL(string: "https://www.instagram.com/lavoramiapp/")!) {
                                Image("instagram")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                            Link(destination: URL(string: "https://www.tiktok.com/@lavoramiapp")!) {
                                Image("tiktok")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                            
                            Button {
                                let url = URL(string: "https://www.lavorami.it\((colorScheme == .dark) ? "?theme=dark" : "?theme=light")")!
                                
                                if(howToOpenLinks == .inApp) {
                                    selectedURL = url
                                }
                                else {
                                    openURLAction(url)
                                }
                            } label: {
                                Image(systemName: "network")
                                    .font(.system(size: 20))
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Impostazioni")
            .alert("Sei sicuro?", isPresented: $presentedAlertReset) {
                Button("Annulla", role: .cancel) { }
                Button("Continua", role: .destructive) {
                    enableNotifications = true
                    preferredFilter = .all
                    linesFavorites = []
                    linesSelected = []
                    showErrorMessages = false
                    showStrikeBanner = true
                    requireFaceID = true
                    howToOpenLinks = .inApp
                    appearanceSelection = .system
                    feedbacksEnabled = true
                    showTranslateButton = false
                    showRecentSearches = true
                    recentlySearchedLinesData = Data()
                    selectedWidgetLine = ""
                }
            } message: {
                Text("Sei sicuro di voler ripristinare le impostazioni?")
            }
            .alert("Errore di connessione", isPresented: $showErrorDBSavePopUp) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Si è verificato un errore di connessione durante il salvataggio delle linee preferite. Controlla la tua connessione ad Internet.")
            }
            .sheet(isPresented: $showInfoMapDeviations) {
                LineDeviationInfoView()
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea(.all)
            }
            .fullScreenCover(isPresented: $showWrapped, onDismiss: {
                hasOpenedWrapped = true
            }) {
                WrappedView()
            }
        }
    }
}
