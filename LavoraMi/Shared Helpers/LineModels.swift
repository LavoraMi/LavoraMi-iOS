//
//  LineModels.swift
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

struct LineInfo: Identifiable{
    let id = UUID()
    let name: String
    let branches: String
    let type: String
    let waitMinutes: String
    let stations: [MetroStation]
    let accessibilityStatus: String
}

struct LineShortInfo: Identifiable{
    let id = UUID()
    let name: String
}

struct InterchangeInfo: Identifiable {
    let id = UUID()
    let name: String
    let lines: [String]
    let typeOfInterchange: String
    let branch: String
    let lineOrder: Int

    init(name: String, lines: [String], typeOfInterchange: String, branch: String = "Main", lineOrder: Int = 0) {
        self.name = name
        self.lines = lines
        self.typeOfInterchange = typeOfInterchange
        self.branch = branch
        self.lineOrder = lineOrder
    }
}

struct MetroStation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let branch: String
}

struct InterchangeStation: Identifiable {
    let id = UUID()
    let displayName: String
    let lines: [String]
    let typeOfInterchange: String
    let linesToShow: [String]
}
