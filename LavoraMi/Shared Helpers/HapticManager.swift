//
//  HapticManager.swift
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

struct HapticManager {
    static let shared = HapticManager()
    private let generator = UIImpactFeedbackGenerator(style: .light)
        
    func trigger() {
        generator.prepare()
        generator.impactOccurred()
    }
}
