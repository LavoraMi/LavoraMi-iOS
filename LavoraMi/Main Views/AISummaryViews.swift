//
//  AISummaryViews.swift
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

struct AISummarySkeletonView: View {
    @State private var startPoint: UnitPoint = .init(x: -1.8, y: -1.2)
    @State private var endPoint: UnitPoint = .init(x: -0.6, y: -0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Riepilogo AI", systemImage: "text.line.3.summary")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 10)
                    .frame(maxWidth: 160)
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(.systemGray3), Color(.systemGray2), Color(.systemGray3)],
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.accentColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.top, 4)
        .onAppear {
            withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                startPoint = .init(x: 1.2, y: 1.2)
                endPoint = .init(x: 2.4, y: 2.2)
            }
        }
    }
}

@available(iOS 26, *)
struct AISummarizeButton: View {
    let text: String
    @Binding var summary: String
    @Binding var isLoading: Bool

    private var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    var body: some View {
        if isAvailable {
            Button {
                Task { await summarize() }
            } label: {
                Label(
                    isLoading ? "Riassumo..." : "Riassumi",
                    systemImage: "text.line.3.summary"
                )
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.12))
                .foregroundStyle(.red.gradient)
                .clipShape(Capsule())
            }
            .disabled(isLoading)
        }
    }

    private func summarize() async {
        isLoading = true
        summary = ""
        defer { isLoading = false }

        let session = LanguageModelSession {
            String(localized: .inputAI)
        }

        do {
            let stream = session.streamResponse(to: text)
            for try await partial in stream {
                summary = partial.content
            }
        } catch {
            summary = String(localized: .aiError)
        }
    }
}
