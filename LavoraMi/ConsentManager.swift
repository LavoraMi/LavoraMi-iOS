//
//  ConsentManager.swift
//  LavoraMi
//
//  Created by Andrea Filice on 05/07/2026.
//

import Foundation
import Combine
import UserMessagingPlatform
import SwiftUI

class ConsentManager: NSObject, ObservableObject {
    @Published var isReady = false
    @Published var canRequestAds = false
    
    static let shared = ConsentManager()
    
    override init() {
        super.init()
    }
    
    func requestConsentInfoUpdate() {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Errore richiesta consenso: \(error.localizedDescription)")
                    self.isReady = true
                    self.canRequestAds = ConsentInformation.shared.canRequestAds
                    return
                }
                
                ConsentForm.loadAndPresentIfRequired(from: nil) { formError in
                    DispatchQueue.main.async {
                        if let formError = formError {
                            print("Errore form consenso: \(formError.localizedDescription)")
                        }
                        self.canRequestAds = ConsentInformation.shared.canRequestAds
                        self.isReady = true
                    }
                }
            }
        }
    }
    
    var isPrivacyOptionsRequired: Bool {
        return ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
    
    func presentPrivacyOptionsForm() {
        ConsentForm.presentPrivacyOptionsForm(from: nil) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Errore privacy options form: \(error.localizedDescription)")
                }
                self.canRequestAds = ConsentInformation.shared.canRequestAds
            }
        }
    }
}
