//
//  LibraryRowView.swift
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

struct LibraryRowView: View {
    let name: String
    let version: String
    let license: String
    let copyright: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(version)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
            }

            HStack {
                Text(license)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text(copyright)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .cornerRadius(12)
    }
}
