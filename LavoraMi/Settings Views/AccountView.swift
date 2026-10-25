//
//  AccountView.swift
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

struct AccountView: View {
    @StateObject var auth: AuthManager
    @State private var email: String = ""
    @State private var emailRecoverPassword: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    @State private var tabTitle: String = ""
    @State private var isLogginIn: Bool = true
    @State private var loggedIn: Bool = false
    @State private var resettingPassword: Bool = false
    @State private var passwordResetted: Bool = false
    @State private var popUpVerifyMail: Bool = false
    @State private var showError: Bool = false
    @State private var showDeletePopUp: Bool = false
    @State private var showDataManagementPopUp: Bool = false
    @State private var showEditPasswordPopUp: Bool = false
    @State private var showErrorDBSavePopUp: Bool = false
    @State private var showConfirmToExitPopUp: Bool = false
    @State private var isLocked: Bool = true
    @State private var text: String = ""
    @State private var selectedURL: URL?
    @State private var isBiometricAuthCompleted: Bool = false
    @State private var showMailApple: Bool = false
    @State private var logginIn: Bool = false
    @State var isRequiringData: Bool = false
    @State var saveFavoritesData = true
    @State var saveYourLinesData = true
    @State private var currentNonce: String?
    @State private var currentSyncStatus: String = String(localized: .sincronizzazione)
    @State private var currentSyncStatusIcon: String = "cloudSyncing"
    @State private var showPopUpNotSynched: Bool = false
    @State private var newUsername: String = ""
    @State private var showChangeUsernamePopUp: Bool = false
    @State private var showAddUsernamePopUp: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURLAction
    
