//
//  Extensions.swift
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

//EXTENSION: Save files also with arrays
extension Array: @retroactive RawRepresentable where Element == String {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([String].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

// MARK: - Bundle version helpers
extension Bundle {
    /// CFBundleShortVersionString (e.g., 1.2.3)
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// CFBundleVersion (build number)
    var buildVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}

extension URL: @retroactive Identifiable { public var id: String { absoluteString }}

extension Date: @retroactive RawRepresentable {
    private static let isoFormatter = ISO8601DateFormatter()

    public var rawValue: String {
        Date.isoFormatter.string(from: self)
    }

    public init?(rawValue: String) {
        if let date = Date.isoFormatter.date(from: rawValue) {
            self = date
        } else {
            self = Date()
        }
    }
}

extension Date {
    var hasTime: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 3600)!
        
        let cal = calendar.dateComponents([.hour, .minute], from: self)
        return (cal.hour ?? 0) != 0 || (cal.minute ?? 0) != 0
    }
}
