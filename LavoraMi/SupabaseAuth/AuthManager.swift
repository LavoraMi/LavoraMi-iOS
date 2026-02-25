//
//  AuthManager.swift
//  LavoraMi
//
//  Created by Andrea Filice on 02/02/26.
//

import SwiftUI
import Supabase
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
            await signIn(email: email, password: password)
            do { self.session = try await supabase.auth.session } catch { }
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
            
            try await supabase.rpc("delete_self").execute()
            try await supabase.auth.signOut()
            
            self.session = nil
            print("Account eliminato definitivamente.")
            
        } catch {
            print("Errore durante l'eliminazione: \(error)")
            errorMessage = "Impossibile eliminare l'account: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func editPassword(password: String) async {
        do{
            try await supabase.auth.update(
                user: UserAttributes(
                    password: password
                )
            )
        }
        catch{
            print("Errore durante la modifica della Password.")
        }
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
}
