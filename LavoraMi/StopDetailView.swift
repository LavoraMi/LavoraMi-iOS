//
//  StopDetailView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 01/10/2026.
//

import SwiftUI
import MapKit
import Combine

struct TramStopSelection: Identifiable {
    let id = UUID()
    let name: String
}

private struct DirectionDepartures: Identifiable {
    let id: String
    let departures: [Departure]
}

struct StopDetailView: View {
    let lineName: String
    let stations: [MetroStation]
    let interchanges: [InterchangeInfo]
    let lineColor: Color

    @State private var stopName: String
    @State private var routeData: GTFSRoute?
    @State private var loadFailed = false
    @State private var directions: [DirectionDepartures] = []
    @State private var directionIndex = 0
    @State private var camera: MapCameraPosition = .automatic
    @State private var showSheet = false
    @State private var detent: PresentationDetent = .medium

    @Environment(\.dismiss) private var dismiss
    @AppStorage("feedbacksEnabled") private var feedbacksEnabled: Bool = true

    private let refreshTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    init(lineName: String, stopName: String, stations: [MetroStation], interchanges: [InterchangeInfo], initialRoute: GTFSRoute?, lineColor: Color) {
        self.lineName = lineName
        self.stations = stations
        self.interchanges = interchanges
        self.lineColor = lineColor
        _stopName = State(initialValue: stopName)
        _routeData = State(initialValue: initialRoute)
    }

    private var cdnURL: URL? {
        URL(string: "https://cdn.lavorami.it/gtfs/\(lineName.uppercased()).json")
    }

