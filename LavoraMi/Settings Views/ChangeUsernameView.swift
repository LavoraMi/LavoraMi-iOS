//
//  ChangeUsernameView.swift
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

struct ChangeUsernameView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var startImageTransition: Bool = false
    @StateObject var auth: AuthManager
    
    @State var newUsername: String = ""
    @State var isLoading: Bool = true
    @State var focused: Bool = false
    @Binding var fullName: String
    @AppStorage("enableAnimations") var enableAnimations = true
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Image(systemName: "at")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.red)
                        .padding(.top, 40)

                    Text("Modifica Nome Utente")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("Inserisci un nuovo nome utente per il tuo Account.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("I tuoi dati di LavoraMi sono completamente privati e protetti, potrai richiederli quando vuoi selezionando \"Richiedi i tuoi dati\".")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "at")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.gray)
                        
                        TextField("Nome Utente", text: $newUsername)
                            .textInputAutocapitalization(.words)
                            .keyboardType(.alphabet)
                            .keyboardShortcut(.end)
                            .disabled(auth.isLoading)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .background(
                        colorScheme == .dark ? Color(UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)) : Color(UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    Button {
                        Task {
                            do {
                                try await auth.updateUserName(newUserName: newUsername)
                                fullName = newUsername
                                presentationMode.wrappedValue.dismiss()
                                newUsername = ""
                            }
                            catch {}
                        }
                    } label: {
                        Text("Continua")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(isUsernameValid() ? Color.gray : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.top, 10)
                    .disabled(isUsernameValid())
                    
                    if(newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        Text("Il Nome Utente non può essere vuoto.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, -15)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    else if(newUsername.trimmingCharacters(in: .whitespacesAndNewlines) == fullName.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        Text("Il nuovo Nome Utente non può essere uguale al tuo Nome Utente attuale.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, -15)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    else if(newUsername.trimmingCharacters(in: .whitespacesAndNewlines).count < 3) {
                        Text("Il Nome Utente non può contenere meno di 3 caratteri.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, -15)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Personalizza")
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
        }
    }

    private func dismiss() {
        fullName = fullName
        presentationMode.wrappedValue.dismiss()
    }
    
    private func isUsernameValid() -> Bool {
        /// This method is a refactor one and check if the new Username of the user is valid and can be saved into the Database.
        /// - Returns: A boolean value based from 3 rules: 1) Username cannot be empty, 2) Username can't be equal to the old username, 3) Minimum characters of the new username: 3
        return newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newUsername.trimmingCharacters(in: .whitespacesAndNewlines) == fullName.trimmingCharacters(in: .whitespacesAndNewlines) || (newUsername.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
    }
}
