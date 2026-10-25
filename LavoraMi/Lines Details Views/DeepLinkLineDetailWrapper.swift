//
//  DeepLinkLineDetailWrapper.swift
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

///URL Types
///In this section we create the code for open the URLs of Widgets
struct DeepLinkLine: Identifiable {
    let id = UUID()
    let name: String
}

struct DeepLinkLineDetailWrapper: View {
    let lineName: String
    @ObservedObject var viewModel: WorkViewModel
    @Environment(\.dismiss) private var dismiss

    private var lineInfo: LineInfo? {
        LinesView(viewModel: viewModel).fullLineInfo(for: lineName)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let info = lineInfo {
                LineDetailView(
                    lineName: info.name,
                    typeOfTransport: info.type,
                    branches: info.branches,
                    waitMinutes: info.waitMinutes,
                    workScheduled: getWorkScheduled(line: info.name, viewModel: viewModel),
                    workNow: getWorkNow(line: info.name, viewModel: viewModel),
                    viewModel: viewModel,
                    stations: info.stations,
                    accessibilityStatus: info.accessibilityStatus,
                    isDetailed: info.type != "NET"
                    && info.type != "Autoguidovie"
                )
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)

                    Text("Linea non trovata.")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("Questa linea non esiste oppure non è ancora su LavoraMi. Segnala a support@lavorami.it se ritieni sia un errore.")
                        .font(.system(size: 12))
                        .padding(.horizontal, 20)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(.quaternary, lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
    }
}
