//
//  AppearancePickerView.swift
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

struct AppearancePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURLAction
    @AppStorage("appearanceSelection") private var appearanceSelection: AppearanceType = .system

    var body: some View {
        List {
            Section("Tema") {
                ForEach(AppearanceType.allCases) { filter in
                    Button {
                        appearanceSelection = filter
                        dismiss()
                    } label: {
                        HStack {
                            Label {
                                Text(filter.description)
                            } icon: {
                                Image(systemName: filter.iconName)
                                    .foregroundStyle(.red)
                            }
                            Spacer()
                            if appearanceSelection == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .foregroundColor(Color("TextColor"))
                }
            }
            Section() {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURLAction(url)
                    }
                } label: {
                    HStack {
                        Text("🇮🇹 Italiano")
                        if(Locale.current.language.languageCode?.identifier == "it") {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                .foregroundColor(Color("TextColor"))
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURLAction(url)
                    }
                } label: {
                    HStack {
                        Text("🇬🇧 Inglese")
                        if(Locale.current.language.languageCode?.identifier == "en") {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                .foregroundColor(Color("TextColor"))
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURLAction(url)
                    }
                } label: {
                    HStack {
                        Text("🇪🇸 Spagnolo")
                        if(Locale.current.language.languageCode?.identifier == "es") {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                .foregroundColor(Color("TextColor"))
            } header: {
                Text("Lingua")
            } footer: {
                Text("Per modificare la lingua, sarai reindirizzato alle impostazioni dell'app su iOS.")
            }
        }
        .navigationTitle("Aspetto e Lingua")
        .navigationBarTitleDisplayMode(.inline)
    }
}
