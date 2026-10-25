//
//  InfoAccessibilityView.swift
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

struct InfoAccessibilityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var startImageTransition: Bool = false
    @Binding var showInfoView: Bool
    @AppStorage("enableAnimations") var enableAnimations = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    if #available(iOS 18.0, *), enableAnimations {
                        Image(systemName: startImageTransition ? "figure.roll" : "person.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .padding(.top, 50)
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                            .onAppear {
                                Task {
                                    try? await Task.sleep(for: .seconds(1))
                                    withAnimation {
                                        startImageTransition = true
                                    }
                                }
                            }
                            .onDisappear {
                                startImageTransition = false
                            }
                    } else {
                        Image(systemName: "figure.roll")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .padding(.top, 40)
                    }

                    Text("Informazioni sull'Accessibilità")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("LavoraMi mostra l'accessibilità di una linea in base agli impianti nelle stazioni e alla tipologia di mezzo utilizzato.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("LavoraMi prende queste informazioni da fonti autorevoli e affidabili, i dati potrebbero non essere aggiornati all'ultimo minuto.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 20) {
                        accessibilitySection(
                            icon: "checkmark.circle.fill",
                            color: .green,
                            title: String(localized: .completamenteAccessibile),
                            description: String(localized: .completamenteAccessibileDeps)
                        )
                        Divider()
                        accessibilitySection(
                            icon: "exclamationmark.circle.fill",
                            color: .orange,
                            title: String(localized: .parzialmenteAccessibile),
                            description: String(localized: .parzialmenteAccessibileDeps)
                        )
                        Divider()
                        accessibilitySection(
                            icon: "xmark.circle.fill",
                            color: .red,
                            title: String(localized: .nonAccessibile),
                            description: String(localized: .nonAccessibileDeps)
                        )
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                }
                .padding()
            }
            .navigationTitle("Accessibilità")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func dismiss() {
        showInfoView = false
        presentationMode.wrappedValue.dismiss()
    }

    @ViewBuilder
    private func accessibilitySection(icon: String, color: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.roll")
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                .font(.headline)

                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }

            Text(description)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}
 
