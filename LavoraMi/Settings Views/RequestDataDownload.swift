//
//  RequestDataDownload.swift
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

struct RequestDataDownload: View {
    @AppStorage("emailSaved") var emailSaved: String = ""
    
    @State private var mailData: ComposeMailData = ComposeMailData(subject: "Richiesta di Dati", recipients: ["support@lavorami.it"], message: "Buongiorno,\nVorrei richiedere l'invio dei miei dati in formato JSON dell'Account con mail: mail@mail.com", attachments: nil)
    @State private var showMailView: Bool = false
    @State private var selectedFileType: fileFormatType = .json
    
    @Binding var isRequiringData: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "person.and.background.dotted")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.red)
                    
                    Text("Richiedi i tuoi Dati")
                        .font(.system(size: 30, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Invia una richiesta al nostro Team per scaricare i tuoi dati.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            List{
                Section(footer: Text("Seleziona il formato in cui i tuoi dati verranno esportati.")){
                    Label("Formato del File:", systemImage: "arrow.down.doc.fill")
                        .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    Picker(selection: $selectedFileType, content: {
                        ForEach(fileFormatType.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                                .foregroundStyle(Color("TextColor"))
                        }
                    }, label: {
                        Text("")
                    })
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                }
            }
            Spacer()
            Button(action: {
                let localizedString = String(localized: .messaggioEmailDati(selectedFileType.rawValue, emailSaved))
                let formattedBody = localizedString.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\", with: "")
                mailData = ComposeMailData(subject: String(localized: .richiestaDeiDati), recipients: ["support@lavorami.it"], message: formattedBody, attachments: nil)
                showMailView = true
            }) {
                Label("Richiedi Dati", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red)
                    .foregroundStyle(.white)
                    .cornerRadius(16)
            }
            .sheet(isPresented: $showMailView) {
                MailView(data: $mailData) { result in
                    print(result)
                }
            }
        }
        .padding()
        .navigationTitle("Aiuto")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .onAppear{
            isRequiringData = true
        }
    }
}
