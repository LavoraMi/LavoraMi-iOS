//
//  InfoView.swift
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

struct InfoView: View {
    let device = UIDevice.current
    
    @Environment(\.openURL) private var openURLAction
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @State private var selectedURL: URL?
    @State private var mailData: ComposeMailData = ComposeMailData(subject: String(localized: .titoloBugReport), recipients: ["support@lavorami.it"], message: "", attachments: nil)
    @State private var mailDataInfoReport: ComposeMailData = ComposeMailData(subject: String(localized: .mailInformazioni), recipients: ["report-incorrettezze@lavorami.it"], message: "", attachments: nil)
    @State private var showMailView: Bool = false
    @State private var showMailViewReport: Bool = false
    
    var body: some View {
        Section{
            HStack{
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("LavoraMi")
                    .font(.system(size: 35))
                    .bold()
            }
            .padding(.bottom, 10)
            Text("\(Bundle.main.shortVersion) (Build \(Bundle.main.buildVersion))")
            Divider()
                .padding(.top, 10)
            ScrollView{
                Section(){
                    Text("Fonti Dati")
                        .font(.system(size: 30))
                        .bold()
                    Text("Questa applicazione aggrega dati pubblici, accessibili a tutti, per facilitarne la consultazione.")
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .italic()
                    Text("""
                    LavoraMi è un'applicazione indipendente sviluppata da terze parti e NON è in alcun modo affiliata, supportata, autorizzata o sponsorizzata da ATM S.p.A., Trenord S.r.l., Gruppo FNM, RFI o altri enti di trasporto citati.

                    Tutti i dati visualizzati in questa applicazione (orari, stati del servizio, avvisi) sono raccolti da fonti pubbliche al solo scopo di migliorarne la comprensione ed a solo scopo informativo.
                    
                    Non si fornisce alcuna garanzia, esplicita o implicita, riguardo l'accuratezza, la completezza, l'affidabilità o la tempestività delle informazioni fornite. Le informazioni potrebbero non riflettere variazioni dell'ultimo minuto.

                    L'uso dell'applicazione è interamente a proprio rischio. Lo sviluppatore declina ogni responsabilità per eventuali inesattezze, ritardi, mancati servizi, danni diretti o indiretti derivanti dall'affidamento sulle informazioni fornite da questa app.
                    
                    Per le decisioni di viaggio critiche, si raccomanda di fare sempre riferimento ai canali ufficiali, agli annunci sonori e alla segnaletica presente in stazione.
                    
                    Tutti i marchi, i loghi e i nomi commerciali citati appartengono ai legittimi proprietari.
                    """)
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                }
                Divider()
                Section(){
                    VStack(spacing: 12){
                        Text("Team di Sviluppo")
                            .font(.system(size: 30))
                            .bold()
                            .padding(.top, 20)
                        
                        Text("Sviluppatore Principale:")
                            .font(.system(size: 20))
                        Text("Andrea Filice")
                            .bold()
                            .font(.system(size: 25))
                            .padding(.top, -5)
                        
                        Text("Sviluppatore iOS:")
                            .font(.system(size: 20))
                        Text("Andrea Filice")
                            .bold()
                            .font(.system(size: 25))
                            .padding(.top, -5)
                        
                        Text("Sviluppatori Android:")
                            .font(.system(size: 20))
                            .padding(.top, 20)
                        Text("Andrea Filice")
                            .bold()
                            .font(.system(size: 25))
                        Text("Alessandro Rebuscini")
                            .bold()
                            .font(.system(size: 25))
                        Text("Tommaso Ruggeri")
                            .bold()
                            .font(.system(size: 25))
                        
                        Text("Sviluppatori Web:")
                            .font(.system(size: 20))
                            .padding(.top, 20)
                        Text("Riccardo De Diana")
                            .bold()
                            .font(.system(size: 25))
                        Text("Simone Gallotti")
                            .bold()
                            .font(.system(size: 25))
                    }
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Seguici su")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    Button {
                        let url = URL(string: "https://www.instagram.com/lavoramiapp/")!
                        openURLAction(url)
                    } label: {
                        HStack{
                            Image("instagram")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("Instagram")
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.tiktok.com/@lavoramiapp")!
                        openURLAction(url)
                    } label: {
                        HStack{
                            Image("tiktok")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("TikTok")
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.facebook.com/profile.php?id=61593590085842")!
                        openURLAction(url)
                    } label: {
                        HStack{
                            Image("facebook")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("Facebook")
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Contatti")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    
                    Button {
                        showMailView = true
                    } label: {
                        Label("Segnala un bug", systemImage: "ladybug.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        showMailViewReport = true
                    } label: {
                        Label("Segnala Incorrettezze", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.lavorami.it\((colorScheme == .dark) ? "?theme=dark" : "?theme=light")")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Sito web", systemImage: "network")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    .sheet(isPresented: $showMailView) {
                        MailView(data: $mailData) { result in
                            print(result)
                        }
                    }
                    .sheet(isPresented: $showMailViewReport) {
                        MailView(data: $mailDataInfoReport) { result in
                            print(result)
                        }
                    }
                    Spacer()
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Informazioni")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    NavigationLink(destination: LibrariesView()) {
                        Label("Librerie Open-Source", systemImage: "books.vertical.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.lavorami.it/privacyPolicy\((colorScheme == .dark) ? "" : "?theme=light")")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Privacy Policy", systemImage: "lock.shield.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.lavorami.it/termsofservice\((colorScheme == .dark) ? "" : "?theme=light")")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Termini di Servizio", systemImage: "doc.text.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
                .ignoresSafeArea(.all)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
