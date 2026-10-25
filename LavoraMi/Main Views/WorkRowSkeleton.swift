//
//  WorkRowSkeleton.swift
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

struct WorkRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 180, height: 14)

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 40, height: 20)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 32, height: 20)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 50, height: 20)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 28, height: 20)
                }

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 6)
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 90, height: 10)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 90, height: 10)
                }

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 120, height: 12)
                    .frame(alignment: .center)
            }
            .shimmer()
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}
