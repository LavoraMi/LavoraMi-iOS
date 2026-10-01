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
    @State private var stopId: String?
    @State private var routeData: GTFSRoute?
    @State private var loadFailed = false
    @State private var directions: [DirectionDepartures] = []
    @State private var directionIndex = 0
    @State private var camera: MapCameraPosition
    @State private var mapSize: CGSize = CGSize(width: 393, height: 852)
    @State private var showSheet = false
    @State private var detent: PresentationDetent = .medium

    @Environment(\.dismiss) private var dismiss
    @AppStorage("feedbacksEnabled") private var feedbacksEnabled: Bool = true

    private let refreshTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    private static let visibleMapMeters: Double = 420
    private static let collapsedSheetHeight: CGFloat = 96

    init(lineName: String, stopName: String, stations: [MetroStation], interchanges: [InterchangeInfo], initialRoute: GTFSRoute?, lineColor: Color) {
        self.lineName = lineName
        self.stations = stations
        self.interchanges = interchanges
        self.lineColor = lineColor
        _stopName = State(initialValue: stopName)
        _routeData = State(initialValue: initialRoute)
        _stopId = State(initialValue: initialRoute.flatMap { GTFSHelper.stopId(named: stopName, in: $0) })

        let start = stations.first { $0.name != "NO_DRAW" && $0.name.caseInsensitiveCompare(stopName) == .orderedSame }
        if let coord = start?.coordinate {
            let size = CGSize(width: 393, height: 852)
            _camera = State(initialValue: .region(Self.region(center: coord, size: size, sheetHeight: size.height / 2)))
        }
        else {
            _camera = State(initialValue: .automatic)
        }
    }

    private var cdnURL: URL? {
        URL(string: "https://cdn.lavorami.it/gtfs/\(lineName.uppercased()).json")
    }

    var body: some View {
        let visible = visibleStations

        GeometryReader { geo in
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
            .onAppear { updateMapSize(from: geo) }
            .onChange(of: geo.size) { _, _ in updateMapSize(from: geo) }
        }
        .sheet(isPresented: $showSheet) {
            sheetContent
                .presentationDetents([.height(Self.collapsedSheetHeight), .medium], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationBackground(Color(.systemBackground))
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .interactiveDismissDisabled()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showSheet = true }
        }
        .onChange(of: detent) { _, _ in fitCamera() }
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

    private func updateMapSize(from geo: GeometryProxy) {
        let insets = geo.safeAreaInsets
        let full = CGSize(width: geo.size.width + insets.leading + insets.trailing,
                          height: geo.size.height + insets.top + insets.bottom)
        guard full.width > 0, full.height > 0, full != mapSize else { return }
        mapSize = full
        fitCamera(animated: false)
    }

    private static func region(center coord: CLLocationCoordinate2D, size: CGSize, sheetHeight: CGFloat) -> MKCoordinateRegion {
        let height = Double(max(size.height, 1))
        let width = Double(max(size.width, 1))
        let metersPerPoint = visibleMapMeters / height
        let metersPerDegree = 111_320.0

        let shiftMeters = Double(sheetHeight) / 2 * metersPerPoint
        let center = CLLocationCoordinate2D(latitude: coord.latitude - shiftMeters / metersPerDegree,
                                            longitude: coord.longitude)
        let span = MKCoordinateSpan(
            latitudeDelta: visibleMapMeters / metersPerDegree,
            longitudeDelta: width * metersPerPoint / (metersPerDegree * max(cos(coord.latitude * .pi / 180), 0.01))
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    private func fitCamera(animated: Bool = true) {
        let current = stations.first { !isHidden($0) && $0.name.caseInsensitiveCompare(stopName) == .orderedSame }
        guard let coord = current?.coordinate else { return }

        let sheetHeight = detent == .medium ? mapSize.height / 2 : Self.collapsedSheetHeight
        let target = MapCameraPosition.region(Self.region(center: coord, size: mapSize, sheetHeight: sheetHeight))

        if animated {
            withAnimation(.easeInOut(duration: 0.4)) { camera = target }
        }
        else {
            camera = target
        }
    }
    
    private var sheetContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                nextArrivalSection
                StopInterchangeTimeline(
                    name: interchange?.name ?? stopName,
                    otherLines: (interchange?.lines ?? []).filter { $0 != lineName },
                    typeOfInterchange: interchange?.typeOfInterchange ?? "tram.fill",
                    lineColor: lineColor
                )
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

                StopMarqueeText(text: "Direzione: \(next.headsign.uppercased())", font: .system(size: 16))
                    .id(next.headsign)

                Text(next.formattedWait)
                    .font(.system(size: 18, weight: .bold))
                    .fixedSize()
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

    private var currentDirection: DirectionDepartures? {
        directions.indices.contains(directionIndex) ? directions[directionIndex] : nil
    }

    private func select(_ name: String) {
        guard name.caseInsensitiveCompare(stopName) != .orderedSame else { return }
        if feedbacksEnabled { HapticManager.shared.trigger() }
        stopName = name
        directionIndex = 0
        resolveStopId()
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
        resolveStopId()
        refreshDepartures()
    }

    private func resolveStopId() {
        stopId = routeData.flatMap { GTFSHelper.stopId(named: stopName, in: $0) }
    }

    private func refreshDepartures() {
        guard let route = routeData, let id = stopId else {
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
}

private struct StopInterchangeTimeline: View {
    let name: String
    let otherLines: [String]
    let typeOfInterchange: String
    let lineColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Rectangle().fill(lineColor).frame(width: 3, height: 10)
                Circle()
                    .strokeBorder(lineColor, lineWidth: 3)
                    .background(Circle().fill(Color.white))
                    .frame(width: 20, height: 20)
                Rectangle().fill(lineColor).frame(width: 3).frame(maxHeight: .infinity)
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 10) {
                StopMarqueeText(text: name.uppercased(), font: .custom("TitilliumWeb-Bold", size: 20))
                    .id(name)
                    .padding(.top, 6)

                if otherLines.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "nosign")
                            .font(.system(size: 18, weight: .bold))
                        Text("Fermata senza interscambi.")
                            .font(.custom("TitilliumWeb-Bold", size: 15))
                    }
                    .foregroundStyle(Color("TextColor"))
                }
                else {
                    HStack(spacing: 8) {
                        typeIcon
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(otherLines, id: \.self) { badge(for: $0) }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var typeIcon: some View {
        if typeOfInterchange == "stadium.fill" || typeOfInterchange == "hospital" {
            Image(typeOfInterchange)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(Color("TextColor"))
        }
        else {
            Image(systemName: typeOfInterchange)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color("TextColor"))
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

private struct StopMarqueeText: View {
    let text: String
    let font: Font
    @State private var textWidth: CGFloat = 0
    @State private var boxWidth: CGFloat = 0
    @State private var shifted = false

    private var overflow: CGFloat { max(0, textWidth - boxWidth) }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(Color("TextColor"))
            .lineLimit(1)
            .fixedSize()
            .background(GeometryReader { g in Color.clear.onAppear { textWidth = g.size.width } })
            .offset(x: shifted ? -overflow : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GeometryReader { g in Color.clear.onAppear { boxWidth = g.size.width } })
            .clipped()
            .onChange(of: overflow) { _, value in
                guard value > 1 else { return }
                withAnimation(.linear(duration: Double(value) / 35).delay(2).repeatForever(autoreverses: true)) {
                    shifted = true
                }
            }
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
