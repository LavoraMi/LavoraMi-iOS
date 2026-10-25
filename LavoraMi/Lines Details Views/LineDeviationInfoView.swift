//
//  LineDeviationInfoView.swift
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

struct LineDeviationInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var startImageTransition: Bool = false
    @AppStorage("enableAnimations") var enableAnimations = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    if #available(iOS 18.0, *), enableAnimations {
                        Image(systemName: startImageTransition ? "arrow.trianglehead.pull" : "arrow.trianglehead.branch")
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
                        Image(systemName: "arrow.branch")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .padding(.top, 40)
                    }

                    Text("Informazioni sulle mappe")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("LavoraMi potrebbe non mostrare il percorso attuale delle linee sulle mappe, poiché sono in corso deviazioni, interruzioni di tratte del percorso o di stazioni non accessibili. Consultate gli avvisi nella sezione \"Lavori\"!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("LavoraMi prende queste informazioni da fonti autorevoli e affidabili, le eventuali deviazioni di percorso sono indicate nei lavori qui sotto mostrati, potete prendere le eventuali soluzioni di viaggio nell'apposita sezione.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        currentStatus(
                            icon: "person.crop.square.fill",
                            color: .green,
                            title: String(localized: .personaleTitle),
                            description: String(localized: .personaleDeps)
                        )
                        Divider()
                        currentStatus(
                            icon: "exclamationmark.triangle.fill",
                            color: .orange,
                            title: String(localized: .lavoriDeviationInfoTitle),
                            description: String(localized: .lavoriDeviationInfoDeps)
                        )
                        Divider()
                        currentStatus(
                            icon: "person.crop.circle.badge.exclamationmark",
                            color: .red,
                            title: String(localized: .incorrettezzeTitle),
                            description: String(localized: .incorrettezzeDeps)
                        )
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                }
                .padding()
            }
            .navigationTitle("Info sulle Mappe")
            .navigationBarTitleDisplayMode(.inline)
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

    private func dismiss() {presentationMode.wrappedValue.dismiss()}
    
    @ViewBuilder
    private func currentStatus(icon: String, color: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
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
