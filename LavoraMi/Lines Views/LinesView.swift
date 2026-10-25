//
//  LinesView.swift
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

struct LinesView: View {
    @Environment(\.openURL) private var openURLAction
    @ObservedObject var viewModel: WorkViewModel
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("showRecentSearches") var showRecentSearches: Bool = true
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true

    @State private var searchInput: String = ""
    @State private var selectedURL: URL?
    @State private var showDeletePopUp: Bool = false
    @FocusState private var isSearchFocused: Bool

    @StateObject private var adMobManager = AdMobManager(totalDesired: 2)
    @ObservedObject private var consentManager = ConsentManager.shared
    @State private var adsRequested: Bool = false

    private var shouldShowAdsAfterRecent: Bool {
        showRecentSearches && recentlySearchedLines.count >= 2
    }

    @ViewBuilder
    private var supportLavoraMiSection: some View {
        if !adMobManager.nativeAds.isEmpty {
            Section {
                ForEach(Array(adMobManager.nativeAds.enumerated()), id: \.offset) { _, ad in
                    CompactNativeAdView(nativeAd: ad)
                        .frame(height: 60)
                }
            } header: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Supporta LavoraMi")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.primary)
                        .textCase(nil)

                    Text("Aiutaci a sostenere LavoraMi!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
        }
    }

    private func requestLinesAdsIfNeeded() {
        guard consentManager.isReady, !adsRequested else { return }
        if let adUnitID = Bundle.main.infoDictionary?["AdUnitID"] as? String {
            adsRequested = true
            adMobManager.loadNativeAds(adUnitID: adUnitID)
        }
    }

    // MARK: - Search helpers
    private func matches(_ line: LineInfo, query: String) -> Bool {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return true }
        
        let typeKeywords: [String: [String]] = [
            "Metro": ["metro", "metropolitana", "m"],
            "Minimetro": ["minimetro", "ospedale", "h", "san raffaele"],
            "Suburbano": ["suburbano", "s"],
            "Regio express": ["regio", "express", "re"],
            "Regionale": ["regio", "regionale", "r"],
            String(localized: .tram): ["tram", "tranvía", "t"],
            String(localized: .filobus): ["filobus", "9"],
            "Movibus": ["bus", "movibus", "z"],
            "Nordest Trasporti": ["z", "bus", "net"],
            "STAR Mobility": ["bus", "star", "z"],
            "STAV": ["stav", "bus", "z"],
            "Autoguidovie": ["autoguidovie", "bus", "z"],
            "Malpensa Express": ["malpensa", "malpensa express", "express", "mxp"]
        ]
        
        let name = line.name.lowercased()
        let type = line.type.lowercased()
        let tokens = q.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
        
        for token in tokens {
            if name.contains(token) { continue }
            if type.contains(token) { continue }
            let hasNumbers = token.rangeOfCharacter(from: .decimalDigits) != nil
            if !hasNumbers,
               let synonyms = typeKeywords[line.type]?.map({ $0.lowercased() }),
               synonyms.contains(where: { token.hasPrefix($0) || $0.hasPrefix(token) }) {
                continue
            }
            if token.allSatisfy({ $0.isNumber }) && name.contains(token) { continue }
            
            return false
        }
        return true
    }

    private func filtered(_ items: [LineInfo]) -> [LineInfo] {
        guard !searchInput.isEmpty else { return items }
        return items.filter { matches($0, query: searchInput) }
    }

    var filteredMetros: [LineInfo] { filtered(metros) }
    var filteredMinimetro: [LineInfo] { filtered([minimetro]) }
    var filteredSuburban: [LineInfo] { filtered(suburban) }
    var filteredRegioExpress: [LineInfo] { filtered(regioExpress) }
    var filteredRegional: [LineInfo] { filtered(regionalLines) }
    var filteredTrams: [LineInfo] { filtered(trams) }
    var filteredFilobus: [LineInfo] { filtered(filobus) }
    var filteredMovibus: [LineInfo] { filtered(bus) }
    var filteredNET: [LineInfo] { filtered(net) }
    var filteredSTAR: [LineInfo] { filtered(star) }
    var filteredSTAV: [LineInfo] { filtered(stav) }
    var filteredAutoguidovie: [LineInfo] { filtered(autoguidovie) }
    var filteredCrossBorders: [LineInfo] { filtered(crossBorderLines) }
    var filteredMalpensaExpress: [LineInfo] { filtered(malpensaExpress) }
    
