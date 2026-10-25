//
//  WarningBanner.swift
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

struct WarningBanner: View {
    let text: String
    let icon: String
    let action: () -> Void
    
    private let amberColor = Color.init(red: 1.0, green: 0.6, blue: 0.0)
    private let backgroundColor = Color.init(red: 1.0, green: 0.8, blue: 0.4).opacity(0.2)
    
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: (icon == "") ? "exclamationmark.triangle.fill" : icon)
                .font(.system(size: 16))
                .foregroundColor(amberColor)
            
            Text(text)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(amberColor)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(amberColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}
