//
//  WorkItem.swift
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

struct WorkItem: Identifiable, Hashable, Codable {
    var id = UUID()
    
    let title: String
    let titleIcon: String
    let typeOfTransport: String
    let roads: String
    let lines: [String]
    let startDate: Date
    let endDate: Date
    let details: String
    let company: String
    
    enum CodingKeys: String, CodingKey {
        case title, titleIcon, typeOfTransport, roads, lines, startDate, endDate, details, company
    }
    
    var progress: Double {
        let now = Date()
        let total = endDate.timeIntervalSince(startDate)
        
        guard total > 0 else { return 1 }
        let elapsed = now.timeIntervalSince(startDate)
        let fraction = elapsed / total
        
        return min(max(fraction, 0), 1)
    }
}

extension WorkItem {
    func matchesFavorites(_ favorites: [String]) -> Bool {
        let transport = self.typeOfTransport.lowercased()
        
        let linesLower = self.lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        
        if favorites.contains("Bus") {
            let isRubberTire = transport.contains("bus") || transport.contains("autobus")
            let isMovibus = transport.contains("movibus") || linesLower.contains { $0.hasPrefix("z6") }
            let isNET = transport.contains("net") || linesLower.contains{ $0.hasPrefix("z3") }
            let isStavOrStar = transport.contains("stav") || linesLower.contains { $0.hasPrefix("z5") }
            let isAutoguidovie = transport.contains("autoguidovie") || linesLower.contains {
                $0.hasPrefix("z4") || $0.hasPrefix("z2")
            }
            
            if isRubberTire && !isMovibus && !isStavOrStar && !isAutoguidovie && !isNET {
                return true
            }
        }
        
        if favorites.contains("z6") {
            if transport.contains("movibus") { return true }
            if linesLower.contains(where: { $0.hasPrefix("z6") }) { return true }
        }
        
        if favorites.contains("z3") {
            if transport.contains("net") { return true }
            if linesLower.contains(where: { $0.hasPrefix("z3") }) { return true }
        }
        
        if favorites.contains("z55"){
            if transport.contains("stav") { return true }
            if linesLower.contains(where: { $0.hasPrefix("z55") || $0.hasPrefix("z56") }) { return true }
        }
        
        if favorites.contains("z50"){
            if transport.contains("star") { return true }
            if linesLower.contains(where: { $0.hasPrefix("z50") || $0.hasPrefix("z51") }) { return true }
        }
        
        if favorites.contains("Autoguidovie") {
            if transport.contains("autoguidovie") { return true }
            if linesLower.contains(where: {
                $0.hasPrefix("z4") || $0.hasPrefix("z2")
            }) {
                return true
            }
        }
        
        if favorites.contains("Tram") {
            let isTram = transport.contains("tram") && !transport.contains("tram.fill.tunnel") && !transport.contains("metro")
            if isTram { return true }
        }
        
        if favorites.contains("Metro") {
            let isMetro = transport.contains("tram.fill.tunnel") || transport.contains("metro")
            if isMetro { return true }
        }
        
        for workLine in self.lines {
            let cleanWorkLine = workLine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let upperLine = workLine.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            for fav in favorites {
                let cleanFav = fav.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if cleanWorkLine == cleanFav {
                    return true
                }
            }
            
            if favorites.contains("S") && upperLine.hasPrefix("S") && !isLineTILO(lineName: upperLine) {
                let suffix = upperLine.dropFirst()
                if !suffix.isEmpty && suffix.allSatisfy({ $0.isNumber }) {
                    return true
                }
            }
            
            if favorites.contains("R") && upperLine.hasPrefix("R") && !upperLine.hasPrefix("RE") {
                return true
            }
            
            if favorites.contains("RE") && upperLine.hasPrefix("RE") && !isLineTILO(lineName: upperLine) {
                return true
            }
            
            if(favorites.contains("Tilo") && isLineTILO(lineName: upperLine)) {
                return true
            }
        }
        
        return false
    }
    
    var isFinishedMoreThanOneDayAgo: Bool {
        let calendar = Calendar.current
        guard let dayDifference = calendar.dateComponents([.day], from: endDate, to: Date()).day else {
            return false
        }
        
        return dayDifference >= 1
    }
}
