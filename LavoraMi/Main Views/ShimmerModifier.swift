//
//  ShimmerModifier.swift
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

struct ShimmerModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0.0

    var duration: Double = 1.25
    var angle: Angle = .degrees(12)
    var bandFraction: CGFloat = 0.35
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let bandWidth = max(80, width * bandFraction)
                    let startX = -bandWidth
                    let endX = width + bandWidth
                    let x = startX + (endX - startX) * progress

                    let highlight = colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.22)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: highlight, location: 0.5),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: bandWidth, height: height * 2)
                        .rotationEffect(angle)
                        .offset(x: x, y: 0)
                        .blendMode(.screen)
                }
                .allowsHitTesting(false)
                .clipped()
            }
            .onAppear {
                guard !reduceMotion else { return }
                progress = 0
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    progress = 1
                }
            }
            .onDisappear {
                progress = 0
            }
    }
}

extension View {func shimmer() -> some View { modifier(ShimmerModifier()) }}
