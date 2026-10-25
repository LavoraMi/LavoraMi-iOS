//
//  LineRow.swift
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

struct LineRow: View {
    let line: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String
    let accessibilityStatus: String
    let stations: [MetroStation]
    @ObservedObject var viewModel: WorkViewModel
    var onTap: (() -> Void)? = nil

    private var isDetailView: Bool {
        typeOfTransport != "NET"
        && typeOfTransport != "Autoguidovie"
    }

    @ViewBuilder
    private var destination: some View {
        LineDetailView(lineName: line, typeOfTransport: typeOfTransport, branches: branches, waitMinutes: waitMinutes, workScheduled: getWorkScheduled(line: (typeOfTransport.uppercased().contains(String(localized: .filobus).uppercased())) ? "Filobus \(line)" : line, viewModel: viewModel), workNow: getWorkNow(line: (typeOfTransport.uppercased().contains(String(localized: .filobus).uppercased()) ? "Filobus \(line)" : line), viewModel: viewModel), viewModel: viewModel, stations: stations, accessibilityStatus: accessibilityStatus, isDetailed: isDetailView, onAppear: { onTap?() })
    }

    var body: some View {
        NavigationLink {destination} label: {
            HStack(spacing: 12) {
                Text(line)
                    .foregroundStyle(.white)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill((typeOfTransport == String(localized: .tram)) ? .orange : getColor(for: line))
                    )

                if line == "MXP1" || line == "MXP2" || line == "H" {Text(typeOfTransport)}
                else {Text("\(typeOfTransport) \(line)")}
            }
            .padding(.vertical, 4)
        }
    }
}
