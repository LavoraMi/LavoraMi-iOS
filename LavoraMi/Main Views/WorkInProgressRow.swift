//
//  WorkInProgressRow.swift
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

struct WorkInProgressRow: View {
    let item: WorkItem
    
    @State private var isExpanded = false
    @State private var showTranslation = false
    @State private var aiSummary: String = ""
    @State private var isAiSummaryLoading: Bool = false
    
    @AppStorage("showTranslateButton") var showTranslateButton: Bool = false
    
    private let italianLoc = Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: "it_IT"))
    private let italianLocTime = Date.FormatStyle(date: .abbreviated, time: .shortened).locale(Locale(identifier: "it_IT"))
    private func formatWorkDate(_ date: Date) -> String {
        date.hasTime ? date.formatted(italianLocTime) : date.formatted(italianLoc)
    }
    
    private var isImportant: Bool {item.details.contains("[LAVORO IMPORTANTE]")}
    private var isEvent: Bool {item.details.contains("[EVENTO]")}
    private var cleanedDetails: String {
        item.details
            .replacingOccurrences(of: "[LAVORO IMPORTANTE]", with: "")
            .replacingOccurrences(of: "[EVENTO]", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var shouldShowTranslationButton: Bool {Locale.current.language.languageCode?.identifier != "it" || showTranslateButton == true}
    var textToTranslate: String {"\(item.title)\n\n\(cleanedDetails)\n\nStrade: \(item.roads)\n\nLinee coinvolte: \(item.lines.joined(separator: ", "))"}

    var body: some View {
        VStack(spacing: 0) {
            if isImportant {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text("LAVORO IMPORTANTE")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(0.5)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.red)
            }
            
            if isEvent {
                HStack(spacing: 8) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text("EVENTO")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(0.5)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.red)
            }
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(cleanedDetails)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        if shouldShowTranslationButton {
                            Button {
                                showTranslation = true
                            } label: {
                                Label("Traduci", systemImage: "translate")
                                    .font(.footnote.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundStyle(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                        }

                        if #available(iOS 26, *) {
                            AISummarizeButton(
                                text: cleanedDetails,
                                summary: $aiSummary,
                                isLoading: $isAiSummaryLoading
                            )
                        }
                    }
                    
                    if isAiSummaryLoading {
                        AISummarySkeletonView()
                    } else if !aiSummary.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Riepilogo AI", systemImage: "text.line.3.summary")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(aiSummary)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(10)
                        .background(Color.accentColor.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 8)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    if item.titleIcon == "point.bottomleft.forward.to.arrow.triangle.uturn.scurvepath" {
                        if #available(iOS 18, *) {
                            Label(item.title, systemImage: item.titleIcon)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color("TextColor"))
                        } else {
                            Label(item.title, systemImage: "arrow.up.forward.app.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color("TextColor"))
                        }
                    }
                    else if item.titleIcon == "arrow.trianglehead.2.counterclockwise" {
                        if #available(iOS 18, *) {
                            Label(item.title, systemImage: item.titleIcon)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color("TextColor"))
                        } else {
                            Label(item.title, systemImage: "shuffle")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color("TextColor"))
                        }
                    }
                    else {
                        Label(item.title, systemImage: item.titleIcon)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(Color("TextColor"))
                    }
                    Label(item.roads, systemImage: "mappin")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(Color("TextColor"))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(item.lines, id: \.self) { line in
                                if line.contains("Filobus") {
                                    Label(line.replacing("Filobus", with: String(localized: .filobus)), systemImage: "bolt.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                                } else if line.starts(with: "N") {
                                    Label(line, systemImage: "moon.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                                } else {
                                    Text(line)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                                }
                            }
                        }
                    }
                    VStack(spacing: 6) {
                        ProgressView(value: item.progress)
                            .progressViewStyle(.linear)
                            .tint(item.progress == 1.0 ? .green : .red)

                        HStack {
                            Text(formatWorkDate(item.startDate))
                                .font(.caption)
                                .foregroundStyle(Color("TextColor"))
                            Spacer()
                                .frame(height: 8)
                            Text(formatWorkDate(item.endDate))
                                .font(.caption)
                                .foregroundStyle(Color("TextColor"))
                        }
                        Spacer().frame(height: 8)
                        Text(item.company)
                            .foregroundStyle(Color("TextColor"))
                            .padding(.top, 4)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    (isImportant || isEvent) ? Color.red.opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: (isImportant || isEvent) ? .red.opacity(0.30) : .black.opacity(0.06),
            radius: (isImportant || isEvent) ? 14 : 6,
            x: 0,
            y: (isImportant || isEvent) ? 4 : 3
        )
        .translationPresentation(isPresented: $showTranslation, text: textToTranslate)
    }
}
