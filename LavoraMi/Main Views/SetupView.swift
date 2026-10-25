//
//  SetupView.swift
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

struct SetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    @State private var currentPage = 0
    @State private var showPopUpConfirmSkipSetup: Bool = false
    @StateObject private var locationManager = LocationManager()
    
    let pages = [
        SetupPage(
            title: "Benvenuto su LavoraMi",
            description: "Tieniti informato. Prima e durante il tuo viaggio.",
            transitionImage: "1",
            standardImage: "1",
            fallbackImage: "lightrail.fill"
        ),
        SetupPage(
            title: "Pianifica il Viaggio",
            description: "Pianifica il tuo viaggio sapendo dei disagi sul tragitto, ben prima di partire.",
            transitionImage: "mappin",
            standardImage: "mappin.and.ellipse"
        ),
        SetupPage(
            title: "Tieni sott'occhio i lavori",
            description: "Seleziona una linea da poter mostrare nel Widget per tenerla sempre sott'occhio.",
            transitionImage: "star.fill",
            standardImage: "widget.small",
            fallbackImage: "star.fill"
        ),
        SetupPage(
            title: "Tieniti Aggiornato",
            description: "Attiva le notifiche per rimanere al passo coi lavori. Senza perderti sorprese.",
            transitionImage: "bell.slash.fill",
            standardImage: "bell.fill"
        ),
        SetupPage(
            title: "Traduci i lavori, nella lingua che vuoi tu.",
            description: "Traduci i dettagli dei lavori in altre lingue, basta cliccare sui dettagli del lavoro e cliccare \"Traduci\".",
            transitionImage: "text.append",
            standardImage: "translate"
        ),
        SetupPage(
            title: "Non perderti Mai.",
            description: "Attiva la posizione per sapere sempre dove sei e non perdere mai la tua fermata.",
            transitionImage: "map.fill",
            standardImage: "location.fill"
        ),
        SetupPage(
            title: "Accessibile, sempre.",
            description: "Guarda se una linea è completamente, parzialmente o per nulla accessibile. Tutto a colpo d'occhio.",
            transitionImage: "person.fill",
            standardImage: "figure.roll"
        ),
        SetupPage(
            title: "Tu ed ancora Tu.",
            description: "I tuoi dati sono al sicuro. Crea un Account per registrarti al nostro club LavoraMi.",
            transitionImage: "lock.open.fill",
            standardImage: "lock.fill"
        ),
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0 ..< pages.count, id: \.self) { index in
                        SetupPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { oldPage, newPage in
                    if newPage == 3 {
                        NotificationManager.shared.requestPermission()
                    }
                    if newPage == 5 {
                        locationManager.requestPermission()
                    }
                }
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color("TextColor") : Color.gray.opacity(0.4))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 8)
                Spacer()
                if currentPage == pages.count - 1 {
                    Button {
                        hasNotCompletedSetup = false
                        dismiss()
                    } label: {
                        Text("Fine")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                } else {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("Avanti")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle(Text("LavoraMi"))
            .toolbar {
                if(currentPage != pages.count - 1) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showPopUpConfirmSkipSetup = true
                        } label: {
                            Text("Salta")
                        }
                    }
                }
            }
            .alert("Sei sicuro?", isPresented: $showPopUpConfirmSkipSetup){
                Button("Annulla", role: .cancel) { }
                Button("Continua", role: .destructive) {
                    hasNotCompletedSetup = false; dismiss()
                }
            } message: {
                Text("Sei sicuro di voler saltare la configurazione?")
            }
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
        NotificationManager.shared.requestPermission()
        locationManager.requestPermission()
    }
}

struct SetupPage {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let transitionImage: String
    let standardImage : String
    var fallbackImage: String? = nil
}

struct SetupPageView: View {
    @State var startImageTransition : Bool = false
    @State var imageTransitionFirstPage: Bool = false
    @State var i = 0
    @AppStorage("enableAnimations") var enableAnimations = true
    let page: SetupPage

    var body: some View {
        VStack(spacing: 30) {
            if #available(iOS 18.0, *), enableAnimations {
                if(page.standardImage != "1") {
                    Image(systemName: (startImageTransition) ? page.standardImage : page.transitionImage)
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .padding(.top, 50)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                        .onAppear{
                            Task{
                                try? await Task.sleep(for: .seconds(1))
                                withAnimation{
                                    startImageTransition = true
                                }
                            }
                        }
                        .onDisappear{
                            startImageTransition = false
                        }
                }
                else {
                    let images = ["tram.fill", "tram.fill.tunnel", "lightrail.fill", "bus.fill"]

                    Image(systemName: images[i])
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .padding(.top, 50)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                        .onAppear {
                            imageTransitionFirstPage = true
                            Task {
                                while imageTransitionFirstPage {
                                    try? await Task.sleep(for: .seconds(1))
                                    withAnimation {
                                        i = (i + 1) % images.count
                                    }
                                }
                            }
                        }
                        .onDisappear(){
                            imageTransitionFirstPage = false
                        }
                }
            }
            else{
                Image(systemName: page.fallbackImage ?? page.standardImage)
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.top, 50)
            }

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if(page.title == "Tu ed ancora Tu."){
                Text("Creando un Account LavoraMi, accetti i Termini di Servizio e la Privacy Policy. Vai in Impostazioni > Account per saperne di più.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            else if(page.title == "Traduci i lavori, nella lingua che vuoi tu."){
                Text("Per attivare questa Funzionalità anche in lingua Italiana, Vai in Impostazioni > Opzioni Avanzate ed attiva \"Mostra Pulsante Traduci\".")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }
}
