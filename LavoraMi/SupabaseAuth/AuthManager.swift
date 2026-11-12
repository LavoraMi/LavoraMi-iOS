//
//  AuthManager.swift
//  LavoraMi
//
//  Created by Andrea Filice on 02/02/26.
//

import SwiftUI
@_spi(Experimental) import Supabase
import AuthenticationServices
import Combine

@MainActor
class AuthManager: ObservableObject {
    //VARIABLES
    @Published var session: Session?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(){
        Task{
            do{
                self.session = try await supabase.auth.session
            }
            catch{
                print("Nessuna sessione attiva attualmente.")
            }
        }
        
        Task {
            for await state in supabase.auth.authStateChanges {
                self.session = state.session
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let metadata: [String: AnyJSON] = ["full_name": .string(name)]
            
            _ = try await supabase.auth.signUp(email: email, password: password, data: metadata)
            print("Registrazione effettuata.")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await supabase.auth.signIn(email: email, password: password)
            self.session = try await supabase.auth.session
            print("Login effettuato!")
        } catch {
            errorMessage = "Errore login: \(error.localizedDescription)"
            self.session = nil
        }
        isLoading = false
    }
    
    func signInWithApple(nonce: String, idToken: String, fullName: String?) async {
        do {
            try await supabase.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idToken, nonce: nonce))
            
            //SETUP THE NAME OF THE ACCOUNT
            if let name = fullName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
                let metadata: [String: AnyJSON] = ["full_name": .string(name)]
                try await supabase.auth.update(user: UserAttributes(data: metadata))
                self.session = try await supabase.auth.session
            }
            
