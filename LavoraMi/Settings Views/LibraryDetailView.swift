//
//  LibraryDetailView.swift
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

struct LibraryDetailView: View {
    let name: String
    let version: String
    let license: String
    let copyright: String
    let licenseText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Informazioni sul componente")
                        .font(.title2).bold()
                        .padding(.bottom, 10)

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nome:").font(.caption).foregroundColor(.secondary)
                            Text(name).font(.body).bold()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Versione:").font(.caption).foregroundColor(.secondary)
                            Text(version).font(.body).bold()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Licenza:").font(.caption).foregroundColor(.secondary)
                            Text(license).font(.body).bold()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Copyright")
                        .font(.title2).bold()

                    Text(copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Testo della licenza")
                        .font(.title2).bold()

                    Text(licenseText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