    var body: some View {
        let visible = visibleStations

        ZStack(alignment: .topLeading) {
            Map(position: $camera) {
                UserAnnotation()

                if visible.path.count >= 2 {
                    MapPolyline(coordinates: visible.path.map(\.coordinate))
                        .stroke(lineColor, lineWidth: 5)
                }

                ForEach(visible.shown) { station in
                    Annotation(station.name, coordinate: station.coordinate) {
                        marker(for: station)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
            }
            .tint(lineColor)
            .ignoresSafeArea()

            backButton
        }
        .sheet(isPresented: $showSheet) {
            sheetContent
                .presentationDetents([.height(96), .medium], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .interactiveDismissDisabled()
        }
        .onAppear {
            fitCamera()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showSheet = true }
        }
        .task {
            await loadRouteIfNeeded()
        }
        .onReceive(refreshTimer) { _ in
            refreshDepartures()
        }
    }

    @ViewBuilder
    private func marker(for station: MetroStation) -> some View {
        if station.name.caseInsensitiveCompare(stopName) == .orderedSame {
            StopPulsingDot(color: lineColor)
        }
        else {
            ZStack {
                Circle().fill(.white).frame(width: 12, height: 12)
                Circle().stroke(lineColor, lineWidth: 3).frame(width: 12, height: 12)
            }
            .contentShape(Circle().inset(by: -8))
            .onTapGesture { select(station.name) }
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.primary)
                .frame(width: 45, height: 45)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .padding(.leading, 12)
        .padding(.top, 8)
    }

    private var sheetContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                nextArrivalSection
                interchangeSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "tram.fill")
                .font(.system(size: 22))
                .foregroundStyle(.orange)
                .frame(width: 52, height: 52)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(stopName)
                    .font(.title3.bold())
                    .lineLimit(1)
                Text("\(String(localized: .tram)) \(lineName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var nextArrivalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Prossimo arrivo:")
                    .font(.headline)
                Spacer()
                if directions.count > 1 {
                    Button(action: changeDirection) {
                        Label("Direzione", systemImage: "arrow.left.arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            arrivalRow
        }
    }

    @ViewBuilder
    private var arrivalRow: some View {
        if let next = currentDirection?.departures.first {
            HStack(spacing: 10) {
                Text(lineName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 50)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(lineColor, in: RoundedRectangle(cornerRadius: 8))

                Text("Direzione: \(next.headsign.uppercased())")
                    .font(.system(size: 16))
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(next.formattedWait)
                    .font(.system(size: 18, weight: .bold))
            }
        }
        else if loadFailed {
            Text("Orari non disponibili per questa fermata.")
                .foregroundStyle(.secondary)
        }
        else if routeData == nil {
            HStack(spacing: 8) {
                ProgressView()
                Text("Caricamento orari...").foregroundStyle(.secondary)
            }
        }
        else {
            Text("Nessuna partenza prevista per oggi.")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var interchangeSection: some View {
        if let info = interchange {
            StopInterchangeCard(interchange: info, currentLine: lineName)
        }
    }

    private var currentDirection: DirectionDepartures? {
        directions.indices.contains(directionIndex) ? directions[directionIndex] : nil
    }

    private func select(_ name: String) {
        guard name.caseInsensitiveCompare(stopName) != .orderedSame else { return }
        if feedbacksEnabled { HapticManager.shared.trigger() }
        stopName = name
        directionIndex = 0
        refreshDepartures()
        fitCamera()
    }

    private func changeDirection() {
        guard directions.count > 1 else { return }
        directionIndex = (directionIndex + 1) % directions.count
        if feedbacksEnabled { HapticManager.shared.trigger() }
    }

    private func loadRouteIfNeeded() async {
        if routeData == nil, let url = cdnURL {
            do { routeData = try await GTFSHelper.load(from: url) }
            catch { loadFailed = true }
        }
        refreshDepartures()
    }

    private func refreshDepartures() {
        guard let route = routeData,
              let id = GTFSHelper.stopId(named: stopName, in: route) else {
            directions = []
            return
        }
        let byDir = GTFSHelper.getDepartures(for: id, in: route, limit: 1) ?? [:]
        directions = byDir.keys.sorted().map { DirectionDepartures(id: $0, departures: byDir[$0] ?? []) }
        if directionIndex >= directions.count { directionIndex = 0 }
    }

    private var interchange: InterchangeInfo? {
        let target = GTFSHelper.normalizedName(stopName)
        if target == "lodi tibb",
           let special = interchanges.first(where: { $0.name.caseInsensitiveCompare("Milano Scalo Romana") == .orderedSame }) {
            return special
        }
        
        if let exact = interchanges.first(where: { GTFSHelper.normalizedName($0.name) == target }) { return exact }
        return interchanges.first { GTFSHelper.normalizedName($0.name).contains(target) }
    }

    private func isHidden(_ s: MetroStation) -> Bool {
        s.name.caseInsensitiveCompare("NO_DRAW") == .orderedSame
    }

    private func nearestReal(in list: [MetroStation], from index: Int, step: Int) -> Int? {
        var i = index + step
        while list.indices.contains(i) {
            if !isHidden(list[i]) { return i }
            i += step
        }
        
        return nil
    }

    private var visibleStations: (path: [MetroStation], shown: [MetroStation]) {
        let real = stations.filter { !isHidden($0) }
        func isCurrent(_ s: MetroStation) -> Bool {
            !isHidden(s) && s.name.caseInsensitiveCompare(stopName) == .orderedSame
        }

        guard let current = stations.first(where: isCurrent) else { return (stations, real) }

        let branchStations = stations.filter { $0.branch == current.branch }
        guard let idx = branchStations.firstIndex(where: isCurrent) else { return (stations, real) }

        let prev = nearestReal(in: branchStations, from: idx, step: -1)
        let next = nearestReal(in: branchStations, from: idx, step: +1)
        let start = prev ?? idx
        let end = next ?? idx

        let path = Array(branchStations[start...end])
        let shown = [prev, idx, next].compactMap { $0 }.map { branchStations[$0] }
        return (path, shown)
    }

    private func fitCamera() {
        let target = stations.first {
            !isHidden($0) && $0.name.caseInsensitiveCompare(stopName) == .orderedSame
        }
        
        guard let coord = target?.coordinate else {
            let points = visibleStations.shown.map(\.coordinate)
            guard let first = points.first else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                camera = .camera(MapCamera(centerCoordinate: first, distance: 900, heading: 0, pitch: 0))
            }
            return
        }

        let distance: CLLocationDistance = 650
        let metersSouth = distance * 0.22
        let degreesSouth = metersSouth / 111_000
        let center = CLLocationCoordinate2D(latitude: coord.latitude - degreesSouth, longitude: coord.longitude)

        withAnimation(.easeInOut(duration: 0.4)) {
            camera = .camera(MapCamera(centerCoordinate: center, distance: distance, heading: 0, pitch: 0))
        }
    }
}

private struct StopInterchangeCard: View {
    let interchange: InterchangeInfo
    let currentLine: String

    private var otherLines: [String] { interchange.lines.filter { $0 != currentLine } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interscambi")
                .font(.headline)

            if otherLines.isEmpty {
                Label("Fermata senza interscambi.", systemImage: "nosign")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            else {
                HStack(spacing: 10) {
                    typeIcon
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(otherLines, id: \.self) { line in
                                badge(for: line)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var typeIcon: some View {
        if interchange.typeOfInterchange == "stadium.fill" || interchange.typeOfInterchange == "hospital" {
            Image(interchange.typeOfInterchange)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.primary)
        }
        else {
            Image(systemName: interchange.typeOfInterchange)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.primary)
        }
    }

    @ViewBuilder
    private func badge(for line: String) -> some View {
        Group {
            if line.contains(String(localized: .filobus)) || line.wholeMatch(of: /9[0-3]/) != nil {
                Label(line, systemImage: "bolt.fill")
            }
            else if line.starts(with: "N") {
                Label(line, systemImage: "moon.fill")
            }
            else if line == "Monumento" {
                Text(String(localized: .monumento)).foregroundStyle(.black)
            }
            else if line == "Ospedale" {
                Text(String(localized: .ospedale))
            }
            else {
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

private struct StopPulsingDot: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: 36, height: 36)
                .scaleEffect(animate ? 1.5 : 0.5)
                .opacity(animate ? 0 : 1)
                .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: animate)

            Circle().fill(.white).frame(width: 16, height: 16)
            Circle().stroke(color, lineWidth: 3).frame(width: 16, height: 16)
        }
        .onAppear { animate = true }
    }
}

extension GTFSHelper {
    private static let abbreviazioni: [String: String] = [
        "p.le": "piazzale", "p.za": "piazza", "p.ta": "porta", "v.le": "viale",
        "c.so": "corso", "l.go": "largo", "m.te": "monte",
        "s.": "san", "c.": "console", "p.": "principe"
    ]

    static func normalizedName(_ name: String) -> String {
        name
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "it_IT"))
            .trimmingCharacters(in: .whitespaces)
            .split(separator: " ")
            .map { abbreviazioni[String($0)] ?? String($0) }
            .joined(separator: " ")
    }

    private static let numeriParole: [String: String] = [
        "uno": "1", "due": "2", "tre": "3", "quattro": "4", "cinque": "5", "sei": "6", "sette": "7",
        "otto": "8", "nove": "9", "dieci": "10", "undici": "11", "dodici": "12", "tredici": "13",
        "quattordici": "14", "quindici": "15", "sedici": "16", "diciassette": "17", "diciotto": "18",
        "diciannove": "19", "venti": "20", "ventuno": "21", "ventidue": "22", "ventitre": "23",
        "ventiquattro": "24", "venticinque": "25", "ventisei": "26", "ventisette": "27",
        "ventotto": "28", "ventinove": "29", "trenta": "30", "trentuno": "31"
    ]

    private static func romanValue(_ token: String) -> Int? {
        guard token.range(of: "^[ivx]+$", options: .regularExpression) != nil else { return nil }
        let map: [Character: Int] = ["i": 1, "v": 5, "x": 10]
        var total = 0, prev = 0
        for ch in token.reversed() {
            let v = map[ch] ?? 0
            total += v < prev ? -v : v
            prev = max(prev, v)
        }
        return total > 1 ? total : nil
    }

    private static func matchTokens(_ name: String) -> [String] {
        normalizedName(name)
            .replacingOccurrences(of: "[.,'’()\\-]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.range(of: "^m[1-5]$", options: .regularExpression) == nil && $0 != "fn" }
            .map { numeriParole[$0] ?? romanValue($0).map(String.init) ?? $0 }
    }

    static func stopId(named name: String, in route: GTFSRoute) -> String? {
        let target = normalizedName(name)
        if let exact = route.stops.first(where: { normalizedName($0.value.n) == target })?.key { return exact }

        let t = matchTokens(name)
        guard !t.isEmpty else { return nil }
        let tSet = Set(t)

        if let same = route.stops.first(where: { Set(matchTokens($0.value.n)) == tSet })?.key { return same }

        var bestKey: String?
        var bestScore = 0.0
        for (key, stop) in route.stops {
            let s = Set(matchTokens(stop.n))
            let union = s.union(tSet).count
            guard union > 0 else { continue }
            let score = Double(s.intersection(tSet).count) / Double(union)
            if score > bestScore { bestScore = score; bestKey = key }
        }
        if bestScore >= 0.6 { return bestKey } 
        
        return nil
    }
}
