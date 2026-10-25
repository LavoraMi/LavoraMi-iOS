//
//  TransportHelpers.swift
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

func getColor(for line: String) -> Color {
    switch line {
        ///SUBURBAN LINES
        case "S1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "S2": return Color(red: 0, green: 152/255, blue: 121/255)
        case "S3": return Color(red: 169/255, green: 10/255, blue: 46/255)
        case "S4": return Color(red: 131/255, green: 187/255, blue: 38/255)
        case "S5": return Color(red: 243/255, green: 145/255, blue: 35/255)
        case "S6": return Color(red: 246/255, green: 210/255, blue: 0)
        case "S7": return Color(red: 229/255, green: 0, blue: 113/255)
        case "S8": return Color(red: 246/255, green: 182/255, blue: 182/255)
        case "S9": return Color(red: 162/255, green: 51/255, blue: 138/255)
        case "S11": return Color(red: 165/255, green: 147/255, blue: 198/255)
        case "S12": return Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(white: 35/255, alpha: 1) : .black
        })
        case "S13": return Color(red: 167/255, green: 109/255, blue: 17/255)
        case "S19": return Color(red: 102/255, green: 13/255, blue: 54/255)
        case "S31": return Color(red: 180/255, green: 205/255, blue: 75/255)
        
        ///TILO LINES
        case "S10": return Color(red: 226/255, green: 15/255, blue: 26/255)
        case "S20": return Color(red: 0/255, green: 158/255, blue: 224/255)
        case "S30": return Color(red: 1/255, green: 144/255, blue: 54/255)
        case "S40": return Color(red: 120/255, green: 187/255, blue: 114/255)
        case "S50": return Color(red: 128/255, green: 79/255, blue: 16/255)
        case "S90": return Color(red: 254/255, green: 206/255, blue: 0/255)
        case "RE80": return Color(red: 1/255, green: 80/255, blue: 158/255)
        
        ///METRO LINES
        case "M1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "NM1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "BM1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "M2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "NM2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "BM2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "M3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "NM3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "BM3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "M4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "NM4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "BM4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "M5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        case "NM5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        case "BM5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        
        ///BUS LINES
        case _ where line.contains("z"): return Color(red: 28/255, green: 28/255, blue: 1)
        case _ where line.contains(String(localized: .filobus)): return Color(red: 101/255, green: 179/255, blue: 46/255)
        case _ where line.contains("P") && !(line.contains("MXP")): return Color(red: 69/255, green: 56/255, blue: 0)
        
        ///OTHER LINES
        case let s where s.hasPrefix("B") && (1...33).contains(Int(s.dropFirst()) ?? 0): return .orange
        case "MXP": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP1": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP2": return Color(red: 140/255, green: 0, blue: 118/255)
        case "SFM 6": return Color(red: 139/255, green: 35/255, blue: 29/255)
        case "REG": return Color(red: 226/255, green: 62/255, blue: 62/255)
        case "H": return Color(red: 226/255, green: 62/255, blue: 62/255)
        case "AV": return .red
        case "RV": return .red
        case String(localized: .aereoporto): return .cyan
        case "Monumento": return Color(red: 234/255, green: 223/255, blue: 201/255)
        case "Ospedale": return Color(red: 224/255, green: 88/255, blue: 79/255)
        case _ where line.contains("R") && !line.contains("RE"): return Color.blue
        case _ where line.contains("RE") && !line.contains("REG"): return Color.red
        case let s where (1...33).contains(Int(s) ?? 0): return .orange
        case _ where line.starts(with: "N"): return Color(red: 2/255, green: 27/255, blue: 129/255)
        
        ///FALLBACK CASE
        default: return Color(red: 90/255, green: 180/255, blue: 85/255)
    }
}

func getCurrentTransportIcon(for lineLongName: String) -> String{
    switch(lineLongName){
        case "Suburbano":
            return "train.side.front.car"
        case "TILO":
            return "train.side.front.car"
        case "Malpensa Express":
            return "train.side.front.car"
            
        case "Metro":
            return "tram.tunnel.fill"
            
        case "Autoguidovie":
            return "bus.fill"
        case "STAV":
            return "bus.fill"
        case "STAR Mobility":
            return "bus.fill"
        case "NET":
            return "bus.fill"
        case "Movibus":
            return "bus.fill"
            
        case String(localized: .filobus):
            return "bus.fill"
        case String(localized: .tram):
            return "tram.fill"
        
        default:
            return "train.side.front.car"
    }
}

func getIconForFilter(for filterName: String) -> String{
    switch(filterName){
        case "Le tue linee":
            return "sparkle"
        case "Tutti":
            return "line.3.horizontal.decrease"
        case "Bus":
            return "bus.fill"
        case "Tram":
            return "tram.fill"
        case "Metropolitana":
            return "tram.tunnel.fill"
        case "Treno":
            return "train.side.front.car"
        case "In Corso":
            return "clock.badge.exclamationmark.fill"
        case "Programmati":
            return "calendar.badge.clock"
            
        default:
            return ""
    }
}

func isLineTILO(lineName: String) -> Bool {
    return (lineName == "S10" || lineName == "S20" || lineName == "S30" || lineName == "S40" || lineName == "S50" || lineName == "S90" || lineName == "RE80")
}