    struct RecentLine: Identifiable, Codable, Hashable {
        let id: UUID
        let name: String
        let branches: String
        let type: String
        let waitMinutes: String
        let accessibilityStatus: String
        
        init(from lineInfo: LineInfo) {
            self.id = lineInfo.id
            self.name = lineInfo.name
            self.branches = lineInfo.branches
            self.type = lineInfo.type
            self.waitMinutes = lineInfo.waitMinutes
            self.accessibilityStatus = lineInfo.accessibilityStatus
        }
    }
    
    @AppStorage("recentlySearchedLinesData") private var recentlySearchedLinesData: Data = Data()

    var recentlySearchedLines: [RecentLine] {
        get { (try? JSONDecoder().decode([RecentLine].self, from: recentlySearchedLinesData)) ?? [] }
        set { recentlySearchedLinesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    func fullLineInfo(for name: String) -> LineInfo? {
        let groups: [[LineInfo]] = [
            metros, [minimetro], suburban, regioExpress, regionalLines,
            crossBorderLines, malpensaExpress, trams, filobus, bus,
            net, stav, star, autoguidovie
        ]
        
        return groups.joined().first { $0.name == name }
    }

    func addToRecent(_ line: LineInfo) {
        var recent = recentlySearchedLines
        recent.removeAll { $0.name == line.name }
        recent.insert(RecentLine(from: line), at: 0)
        if recent.count > 5 { recent = Array(recent.prefix(5)) }
        recentlySearchedLinesData = (try? JSONEncoder().encode(recent)) ?? Data()
    }
    
    var metros: [LineInfo] {
        [
            LineInfo(name: "M1", branches: "Sesto F.S. - Rho Fiera / Bisceglie", type: "Metro", waitMinutes: "Sesto FS: 3 min | Rho/Bisceglie: 7-8 min", stations: MetroStationsDB.stationsM1, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M2", branches: "Gessate / Cologno - Assago / Abbiategrasso", type: "Metro", waitMinutes: "Gessate: 12-15 min | Assago: 9-10 min", stations: MetroStationsDB.stationsM2, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M3", branches: "Comasina - San Donato", type: "Metro", waitMinutes: "4-5 min", stations: MetroStationsDB.stationsM3, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M4", branches: "Linate Aeroporto - San Cristoforo", type: "Metro", waitMinutes: "2-3 min",stations: MetroStationsDB.stationsM4, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M5", branches: "Bignami - San Siro Stadio", type: "Metro", waitMinutes: "4 min", stations: MetroStationsDB.stationsM5, accessibilityStatus: String(localized: .lineaAccessibile))
        ]
    }
    
    var minimetro: LineInfo = LineInfo(name: "H", branches: "Cascina Gobba - Osp. San Raffaele", type: "Minimetro San Raffaele", waitMinutes: "10 min", stations: MetroStationsDB.hStations, accessibilityStatus: String(localized: .lineaAccessibile))
    
    var suburban: [LineInfo] {
        [
            LineInfo(name: "S1", branches: "Saronno - Lodi", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS1, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S2", branches: "Mariano Comense - Milano Rogoredo", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS2,  accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S3", branches: "Saronno - Milano Cadorna", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS3, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S4", branches: "Camnago Lentate - Milano Cadorna", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS4, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S5", branches: "Varese - Treviglio", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS5, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S6", branches: "Novara - Pioltello-Limito / Treviglio", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS6, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S7", branches: "Lecco - Milano Porta Garibaldi", type: String(localized: .suburbano), waitMinutes: "30 min - 1 \(String(localized: .ora))", stations: SuburbanStationsDB.stationsS7, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "S8", branches: "Lecco - Carnate - Milano Porta Garibaldi", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS8, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "S9", branches: "Saronno - Albairate Vermezzo", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS9, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "S11", branches: "Rho - Como S. Giovanni", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS11, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S12", branches: "Melegnano - Milano Bovisa", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS12, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S13", branches: "Garbagnate Milanese - Pavia", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS13, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S19", branches: "Albairate Vermezzo - Milano Rogoredo", type: String(localized: .suburbano), waitMinutes: "30 min", stations: SuburbanStationsDB.stationsS19, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S31", branches: "Brescia - Iseo", type: String(localized: .suburbano), waitMinutes: "1 \(String(localized: .ora))", stations: SuburbanStationsDB.stationsS31, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile))
        ]
    }
    
    var regionalLines: [LineInfo] {
        [
            LineInfo(name: "R1", branches: "Bergamo - Brescia", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegionalStationsDB.r1, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R2", branches: "Bergamo - Treviglio", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r2, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R3", branches: "Brescia - Iseo - Breno", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r3, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R4", branches: "Brescia - Treviglio - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegionalStationsDB.r4, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "R5", branches: "Brescia - Cremona", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r5, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R6", branches: "Cremona - Treviglio", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r6, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R7", branches: "Lecco - Bergamo", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r7, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R8", branches: "Brescia - Piadena - Parma", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r8, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R9", branches: "Rovato - Bornato - Iseo", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r9, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R11", branches: "Colico - Chiavenna", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r11, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R12", branches: "Sondrio - Tirano", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r12, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R13", branches: "Lecco - Colico - Sondrio", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r13, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R14", branches: "Bergamo - Carnate - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegionalStationsDB.r14, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R15", branches: "Seregno - Carnate Usmate", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r15, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R16", branches: "Asso - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegionalStationsDB.r16, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R17", branches: "Como - Saronno - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegionalStationsDB.r17, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R18", branches: "Como - Molteno - Lecco", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r18, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R21", branches: "Luino - Gallarate - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r21, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R22", branches: "Varese - Saronno - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegionalStationsDB.r22, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "R23", branches: "Domodossola - Gallarate - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r23, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R24", branches: "Laveno - Sesto Calende", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r24, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R25", branches: "Novara - Mortara", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r25, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R27", branches: "Novara - Saronno - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegionalStationsDB.r27, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "R31", branches: "Mortara - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegionalStationsDB.r31, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R32", branches: "Mortara - Alessandria", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r32, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R33", branches: "Pavia - Voghera", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r33, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R34", branches: "Stradella - Pavia - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: RegionalStationsDB.r34, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R35", branches: "Pavia - Torreberetti - Alessandria", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r35, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R36", branches: "Pavia - Mortara - Vercelli", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r36, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R37", branches: "Pavia - Codogno", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r37, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R38", branches: "Piacenza - Lodi - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegionalStationsDB.r38, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "R39", branches: "Codogno - Cremona", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r39, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R40", branches: "Cremona - Mantova", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r40, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R41", branches: "Voghera - Piacenza", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegionalStationsDB.r41, accessibilityStatus: String(localized: .lineaNonAccessibile)),
        ]
    }
    
    var regioExpress: [LineInfo] {
        [
            LineInfo(name: "RE1", branches: "Laveno - Saronno - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegioExpressStationsDB.re1, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE2", branches: "Milano - Bergamo", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: RegioExpressStationsDB.re2, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "RE3", branches: "Brescia - Iseo - Edolo", type: "Regio Express", waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: RegioExpressStationsDB.re3, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE4", branches: "Domodossola - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: RegioExpressStationsDB.re4, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE5", branches: "Porto Ceresio - Varese - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: RegioExpressStationsDB.re5, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE6", branches: "Verona - Brescia - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: RegioExpressStationsDB.re6, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE7", branches: "Como - Saronno - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: RegioExpressStationsDB.re7, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE8", branches: "Tirano - Lecco - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: RegioExpressStationsDB.re8, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE11", branches: "Mantova - Codogno - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: RegioExpressStationsDB.re11, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE13", branches: "Asti/Arquata - Pavia - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: RegioExpressStationsDB.re13, accessibilityStatus: String(localized: .lineaAccessibile))
        ]
    }
    
    var crossBorderLines: [LineInfo] {
        [
            LineInfo(name: "S10", branches: "Airolo / Biasca - Como S. Giovanni", type: "TILO", waitMinutes: "1 \(String(localized: .ora)) - 45 min", stations: TiloStationsDB.tiloS10, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S20", branches: "Castione Arbedo - Locarno", type: "TILO", waitMinutes: "30 min", stations: TiloStationsDB.tiloS20, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S30", branches: "Bellinzona / Cadenazzo - Gallarate", type: "TILO", waitMinutes: "2 \(String(localized: .ore))", stations: TiloStationsDB.tiloS30, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S40", branches: "Como S. Giovanni - Varese", type: "TILO", waitMinutes: "1 \(String(localized: .ora))", stations: TiloStationsDB.tiloS40, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S50", branches: "Airolo / Biasca - Malpensa Aeroporto T2", type: "TILO", waitMinutes: "1 \(String(localized: .ora))", stations: TiloStationsDB.tiloS50, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S90", branches: "Bellinzona - Mendrisio", type: "TILO", waitMinutes: "30 min", stations: TiloStationsDB.tiloS90, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE80", branches: "Locarno - Milano Centrale", type: "TILO", waitMinutes: "30 min - 1 \(String(localized: .ora))", stations: TiloStationsDB.tiloRE80, accessibilityStatus: String(localized: .lineaAccessibile))
        ]
    }
    
    var malpensaExpress: [LineInfo] {
        [
            LineInfo(name: "MXP1", branches: "Gallarate - Malpensa T2 - Milano Centrale", type: "Malpensa Express 1", waitMinutes: "30 min", stations: MalpensaExpressStationsDB.mxp1, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "MXP2", branches: "Malpensa T2 - Milano Cadorna", type: "Malpensa Express 2", waitMinutes: "30 min", stations: MalpensaExpressStationsDB.mxp2, accessibilityStatus: String(localized: .lineaAccessibile)),
        ]
    }
    
    var trams: [LineInfo] {
        [
            LineInfo(name: "1", branches: "Roserio (Ospedale Sacco) - Greco", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram1, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "2", branches: "P.Le Negrelli - P.Za Bausan", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram2, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "3", branches: "Duomo M1 M3 - Gratosoglio", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram3, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "4", branches: "Cairoli M1 - Niguarda (Parco Nord)", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram4, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "5", branches: "Niguarda Ospedale - Ortica", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram5, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "7", branches: "P.Le Lagosta - Q.Re Adriano", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram7, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "9", branches: "Centrale FS M2 M3 - P.Ta Genova M2", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram9, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "10", branches: "P.Za XXIV Maggio - V.Le Lunigiana", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram10, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "12", branches: "V.Le Molise - Roserio (Ospedale Sacco)", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram12, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "14", branches: "Lorenteggio - Cimitero Maggiore", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram14, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "15", branches: "Duomo M1 M3 - Rozzano (Via G. Rossa)", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram15, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "16", branches: "San Siro Stadio M5 - Via Monte Velino", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram16, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "19", branches: "P.Za Castelli - Lambrate FS M2", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram19, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "24", branches: "P.Za Fontana - Vigentino", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram24, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "27", branches: "V.Le Ungheria - P.Za Fontana", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram27, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "31", branches: "Bicocca M5 - Cinisello (1° Maggio)", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram31, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "33", branches: "P.Le Lagosta - Rimembranze di Lambrate", type: String(localized: .tram), waitMinutes: "5-20 min", stations: TramStationsDB.tram33, accessibilityStatus: String(localized: .lineaNonAccessibile)),
        ]
    }
    
    var filobus: [LineInfo] {
        [
            LineInfo(name: "90", branches: "\(String(localized: .circolareDestra)) (Lotto M1 M5 - Lodi M3)", type: String(localized: .filobus), waitMinutes: "4-6 min", stations: FilobusStationsDB.filobus90, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "91", branches: "\(String(localized: .circolareSinistra)) (Lodi M3 - Lotto M1 M5)", type: String(localized: .filobus), waitMinutes: "4-6 min", stations: FilobusStationsDB.filobus91, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "92", branches: "Via Varè (Bovisa FN) - Lodi M3", type: String(localized: .filobus), waitMinutes: "7-10 min", stations: FilobusStationsDB.filobus92, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "93", branches: "V.Le Omero - Lambrate FS", type: String(localized: .filobus), waitMinutes: "10-12 min", stations: FilobusStationsDB.filobus93, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile))
        ]
    }
    
