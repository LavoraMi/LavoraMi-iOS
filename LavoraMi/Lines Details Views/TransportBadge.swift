//
//  TransportBadge.swift
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

struct TransportBadge: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let line: String
    
    private var badgeColor: Color {
        if line.starts(with: "z") {
            return getColor(for: "z")
        }
        return getColor(for: line)
    }

    var body: some View {
        Text(line)
            .foregroundStyle(.white)
            .font(.system(size: 20, weight: .bold))
            .padding(.vertical, 4)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(badgeColor)
            )
    }
}
