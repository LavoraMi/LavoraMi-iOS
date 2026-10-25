//
//  Enums.swift
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

//MARK: UTILITIES
//NOTE: FILTERS
enum FilterBy: String, CaseIterable, Identifiable {
    case suggested = "Le tue linee"
    case all = "Tutti"
    case bus = "Bus"
    case tram = "Tram"
    case metro = "Metropolitana"
    case train = "Treno"
    case working = "In Corso"
    case scheduled = "Programmati"
    case ATM = "di ATM"
    case Trenord = "di Trenord"
    case Tilo = "di TILO"
    case Movibus = "di Movibus"
    case Net = "di NET"
    case STAV = "di STAV"
    case STAR = "di STAR"
    case Autoguidovie = "di Autoguidovie"
    
    var localizedTitle: String {
        switch self {
            case .suggested: return String(localized: .yourLinesChip)
            case .all: return String(localized: .tutti)
            case .bus: return String(localized: .bus)
            case .tram: return String(localized: .tram)
            case .metro : return String(localized: .metropolitana)
            case .train: return String(localized: .treno)
            case .working: return String(localized: .inCorso)
            case .scheduled: return String(localized: .programmati)
            case .ATM: return String(localized: .diAtm)
            case .Trenord: return String(localized: .diTrenord)
            case .Tilo: return String(localized: .diTilo)
            case .Movibus: return String(localized: .diMovibus)
            case .Net: return String(localized: .diNET)
            case .STAV: return String(localized: .diStav)
            case .STAR: return String(localized: .diStar)
            case .Autoguidovie: return String(localized: .diAutoguidovie)
        }
    }
    
    var id: String{self.rawValue}
}

enum AppearanceType: Int, CaseIterable, Identifiable {
    case system = 0
    case dark = 1
    case light = 2
    
    var description: String {
        switch self {
            case .system: return String(localized: .sistema)
            case .light: return String(localized: .chiaro)
            case .dark: return String(localized: .scuro)
        }
    }
    
    var iconName: String {
        switch self {
            case .system: return "gear"
            case .dark: return "moon.fill"
            case .light: return "sun.max.fill"
        }
    }
    
    var id: Int{self.rawValue}
}

enum linkOpenTypes: String, CaseIterable, Identifiable{
    case inApp = "In App"
    case safari = "Safari"
    
    var id: String{self.rawValue}
    var localizedID: String {
        switch self {
            case .inApp: return String(localized: .inAppLocalized)
            case .safari: return "Safari"
        }
    }
}

enum fileFormatType: String, CaseIterable, Identifiable{
    case json = "Json"
    case html = "HTML"
    
    var id: String{self.rawValue}
}