    var bus : [LineInfo] {
        [
            LineInfo(name: "z601", branches: "Legnano - Rho - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ601, accessibilityStatus: ""),
            LineInfo(name: "z602", branches: "Legnano - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ602, accessibilityStatus: ""),
            LineInfo(name: "z603", branches: "Nerviano/S.Vittore - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ603, accessibilityStatus: ""),
            LineInfo(name: "z6C3", branches: "Vittore Olona - Cerro Maggiore - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ6C3, accessibilityStatus: ""),
            LineInfo(name: "z606", branches: "Cerro Maggiore - Rho/Europa", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ606, accessibilityStatus: ""),
            LineInfo(name: "z611", branches: "Legnano - Canegrate - Parabiago", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ611, accessibilityStatus: ""),
            LineInfo(name: "z612", branches: "Legnano - Lainate - Arese (Il CENTRO)", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ612, accessibilityStatus: ""),
            LineInfo(name: "z616", branches: "Pregnana Milanese - Rho", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ616, accessibilityStatus: ""),
            LineInfo(name: "z617", branches: "Origgio / Lainate - Molino Dorino M1 ", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ617, accessibilityStatus: ""),
            LineInfo(name: "z618", branches: "Vanzago - Pogliano M. - Rho", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ618, accessibilityStatus: ""),
            LineInfo(name: "z619", branches: "Lainate - Plesso IST Maggiolini", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ619, accessibilityStatus: ""),
            LineInfo(name: "z620", branches: "Magenta - Vittuone - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ620, accessibilityStatus: ""),
            LineInfo(name: "z621", branches: "Cuggiono - Ossona - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ621, accessibilityStatus: ""),
            LineInfo(name: "z622", branches: "Cuggiono - Ossona - Cornaredo", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ622, accessibilityStatus: ""),
            LineInfo(name: "z625", branches: "Busto Arsizio - Busto Garolfo", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ625, accessibilityStatus: ""),
            LineInfo(name: "z627", branches: "Castano Primo - Legnano", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ627, accessibilityStatus: ""),
            LineInfo(name: "z636", branches: "Nosate - Legnano", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ636, accessibilityStatus: ""),
            LineInfo(name: "z641", branches: "Castano Primo - Magenta", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ641, accessibilityStatus: ""),
            LineInfo(name: "z642", branches: "Magenta - Legnano", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ642, accessibilityStatus: ""),
            LineInfo(name: "z643", branches: "Vittuone - Parabiago", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ643, accessibilityStatus: ""),
            LineInfo(name: "z644", branches: "Arconate - Parabiago", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ644, accessibilityStatus: ""),
            LineInfo(name: "z646", branches: "Magenta - Castano Primo", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ646, accessibilityStatus: ""),
            LineInfo(name: "z647", branches: "Cornaredo - Castano Primo", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ647, accessibilityStatus: ""),
            LineInfo(name: "z649", branches: "Magenta - Arluno - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: MovibusStationsDB.movibusZ649, accessibilityStatus: "")
        ]
    }
    
    var net: [LineInfo] {
        [
            LineInfo(name: "z301", branches: "Milano Lampugnano M1 - Sesto FS M1 - Bergamo", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z304", branches: "Cologno Nord M2 - Brugherio", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z305", branches: "Cologno Nord M2 - Carugate - Villa Fiorita M2", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z307", branches: "Cologno Nord M2 - Vimercate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z309", branches: "Cassano D'Adda FS - Trezzo sull'Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z310", branches: "Gessate M2 - Trezzo sull'Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z311", branches: "Gessate M2 - Vaprio d'Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z312", branches: "Gessate M2 - Vimercate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z313", branches: "Gessate M2 - Paderno D'Adda FS", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z314", branches: "Gessate M2 - Monza FS", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z315", branches: "Gorgonzola M2 - Vimercate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z317", branches: "Vimercate - Arcore FS - Correzzana", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z318", branches: "Vimercate - Carnate - Usmate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z319", branches: "Arcore FS - Vimercate - Carnate FS", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z321", branches: "Monza FS - Vimercate - Porto d’Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z322", branches: "Cologno Nord M2 - Vimercate - Porto d'Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z323", branches: "Cologno Nord M2 - Vimercate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
        ]
    }
    
    var star: [LineInfo] {
        [
            LineInfo(name: "z501", branches: "Milano Famagosta - Binasco", type: "STAR Mobility", waitMinutes: "", stations: STARMobilityStationsDB.starZ501, accessibilityStatus: ""),
            LineInfo(name: "z509", branches: "Motta Visconti - Milano Famagosta", type: "STAR Mobility", waitMinutes: "", stations: STARMobilityStationsDB.starZ509, accessibilityStatus: ""),
            LineInfo(name: "z510", branches: "Milano Famagosta - Lacchiarella - Giussago", type: "STAR Mobility", waitMinutes: "", stations: STARMobilityStationsDB.starZ510, accessibilityStatus: ""),
            LineInfo(name: "z515", branches: "Milano Famagosta - Zibido", type: "STAR Mobility", waitMinutes: "", stations: STARMobilityStationsDB.starZ515, accessibilityStatus: ""),
            LineInfo(name: "z516", branches: "Milano Famagosta - Rosate - Besate", type: "STAR Mobility", waitMinutes: "", stations: STARMobilityStationsDB.starZ516, accessibilityStatus: "")
        ]
    }
    
    var stav: [LineInfo] {
        [
            LineInfo(name: "z551", branches: "Abbiategrasso Vittorio Veneto - Bisceglie M1", type: "STAV", waitMinutes: "", stations: STAVStationsDB.stavZ551, accessibilityStatus: ""),
            LineInfo(name: "z552", branches: "Abbiategrasso Vittorio Veneto - S. Stefano Ticino", type: "STAV", waitMinutes: "", stations: STAVStationsDB.stavZ552, accessibilityStatus: ""),
            LineInfo(name: "z553", branches: "Abbiategrasso - Rosate - Milano Romolo", type: "STAV", waitMinutes: "", stations: STAVStationsDB.stavZ553, accessibilityStatus: ""),
            LineInfo(name: "z554", branches: "Albairate - Albairate Vermezzo FS - Bubbiano", type: "STAV", waitMinutes: "", stations: STAVStationsDB.stavZ554, accessibilityStatus: ""),
            LineInfo(name: "z555", branches: "Abbiategrasso Vittorio Veneto - Binasco/Rosate", type: "STAV", waitMinutes: "", stations: STAVStationsDB.stavZ555, accessibilityStatus: ""),
            LineInfo(name: "z556", branches: "Abbiategrasso FS - Motta Visconti", type: "STAV", waitMinutes: "", stations: STAVStationsDB.stavZ556, accessibilityStatus: ""),
            LineInfo(name: "z557", branches: "Gaggiano De Gasperi - Gaggiano FS - San Vito", type: "STAV", waitMinutes: "", stations: STAVStationsDB.stavZ557, accessibilityStatus: ""),
            LineInfo(name: "z559", branches: "Abbiategrasso FS - Magenta FS", type: "STAV", waitMinutes: "", stations: STAVStationsDB.stavZ559, accessibilityStatus: ""),
            LineInfo(name: "z560", branches: "Abbiategrasso FS - Corsico - Bisceglie M1", type: "STAV", waitMinutes: "", stations: STAVStationsDB.stavZ560, accessibilityStatus: "")
        ]
    }

    var autoguidovie: [LineInfo] {
        [
            LineInfo(name: "z401", branches: "Melzo FS - Vignate - Villa Fiorita M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z402", branches: "Cernusco M2 - Pioltello FS - S.Felice", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z403", branches: "Gorgonzola M2 - Melzo (Circolare)", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z404", branches: "Melzo FS - Inzago - Gessate M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z405", branches: "Gessate M2 - Cassano d'Adda - Treviglio", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z407", branches: "Gorgonzola M2 - Truccazzano - Cassano", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z409", branches: "Rodano - S. Felice - Linate Aeroporto", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z410", branches: "Pantigliate - Peschiera - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z411", branches: "Melzo FS - Settala - Pantigliate - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z412", branches: "Paullo - Peschiera - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z413", branches: "Paullo - Tribiano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z415", branches: "Melegnano - Dresano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z418", branches: "S.Zenone FS - Melegnano", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z419", branches: "Paullo - Melzo - Gorgonzola M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z420", branches: "Vizzolo - Melegnano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z431", branches: "Melegnano FS - Carpiano/Cerro L. (Circolare)", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z432", branches: "Melegnano FS - Vizzolo Ospedale", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),

            LineInfo(name: "z203", branches: "Muggiò - Monza FS - Cologno Nord M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z205", branches: "Limbiate - Varedo - Monza FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z209", branches: "Cesano FN - Desio - Lissone", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z219", branches: "Monza FS - Muggiò - Paderno Dugnano", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z221", branches: "Sesto S.G. - Monza FS - Mariano", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z222", branches: "Monza FS - Cinisello B. - Sesto S.G.", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z225", branches: "Sesto S.G. - Cinisello B. - Nova M.se", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z227", branches: "Monza H/Lissone FS - Muggiò - Sesto S.G.", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z228", branches: "Seregno FS - Lissone - Monza FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z229", branches: "Paderno ITC - Cusano - Cinisello B.", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z231", branches: "Carate - Giussano - Seregno FS - Desio", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z232", branches: "Desio - Seregno - Carate - Besana FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z233", branches: "Triuggio - Albiate - Seregno FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z234", branches: "Vedano - Lissone - Muggiò", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z238", branches: "Lissone FS - Monza Polo Istituzionale", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z242", branches: "Desio - Seregno FS - Monticello", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z250", branches: "Lissone FS - Cesano FN - Limbiate", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z251", branches: "Desio FS - Limbiate - Cesano FN", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: "")
        ]
    }
    
    var body: some View {
        NavigationStack{
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Cerca per tipo o numero...", text: $searchInput)
                    .foregroundColor(.primary)
                    .autocorrectionDisabled(true)
                    .focused($isSearchFocused)
                    .submitLabel(.done)
                
                if !searchInput.isEmpty {
                    Button(action: {
                        searchInput = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 5)
            List {
                if(showRecentSearches) {
                    Section(){
                        if recentlySearchedLines.isEmpty && searchInput.isEmpty {
                            Text("Nessuna linea cercata di recente.")
                        } else {
                            if(searchInput.isEmpty) {
                                ForEach(recentlySearchedLines) { recent in
                                    if let lineInfo = fullLineInfo(for: recent.name) {
                                        LineRow(
                                            line: lineInfo.name,
                                            typeOfTransport: lineInfo.type,
                                            branches: lineInfo.branches,
                                            waitMinutes: lineInfo.waitMinutes,
                                            accessibilityStatus: lineInfo.accessibilityStatus,
                                            stations: lineInfo.stations,
                                            viewModel: viewModel
                                        )
                                    }
                                }
                            }
                        }
                    }
                    header:{
                        if(searchInput.isEmpty) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "text.magnifyingglass")
                                            .foregroundStyle(.primary)
                                        Text("Cercate di recente")
                                            .font(.title3)
                                            .bold()
                                            .foregroundStyle(.primary)
                                            .textCase(nil)
                                    }
                                    
                                    Text("In base alle tue ricerche")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .textCase(nil)
                                }
                                Spacer()
                                if(!recentlySearchedLines.isEmpty) {
                                    Button(action: {
                                        showDeletePopUp = true
                                        if(feedbacksEnabled){
                                            HapticManager.shared.trigger()
                                        }
                                    }) {
                                        Image(systemName: "delete.backward.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.bottom, 4)
                                }
                            }
                        }
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))

                    if searchInput.isEmpty && shouldShowAdsAfterRecent {
                        supportLavoraMiSection
                    }
                }
                lineSection(lines: filteredMetros, title: "Linee Metropolitane", subtitle: "ATM", infoURL: "https://giromilano.atm.it/assets/images/schema_rete_metro.jpg")
                    .listSectionSpacing(10)

                if let h = filteredMinimetro.first {
                    LineRow(line: h.name, typeOfTransport: h.type, branches: h.branches, waitMinutes: h.waitMinutes, accessibilityStatus: h.accessibilityStatus, stations: h.stations, viewModel: viewModel, onTap: { addToRecent(h) })
                        .listRowBackground(Color(uiColor: .secondarySystemBackground))
                }
                
                if searchInput.isEmpty && !shouldShowAdsAfterRecent {
                    supportLavoraMiSection
                }

                lineSection(lines: filteredSuburban, title: "Linee Suburbane", subtitle: "Trenord", infoURL: "https://www.trenord.it/linee-e-orari/circolazione/le-nostre-linee/")
                lineSection(lines: filteredRegional, title: "Linee Regionali", subtitle: "Trenord", infoURL: "https://www.trenord.it/linee-e-orari/circolazione/le-nostre-linee/")
                lineSection(lines: filteredRegioExpress, title: "Linee Regio Express", subtitle: "Trenord", infoURL: "https://www.trenord.it/linee-e-orari/circolazione/le-nostre-linee/")
                lineSection(lines: filteredCrossBorders, title: "Linee Transfrontaliere", subtitle: "TILO", infoURL: "https://www.tilo.ch")
                lineSection(lines: filteredMalpensaExpress, title: "Linee Malpensa Express", subtitle: "Trenord", infoURL: "https://www.malpensaexpress.it")
                lineSection(lines: filteredTrams, title: "Linee Tranviarie", subtitle: "ATM", infoURL: "https://www.atm.it/it/AltriServizi/Trasporto/Documents/Carta%20ATM_WEB_2025.11.pdf")
                lineSection(lines: filteredFilobus, title: "Linee Filoviarie", subtitle: "ATM", infoURL: "https://www.atm.it/it/AltriServizi/Trasporto/Documents/Carta%20ATM_WEB_2025.11.pdf")
                lineSection(lines: filteredMovibus, title: "Linee di Bus", subtitle: "Movibus", infoURL: "https://movibus.it/news/")
                lineSection(lines: filteredNET, title: "Linee di Bus", subtitle: "Nordest Trasporti (NET)", infoURL: "https://www.nordesttrasporti.it/percorsi-e-orari/")
                lineSection(lines: filteredSTAR, title: "Linee di Bus", subtitle: "STAR Mobility", infoURL: "https://starmobility.it/orari-autobus/")
                lineSection(lines: filteredSTAV, title: "Linee di Bus", subtitle: "STAV", infoURL: "https://stavautolinee.it/reti-servite/")
                lineSection(lines: filteredAutoguidovie, title: "Linee di Bus", subtitle: "Autoguidovie", infoURL: "https://autoguidovie.it/it/avvisi")
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
            }
            .navigationTitle("Linee")
            .scrollContentBackground(.hidden)
            .overlay {
                let allFiltered: [[LineInfo]] = [
                    filteredMetros, filteredMinimetro, filteredSuburban, filteredRegioExpress,
                    filteredRegional, filteredCrossBorders, filteredMalpensaExpress,
                    filteredTrams, filteredFilobus, filteredMovibus, filteredNET,
                    filteredSTAV, filteredSTAR, filteredAutoguidovie
                ]
                if allFiltered.allSatisfy({ $0.isEmpty }) {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.primary)
                        VStack(spacing: 8) {
                            Text("Nessuna linea trovata per: \"\(searchInput)\"")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                            Text("Prova a cercarne un'altra, come: \(generateRandomLine()).")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .containerRelativeFrame(.vertical)
                }
            }
            .alert("Sei sicuro?", isPresented: $showDeletePopUp) {
                Button("Annulla", role: .cancel){showDeletePopUp = false}
                Button("Continua"){recentlySearchedLinesData = Data()}
            } message: {
                Text("Sei sicuro di voler cancellare le ricerche recenti?")
            }
            .onAppear {
                requestLinesAdsIfNeeded()
            }
            .onChange(of: consentManager.isReady) { _, ready in
                if ready {
                    requestLinesAdsIfNeeded()
                }
            }
        }
    }
    
    @ViewBuilder
    private func lineSection(lines: [LineInfo], title: LocalizedStringKey, subtitle: LocalizedStringKey, infoURL: String) -> some View {
        Section {
            ForEach(lines, id: \.id) { line in
                LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
            }
        } header: {
            if !lines.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(.primary)
                            .textCase(nil)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                    .padding(.bottom, 4)
                    Spacer()
                    Button(action: { openInfo(infoURL) }) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .listRowBackground(Color(uiColor: .secondarySystemBackground))
    }

    private func openInfo(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        if howToOpenLinks == .inApp { selectedURL = url } else { openURLAction(url) }
    }
}