            self.session = try await supabase.auth.session
        }
        catch{
            print("Errore durante il login con Apple.")
        }
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.session = nil
        } catch {
            print("Errore nel logout: \(error)")
        }
    }
    
    func getFullName() -> String {
        guard let metadata = session?.user.userMetadata,
              let jsonValue = metadata["full_name"] else{
            return ""
        }
        
        if case .string(let name) = jsonValue {
            return name
        }
        
        return ""
    }
    
    func getInitialIconName() -> String {
        guard let metadata = session?.user.userMetadata,
              let jsonValue = metadata["full_name"] else { return "" }
        
        guard case .string(let name) = jsonValue else { return "" }
        
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        let initials = components.prefix(2).compactMap { component in
            component.first?.uppercased()
        }
        
        return initials.joined()
    }
    
    func setFullName(name: String){
        let metadata: [String: AnyJSON] = ["full_name": .string(name)]
        
        session?.user.userMetadata = metadata
    }
    
    func isLoggedIn() -> Bool{
        return session != nil
    }
    
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard session != nil else {
                errorMessage = "Nessun utente loggato."
                isLoading = false
                return
            }
            
            try await supabase.rpc("delete_self_dev_test").execute()
            try await supabase.auth.signOut()
            
            self.session = nil
            print("Account eliminato definitivamente.")
            
        } catch {
            print("Errore durante l'eliminazione: \(error)")
            errorMessage = "Impossibile eliminare l'account: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func requestPasswordReset(email: String) async {
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("Mail inviata correttamente!")
        }
        catch{
            print("Errore durante l'invio della mail.")
        }
    }
    
    private var passkeyCache: [String: PasskeyListItem] = [:]
    
    func signInWithPasskey(anchor: ASPresentationAnchor) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            _ = try await supabase.auth.signInWithPasskey(presentationAnchor: anchor)
            self.session = try await supabase.auth.session
            print("Login con passkey effettuato!")
        }
        catch {
            if AuthManager.isPasskeyCancellation(error) { return }
            print("Errore login con passkey: \(error)")
            errorMessage = AuthManager.passkeyMessage(for: error)
        }
    }
    
    func registerPasskey(anchor: ASPresentationAnchor) async throws {
        _ = try await supabase.auth.registerPasskey(presentationAnchor: anchor)
    }
    
    func listPasskeys() async throws -> [PasskeyInfo] {
        let items: [PasskeyListItem] = try await supabase.auth.listPasskeys()
        
        passkeyCache = [:]
        for item in items { passkeyCache["\(item.id)"] = item }
        
        return items
            .map { item in
                PasskeyInfo(
                    id: "\(item.id)",
                    name: (item.friendlyName as String?) ?? "",
                    createdAt: AuthManager.passkeyDate(item.createdAt),
                    lastUsedAt: AuthManager.passkeyDate(item.lastUsedAt)
                )
            }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }
    
    func renamePasskey(_ info: PasskeyInfo, to newName: String) async throws {
        guard let item = passkeyCache[info.id] else { return }
        _ = try await supabase.auth.renamePasskey(id: item.id, friendlyName: newName)
    }
    
    func deletePasskey(_ info: PasskeyInfo) async throws {
        guard let item = passkeyCache[info.id] else { return }
        try await supabase.auth.deletePasskey(id: item.id)
        passkeyCache[info.id] = nil
    }
    
    nonisolated static func isPasskeyCancellation(_ error: Error) -> Bool {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled { return true }
        let nsError = error as NSError
        return nsError.domain == ASAuthorizationError.errorDomain && nsError.code == ASAuthorizationError.canceled.rawValue
    }
    
    nonisolated static func passkeyMessage(for error: Error) -> String {
        let text = "\(error)"
        
        if text.contains("too_many_passkeys") { return "Troppe Passkeys registrate." }
        if text.contains("webauthn_credential_exists") { return "Passkey già presente per questo Dispositivo." }
        if text.contains("webauthn_credential_not_found") { return "Nessuna Passkey trovata per questo Account." }
        if text.contains("email_not_confirmed") { return "Conferma prima il tuo indirizzo email." }
        if text.contains("user_banned") { return "Questo Account non può accedere." }
        if text.contains("passkey_disabled") { return "L'accesso con Passkey non è attivo." }
        if text.contains("webauthn_verification_failed") { return "Verifica della Passkey non riuscita." }
        
        return "Si è verificato un problema. Riprova più tardi."
    }
    
    nonisolated private static func passkeyDate(_ value: Any?) -> Date? {
        if let date = value as? Date { return date }
        
        if let string = value as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) { return date }
            
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: string)
        }
        
        return nil
    }
    
    func isLoggedInWithApple() -> Bool {return session?.user.appMetadata["provider"]?.stringValue == "apple"}
    
    func saveDatasToDb(favorites: [String], yourLines: [String]) async -> Bool {
        let userEmail = session?.user.email
        let userPreferences = await fetchUserPreferences()
        
        let linesToSave = LinesFavoriteDatas(user_email: userEmail ?? "", lines: (userPreferences.enable_favorites) ? favorites : [], your_lines: (userPreferences.enable_your_lines) ? yourLines : [])
        
        let res = await inserDataToDb(linesToSave: linesToSave)
        
        return res
    }
    
    func inserDataToDb(linesToSave: LinesFavoriteDatas) async -> Bool {
        
        if(linesToSave.user_email.isEmpty){
            print("ERRORE: Email vuota.")
            return false
        }
            
        do {
            try await supabase
                .from("userDatas")
                .upsert(linesToSave)
                .execute()
            
            return true
        } catch {
            print("Errore durante l'upsert: \(error)")
            return false
        }
    }
    
    func fetchUserFavorites() async throws -> [String] {
        let userID = session?.user.email
        
        let response = try await supabase
            .from("userDatas")
            .select()
            .eq("user_email", value: userID)
            .execute()
        
        let decodedRows = try JSONDecoder().decode([LinesFavoriteDatas].self, from: response.data)
        
        return decodedRows.first?.lines ?? []
    }
    
    func fetchUserLines() async throws -> [String] {
        let userID = session?.user.email
        
        let response = try await supabase
            .from("userDatas")
            .select()
            .eq("user_email", value: userID)
            .execute()
        
        let decodedRows = try JSONDecoder().decode([LinesFavoriteDatas].self, from: response.data)
        
        return decodedRows.first?.your_lines ?? []
    }
    
    func saveUserPreferences(enableFavorites: Bool, enableYourLines: Bool) async throws {
        let userEmail = session?.user.email
        
        let dataToSave = UserPreferencesDatas(user_email: userEmail ?? "", enable_favorites: enableFavorites, enable_your_lines: enableYourLines)
        
        if(dataToSave.user_email.isEmpty){
            print("ERRORE: Email vuota.")
        }
            
        try await supabase
            .from("userPreferences")
            .upsert(dataToSave)
            .execute()
    }
    
    func fetchUserPreferences() async -> UserPreferencesDatas {
        let userID = session?.user.email
        
        do {
            let response = try await supabase
                .from("userPreferences")
                .select()
                .eq("user_email", value: userID)
                .execute()
            
            let decodedRows = try JSONDecoder().decode([UserPreferencesDatas].self, from: response.data)
            return decodedRows.first ?? UserPreferencesDatas(user_email: "", enable_favorites: true, enable_your_lines: true)
            
        } catch {
            print("Errore nel fetch dei dati: \(error)")
            return UserPreferencesDatas(user_email: "", enable_favorites: true, enable_your_lines: true) ///Fallback value
        }
    }
    
    func fetchUserPreferencesAccount() async throws -> UserPreferencesDatas {
        let userID = session?.user.email
        
        let response = try await supabase
            .from("userPreferences")
            .select()
            .eq("user_email", value: userID)
            .execute()
        
        let decodedRows = try JSONDecoder().decode([UserPreferencesDatas].self, from: response.data)
        return decodedRows.first ?? UserPreferencesDatas(user_email: "", enable_favorites: true, enable_your_lines: true)
    }
    
    func updateUserName(newUserName: String) async throws {
        try await supabase.auth.update(user: UserAttributes(
            data: [
                "full_name": .string(newUserName)
            ]
          )
       )
    }
}

struct LinesFavoriteDatas: Encodable, Decodable {
    let user_email: String
    let lines: [String]
    let your_lines: [String]
}

struct UserPreferencesDatas: Encodable, Decodable {
    let user_email: String
    let enable_favorites: Bool
    let enable_your_lines: Bool
}

struct PasskeyInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let createdAt: Date?
    let lastUsedAt: Date?
}
