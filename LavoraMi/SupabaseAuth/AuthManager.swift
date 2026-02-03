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
            print("Registrazione effettuata. Controlla la mail!")
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
            // Fetch the current session immediately to update UI state
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
}

