//
//  BiometricAuth.swift
//  LavoraMi
//
//  Created by Andrea Filice on 05/02/26.
//

import LocalAuthentication

struct BiometricAuth {

    static func authenticate(onSuccess: @escaping () -> Void, onFailure: @escaping (Error?) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Annulla"

        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            onFailure(error)
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Autenticazione richiesta"
        ) { success, authError in
            DispatchQueue.main.async {
                if success {
                    onSuccess()
                } else {
                    onFailure(authError)
                }
            }
        }
    }

    static func getBiometricType() -> BiometricType {
        let authContext = LAContext()
        
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }
        
        switch authContext.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
}

enum BiometricType {
    case none
    case touchID
    case faceID
}
