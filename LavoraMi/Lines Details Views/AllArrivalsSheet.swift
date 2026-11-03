//
//  AllArrivalsSheet.swift
//  LavoraMi
//
//  Created by Andrea Filice on 03/11/2026.
//

import SwiftUI
import Combine
 
extension GTFSHelper {
    ///Get all the departures from the StopID and GTFS file
    static func getAllDepartures(for stopId: String, directionId: String, in route: GTFSRoute, now: Date = Date()) -> [Departure] {
        getDepartures(for: stopId, in: route, limit: .max, now: now)?[directionId] ?? []
    }
}
 
struct AllArrivalsSelection: Identifiable {
    /// This is a Identifiable struct of datas used by the render process to show GTFS departures
    /// - let id: UUID is the identifier of the departure
    /// - let directionId: String is the identifier that identifies the direction of the departure
    /// - let headsign: String is the text to show into the render process
    
    let id = UUID()
    let directionId: String
    let headsign: String
}
 
struct AllArrivalsSheet: View {
    let route: GTFSRoute
    let stopId: String
    let directionId: String
    let headsign: String
    let lineColor: Color
 
    @Environment(\.dismiss) private var dismiss
    @State private var now = Date()
 
    private let refreshTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
 
    private var departures: [Departure] {
        GTFSHelper.getAllDepartures(for: stopId, directionId: directionId, in: route, now: now)
    }
 
    var body: some View {
        VStack(spacing: 0) {
            topBar
 
            if departures.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "Nessun'altra corsa",
                    systemImage: "clock.badge.questionmark.fill",
                    description: Text("Per oggi non ci sono altre corse programmate per questa direzione.")
                )
                Spacer()
            }
            else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        let list = departures
                        ForEach(Array(list.enumerated()), id: \.offset) { index, dep in
                            row(for: dep, isFirst: index == 0, isLast: index == list.count - 1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color(.systemBackground))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onReceive(refreshTimer) { now = $0 }
    }
 
    private var topBar: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("DIREZIONE: \(headsign.uppercased())")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 250)
 
                Text("Tutti gli arrivi")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
            }
 
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color(.tertiarySystemFill)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Chiudi")
 
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .padding(.top, 8)
        .background(Color(.secondarySystemBackground))
    }
 
    private func row(for dep: Departure, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            timelineIndicator(isFirst: isFirst, isLast: isLast)
 
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(dep.time)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
 
                    Text(waitText(for: dep))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
 
                Text("DIREZIONE: \(dep.headsign.uppercased())")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 14)
 
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
 
    private func timelineIndicator(isFirst: Bool, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? Color.clear : lineColor)
                .frame(width: 3, height: 16)
 
            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(lineColor, lineWidth: 3))
 
            Rectangle()
                .fill(isLast ? Color.clear : lineColor)
                .frame(width: 3)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 20)
    }
 
    private func waitText(for dep: Departure) -> String {
        dep.minutesFromNow == 0 ? String(localized: .inPartenza) : "in \(dep.formattedWait)"
    }
}
