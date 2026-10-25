//
//  InterchangeRow.swift
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

private struct BouncingMarqueeTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct BouncingMarqueeText: View {
    let text: String
    var font: Font
    var color: Color = Color("TextColor")
    var lineHeight: CGFloat
    var speed: Double = 45
    var edgePause: Double = 3
    
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isReady: Bool = false
    @State private var isAnimating: Bool = false

    private var scrollDistance: CGFloat { max(0, textWidth - containerWidth) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                if isReady {
                    Text(text)
                        .font(font)
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .fixedSize()
                        .offset(x: -offset)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .clipped()
            .onAppear {
                containerWidth = geo.size.width
                tryStart()
            }
            .onChange(of: geo.size.width) { _, cw in
                containerWidth = cw
                tryStart()
            }
        }
        .frame(height: lineHeight)
        .background(
            Text(text)
                .font(font)
                .lineLimit(1)
                .fixedSize()
                .hidden()
                .background(
                    GeometryReader { tg in
                        Color.clear.preference(
                            key: BouncingMarqueeTextWidthKey.self,
                            value: tg.size.width
                        )
                    }
                )
        )
        .onPreferenceChange(BouncingMarqueeTextWidthKey.self) { tw in
            textWidth = tw
            tryStart()
        }
        .onChange(of: text) { _, _ in
            isAnimating = false
            isReady = false
            offset = 0
            textWidth = 0
            tryStart()
        }
        .onDisappear {
            isAnimating = false
        }
    }

    private func tryStart() {
        guard textWidth > 0, containerWidth > 0, !isReady else { return }
        isReady = true
        guard scrollDistance > 1 else { return }
        isAnimating = true
        runCycle()
    }

    private func runCycle() {
        guard isAnimating else { return }
        let goDuration = scrollDistance / speed

        DispatchQueue.main.asyncAfter(deadline: .now() + edgePause) {
            guard isAnimating else { return }
            withAnimation(.linear(duration: goDuration)) {
                offset = scrollDistance
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + goDuration + edgePause) {
                guard isAnimating else { return }
                withAnimation(.linear(duration: goDuration)) {
                    offset = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + goDuration) {
                    runCycle()
                }
            }
        }
    }
}

struct InterchangeRow: View {
    let interchange: InterchangeInfo
    let currentLine: String
    let isFirst: Bool
    let isLast: Bool

    var lineColor: Color { getColor(for: currentLine) }
    var otherLines: [String] { interchange.lines.filter { $0 != currentLine } }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : lineColor)
                    .frame(width: 3)
                    .frame(height: 14)
                Circle()
                    .strokeBorder(lineColor, lineWidth: 3)
                    .background(Circle().fill(Color.white))
                    .frame(width: 16, height: 16)
                Rectangle()
                    .fill(isLast ? Color.clear : lineColor)
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: 8) {
                BouncingMarqueeText(
                    text: interchange.name.uppercased(),
                    font: .custom("TitilliumWeb-Bold", size: 20),
                    color: Color("TextColor"),
                    lineHeight: 24
                )

                if !otherLines.isEmpty {
                    HStack(spacing: 6) {
                        if interchange.typeOfInterchange == "stadium.fill" {
                            Image(interchange.typeOfInterchange)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(Color("TextColor"))
                        } else if interchange.typeOfInterchange == "hospital" {
                            Image(interchange.typeOfInterchange)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(Color("TextColor"))
                        } else {
                            Image(systemName: interchange.typeOfInterchange)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color("TextColor"))
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(otherLines, id: \.self) { line in
                                    Group {
                                        if line.contains(String(localized: .filobus)) || line.wholeMatch(of: /9[0-3]/) != nil {
                                            Label(line, systemImage: "bolt.fill")
                                        } else if line.starts(with: "N") {
                                            Label(line, systemImage: "moon.fill")
                                        } else if line == "Monumento" {
                                            Text(String(localized: .monumento))
                                                .foregroundStyle(.black)
                                        } else if line == "Ospedale" {
                                            Text(String(localized: .ospedale))
                                        } else {
                                            Text(line)
                                        }
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                                }
                            }
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "nosign")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color("TextColor"))

                        Text("Fermata senza interscambi.")
                            .font(.custom("TitilliumWeb-Bold", size: 15))
                            .foregroundStyle(Color("TextColor"))
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 24)

            Spacer(minLength: 0)
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
    }
}