    @AppStorage("requireFaceID") var requireFaceID: Bool = true
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("emailSaved") var emailSaved: String = ""
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    if isLogginIn && !loggedIn && !resettingPassword {loginSection}
                    if !isLogginIn && !loggedIn && !resettingPassword {signUpSection}
                    if loggedIn && !resettingPassword {loggedInSection}
                    if resettingPassword {resetPasswordSection}
                }
                .padding(25)
            }
            .blur(radius: isLocked ? 12 : 0)
            .animation(.easeInOut(duration: 0.25), value: isLocked)
            .allowsHitTesting(!isLocked)
            .onAppear(perform: handleOnAppear)
            .alert("Sei sicuro?", isPresented: $showConfirmToExitPopUp) {
                Button("Annulla", role: .cancel) { }
                Button("Conferma", role: .destructive, action: performSignOut)
            } message: {
                Text("Sei sicuro di voler uscire dall'account?")
            }
            .alert("Errore di connessione", isPresented: $showErrorDBSavePopUp) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Si è verificato un errore di connessione durante il salvataggio delle linee preferite. Riprova più tardi.")
            }
            .navigationTitle(tabTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea(.all)
            }
            .sheet(isPresented: $showDataManagementPopUp) {
                AccountDatasInfoView(authManager: auth, saveFavoritesData: saveFavoritesData, saveYourLinesData: saveYourLinesData, currentSyncStatus: $currentSyncStatus, currentSyncStatusIcon: $currentSyncStatusIcon)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var loginSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bentornato")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Accedi al tuo Account per continuare.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 40)

            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.gray)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 15) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.gray)
                    SecureField("Password", text: $password)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack {
                    Spacer()
                    Button("Password dimenticata?") {
                        resettingPassword = true
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                    
                    Button(action: { isLogginIn = false }) {
                        Text("Non hai un account?")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            if let err = auth.errorMessage, !err.isEmpty {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            termsAndPrivacyView
            appleSignInLoginButton
            loginButton
        }
    }
    
    private var signUpSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text("Crea account")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Registrati per iniziare.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 40)

            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Image(systemName: "at")
                        .foregroundStyle(.gray)
                    TextField("Nome utente", text: $fullName)
                        .textInputAutocapitalization(.words)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 15) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.gray)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 15) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.gray)
                    SecureField("Password", text: $password)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                HStack{
                    Spacer()
                    Button(action: { isLogginIn = true }) {
                        Text("Hai già un account?")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            if let err = auth.errorMessage, !err.isEmpty {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            termsAndPrivacyView
            appleSignInSignUpButton
            signUpButton
        }
    }
    
    private var loggedInSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 20) {
                Text("👋 Ciao \(fullName)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                Text("Qui puoi gestire il tuo Account e le tue informazioni.")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .padding(.top, -8)
                
                Section("Informazioni") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "at")
                                .foregroundStyle(.red)
                                .font(.system(size: 25))
                            
                            Text(fullName)
                                .foregroundColor(Color("TextColor"))
                                .font(.system(size: 25))
                            
                            Button(action: {
                                showChangeUsernamePopUp = true
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if email.contains("privaterelay") {
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill.viewfinder")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 25))
                                
                                Text("ID: \(email.prefix(while: {$0 != "@"}))")
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25))
                            }
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 25))
                                
                                Text(email)
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25))
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Image(currentSyncStatusIcon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundStyle(.red)
                            
                            if(currentSyncStatus.contains(String(localized: .sincronizzazione))){
                                ProgressView()
                                    .foregroundStyle(.red)
                            }
                            
                            Text(currentSyncStatus)
                                .foregroundColor(Color("TextColor"))
                                .font(.system(size: 25))
                            
                            if(currentSyncStatus.contains(String(localized: .nonSincronizzato))) {
                                Button(action: {
                                    showPopUpNotSynched = true
                                }) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            if(currentSyncStatus.contains(String(localized: .erroreSincronizzato))) {
                                Button(action: {
                                    currentSyncStatus = String(localized: .sincronizzazione)
                                    currentSyncStatusIcon = "cloudSyncing"
                                    handleOnAppear()
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        if auth.isLoggedInWithApple() {
                            HStack(spacing: 12) {
                                Image(systemName: "apple.logo")
                                    .foregroundStyle(Color("TextColor"))
                                    .font(.system(size: 25))
                                
                                Text("Account creato con Apple")
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25))
                            }
                        }
                    }
                }
                .foregroundStyle(.gray)
                
                manageSection
                .sheet(isPresented: $showChangeUsernamePopUp) {
                    ChangeUsernameView(auth: auth, fullName: $fullName)
                }
                .alert("Sei sicuro?", isPresented: $showDeletePopUp) {
                    Button("Annulla", role: .cancel) { }
                    Button("Continua", role: .destructive, action: performAccountDeletion)
                } message: {
                    Text("Sei sicuro di voler Eliminare Definitivamente il tuo Account?")
                }
                .alert("Modifica Password", isPresented: $showEditPasswordPopUp) {
                    Button("Annulla", role: .cancel) { }
                    Button("Continua", role: .destructive) {
                        Task { await auth.requestPasswordReset(email: email) }
                    }
                } message: {
                    Text("Ti invieremo una mail per modificare la tua password, vuoi continuare?")
                }
                .foregroundStyle(.gray)
                .alert("Dati non Sincronizzati", isPresented: $showPopUpNotSynched) {
                    Button("Chiudi", role: .cancel) { }
                } message: {
                    Text("Hai scelto di non sincronizzare i dati del tuo Account attraverso la funzione \"Preferenze Dati\". Per sincronizzarli, attiva almeno una delle opzioni disponibili.")
                }
                .alert("Inserisci Nome Utente", isPresented: $showAddUsernamePopUp) {
                    TextField("Nome utente", text: $newUsername)
                    Button("Continua") {
                        Task {
                            do {
                                if(!newUsername.isEmpty) {
                                    try await auth.updateUserName(newUserName: newUsername)
                                    fullName = newUsername
                                    newUsername = ""
                                    showChangeUsernamePopUp = false
                                }
                            }
                            catch {}
                        }
                    }
                    .disabled(newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } message: {
                    Text("Il tuo Account non ha un nome utente, inseriscine uno.")
                }
                
                Spacer()

                Button(role: .destructive, action: { showConfirmToExitPopUp = true }) {
                    Label("Esci", systemImage: "rectangle.portrait.and.arrow.right.fill")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5, y: 3)
                }
            }
            .onAppear(perform: populateUserData)
        }
    }
    
    private var manageSection: some View {
        Section("Gestisci") {
            VStack(spacing: 8) {
                if !auth.isLoggedInWithApple() {
                    Button(role: .destructive, action: { showEditPasswordPopUp = true }) {
                        Label("Modifica Password", systemImage: "lock.fill")
                            .font(.system(size: 15))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 5, y: 3)
                    }
                }
                Button(role: .destructive, action: { showDeletePopUp = true }) {
                    Label("Elimina Account", systemImage: "trash.fill")
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5, y: 3)
                }
                
                Button(role: .destructive, action: { showDataManagementPopUp = true }) {
                    Label {
                        Text("Preferenze Dati")
                    } icon: {
                        Image("cloudManage")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .foregroundStyle(.white)
                    }
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5, y: 3)
                }
                
                NavigationLink(destination: RequestDataDownload(isRequiringData: $isRequiringData)) {
                    Label("Richiedi i tuoi dati", systemImage: "person.and.background.dotted")
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5, y: 3)
                }
            }
        }
    }
    
    private var resetPasswordSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reset Password")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Recupera qui la Password del tuo Account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 40)
            
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.gray)
                    TextField("Email", text: $emailRecoverPassword)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            HStack{
                Spacer()
                Button(action: {
                    isLogginIn = true
                    resettingPassword = false
                    passwordResetted = false
                }){
                    Text("Torna al Login")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.top, -10)
            
            Spacer()
            
            Button(role: .destructive, action: performPasswordResetRequest) {
                Label("Invia Email", systemImage: "paperplane.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((!validateEmail(emailRecoverPassword)) ? Color.gray.opacity(0.5) : Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5, y: 3)
            }
            .disabled(!validateEmail(emailRecoverPassword))
            .alert("Email inviata!", isPresented: $passwordResetted) {
                Button("Chiudi", role: .cancel) {
                    resettingPassword = false
                    passwordResetted = false
                }
            } message: {
                Text("Email inviata a \(emailRecoverPassword)!")
            }
        }
    }
    
    private var termsAndPrivacyView: some View {
        HStack(spacing: 0) {
            Text("Continuando, accetti i ")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                let url = URL(string: "https://www.lavorami.it/termsofservice\((colorScheme == .dark) ? "" : "?theme=light")")!
                if howToOpenLinks == .inApp {
                    selectedURL = url
                } else {
                    openURLAction(url)
                }
            } label: {
                Text("Termini")
                    .font(.subheadline)
            }
            
            Text(" e la ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                let url = URL(string: "https://www.lavorami.it/privacypolicy\((colorScheme == .dark) ? "" : "?theme=light")")!
                if howToOpenLinks == .inApp {
                    selectedURL = url
                } else {
                    openURLAction(url)
                }
            } label: {
                Text("Privacy Policy.")
                    .font(.subheadline)
            }
        }
    }
    
    private var appleSignInLoginButton: some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
        } onCompletion: { result in
            handleAppleSignInCompletion(result: result)
        }
        .signInWithAppleButtonStyle((colorScheme == .dark) ? .whiteOutline : .black)
        .frame(height: 50)
        .cornerRadius(16)
    }
    
    private var appleSignInSignUpButton: some View {
        SignInWithAppleButton(.signUp) { request in
            let nonce = randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
        } onCompletion: { result in
            handleAppleSignInCompletion(result: result)
        }
        .signInWithAppleButtonStyle((colorScheme == .dark) ? .whiteOutline : .black)
        .frame(height: 50)
        .cornerRadius(16)
    }
    
    private var loginButton: some View {
        Button(action: performLogin) {
            HStack {
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Label(auth.isLoading ? "Accedo..." : "Accedi", systemImage: "arrow.up.forward.app.fill")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background((!validateUserInputs(email: email, password: password) || logginIn) ? Color.gray.opacity(0.5) : Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 5, y: 3)
        }
        .disabled(!validateUserInputs(email: email, password: password) || auth.isLoading || logginIn)
    }
    
    private var signUpButton: some View {
        Button(action: performSignUp) {
            HStack {
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Label(auth.isLoading ? "Registrazione..." : "Registrati", systemImage: "rectangle.portrait.and.arrow.right.fill")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background((!validateUserInputs(email: email, password: password) || isLogginIn) ? Color.gray.opacity(0.5) : Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 5, y: 3)
        }
        .disabled(!validateUserInputs(email: email, password: password) || auth.isLoading)
        .alert("Conferma Mail", isPresented: $popUpVerifyMail) {
            Button("Chiudi", role: .cancel) {
                popUpVerifyMail = false
                isLogginIn = true
            }
        } message: {
            Text("Verifica il tuo indirizzo Email con la mail che ti abbiamo inviato per continuare.")
        }
    }
    
    private func handleOnAppear() {
        loggedIn = auth.isLoggedIn()
        if loggedIn {
            if fullName.isEmpty { fullName = auth.getFullName() }
            if email.isEmpty, let sess = auth.session {email = sess.user.email ?? email}
            
            Task {
                do {
                    let res: UserPreferencesDatas = try await auth.fetchUserPreferencesAccount()
                    
                    if res.enable_favorites {
                        currentSyncStatus = String(localized: .sincronizzato)
                        currentSyncStatusIcon = "cloudSynced"
                        linesFavorites = try await auth.fetchUserFavorites()
                    } else {
                        currentSyncStatus = String(localized: .erroreSincronizzato)
                        currentSyncStatusIcon = "cloudFailSync"
                    }
                    
                    if res.enable_your_lines {
                        linesSelected = try await auth.fetchUserLines()
                    }
                    
                    if(!res.enable_favorites && !res.enable_your_lines){
                        currentSyncStatus = String(localized: .nonSincronizzato)
                        currentSyncStatusIcon = "cloudDisabled"
                    }
                    
                } catch {
                    currentSyncStatus = String(localized: .erroreSincronizzato)
                    currentSyncStatusIcon = "cloudFailSync"
                }
            }
            
            tabTitle = "Account"
        }
        if requireFaceID && loggedIn && !isRequiringData && !isBiometricAuthCompleted {
            BiometricAuth.authenticate {
                isLocked = false
            } onFailure: { error in
                dismiss()
            }
            isBiometricAuthCompleted = true
        } else {
            isLocked = false
            isRequiringData = false
            isBiometricAuthCompleted = true
        }
    }
    
    private func populateUserData() {
        if fullName.isEmpty { fullName = auth.getFullName() }
        if email.isEmpty, let sess = auth.session {
            email = sess.user.email ?? email
            Task {
                do {
                    linesFavorites = try await auth.fetchUserFavorites()
                    linesSelected = try await auth.fetchUserLines()
                    try await auth.saveUserPreferences(enableFavorites: saveFavoritesData, enableYourLines: saveYourLinesData)
                    
                    currentSyncStatus = String(localized: .sincronizzato)
                    currentSyncStatusIcon = "cloudSynced"
                }
                catch {
                    currentSyncStatus = String(localized: .erroreSincronizzato)
                    currentSyncStatusIcon = "cloudFailSync"
                }
            }
        }
        
        if(auth.getFullName().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || auth.getFullName().contains("User")){showAddUsernamePopUp = true}
        
        emailSaved = email
    }
    
    private func performLogin() {
        logginIn = true
        Task {
            await auth.signIn(email: email, password: password)
            
            if auth.isLoggedIn() {
                if fullName.isEmpty { fullName = auth.getFullName() }
                if email.isEmpty, let sess = auth.session { email = sess.user.email ?? email }
                
                do {
                    linesFavorites = try await auth.fetchUserFavorites()
                    linesSelected = try await auth.fetchUserLines()
                    currentSyncStatus = String(localized: .sincronizzato)
                    currentSyncStatusIcon = "cloudSynced"
                }
                catch {
                    currentSyncStatus = String(localized: .erroreSincronizzato)
                    currentSyncStatusIcon = "cloudFailSync"
                }
                
                self.loggedIn = true
            }
            
            tabTitle = "Account"
            logginIn = false
        }
    }
    
    private func performSignUp() {
        logginIn = true
        Task {
            await auth.signUp(email: email, password: password, name: fullName)
            popUpVerifyMail = auth.errorMessage == nil
            logginIn = false
            tabTitle = "Account"
        }
    }
    
    private func performSignOut() {
        Task {
            loggedIn = false
            isLogginIn = true
            email = ""
            password = ""
            fullName = ""
            tabTitle = ""
            await auth.signOut()
        }
    }
    
    private func performAccountDeletion() {
        Task {
            email = ""
            password = ""
            fullName = ""
            loggedIn = false
            isLogginIn = true
            await auth.deleteAccount()
        }
    }
    
    private func performPasswordResetRequest() {
        Task {
            await auth.requestPasswordReset(email: emailRecoverPassword)
            passwordResetted = true
        }
    }
    
    private func handleAppleSignInCompletion(result: Result<ASAuthorization, Error>) {
        Task {
            logginIn = true
            switch result {
            case .failure(let error):
                print("Apple Sign In error: \(error)")
                logginIn = false
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let idTokenData = credential.identityToken,
                      let idToken = String(data: idTokenData, encoding: .utf8),
                      let nonce = currentNonce
                else {
                    logginIn = false
                    return
                }
                
                var newNameFromApple: String? = nil
                if let personName = credential.fullName {
                    let given = personName.givenName ?? ""
                    let family = personName.familyName ?? ""
                    let composed = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
                    if !composed.isEmpty {
                        newNameFromApple = composed
                    }
                }
                
                await auth.signInWithApple(nonce: nonce, idToken: idToken, fullName: newNameFromApple)
                fullName = auth.getFullName()
                loggedIn = auth.isLoggedIn()
                logginIn = false
                tabTitle = "Account"
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func validateEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func validateUserInputs(email: String, password: String) -> Bool {
        return password.count >= 8 && validateEmail(email)
    }
}
