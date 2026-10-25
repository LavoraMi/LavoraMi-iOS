//
//  LineDetailView.swift
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

struct LineDetailView: View {
    let lineName: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String
    
    let workScheduled: Int
    let workNow: Int
    let viewModel: WorkViewModel
    
    let stations: [MetroStation]
    let accessibilityStatus: String
    let isDetailed: Bool
    
    @AppStorage("selectedWidgetLine") private var selectedWidgetLine: String = ""
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("alreadySeenPopUp") var alreadySeenPopUp: Bool = false
    @AppStorage("alreadySeenPopUpLines") var alreadySeenPopUpLines: Bool = false
    @AppStorage("seenPopUpCreateAccount") var seenPopUpCreateAccount: Bool = false
    @AppStorage("seenPopUpInfoMovibus") var seenPopUpInfoMovibus: Bool = false
    @AppStorage("seenPopUpInfoTram") var seenPopUpInfoTram: Bool = false
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @StateObject private var networkManager = NetworkMonitor()
    @StateObject private var authManager = AuthManager()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURLAction
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @State private var selectedURL: URL?
    @State private var showErrorDBSavePopUp: Bool = false
    
    private enum LineDetailTab { case map, works, interchanges, arrivi }
    @State private var selectedTab: LineDetailTab = .map
    @State private var openPopUpWidget: Bool = false
    @State private var openPopUpLines: Bool = false
    @State private var openPopUpMovibus: Bool = false
    @State private var openPopUpTram: Bool = false
    @State private var openInfoAccessibility: Bool = false
    @State private var openInfoBusOperation: Bool = false
    @State private var openInfoLineSuspended: Bool = false
    @State private var openInfoSlowdowns: Bool = false
    @State private var openInfoTimetables: Bool = false
    @State private var openPopUpInfoStatus: Bool = false
    @State private var selectedBranch: String? = nil
    @State private var modalitaRitorno: Bool = false
    @State private var linesWithBlackText: [String] = ["M3", "M5", "S5", "S6", "S8", "S11", "S12", "S31", "S90"]
    @State private var busWithMultipleDirections: [String] = ["z301", "z515", "z555", "z619", "z647"]
    @State private var showPopUpAccount: Bool = false
    @State private var showPopUpMultipleRoutes: Bool = false
    
    @State private var routeData: GTFSRoute? = nil
    @State private var isLoadingArrivals = false
    @State private var arrivalsErrorMessage: String? = nil
    @State private var selectedStopId: String? = nil
    @State private var selectedStopName: String = ""
    @State private var currentTime = Date()
    @State private var selectedStationIndex: Int?
    private let arrivalsTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    @State private var tramStopSelection: TramStopSelection? = nil
    private var isTram: Bool {
        typeOfTransport.contains(String(localized: .tram))
    }
    
    private var cdnURL: URL? {
        URL(string: "https://cdn.lavorami.it/gtfs/\(lineName.uppercased()).json")
    }
    
    let interchanges = InterchangesDB.interchangesBus

    var activeInterchange: InterchangeStation? {
        interchanges.first { station in
            station.linesToShow.contains(lineName)
        }
    }
    
    var activeStations: [MetroStation] {stations.filter { !$0.branch.lowercased().contains("- new") }}
    private var centerIndex: Int {max(0, activeStations.count / 2)}
    private var centerCoordinate: CLLocationCoordinate2D {
        stations.isEmpty ? CLLocationCoordinate2D(latitude: 45.46443, longitude: 9.18927) : activeStations[centerIndex].coordinate
    }
    
    private var lombardyBounds: MapCameraBounds {
        MapCameraBounds(
            centerCoordinateBounds: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 45.46443, longitude: 9.18927),
                span: MKCoordinateSpan(latitudeDelta: 2.1, longitudeDelta: 3.2)
            ),
            minimumDistance: 1000,
            maximumDistance: 175000
        )
    }
    
    private func isStationClosed(_ stationName: String) -> Bool {
        viewModel.stazioniChiuse.contains { entry in
            let parts = entry.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return false }
            let entryName = parts[0].trimmingCharacters(in: .whitespaces)
            let entryLine = parts[1].trimmingCharacters(in: .whitespaces)
            return entryName.caseInsensitiveCompare(stationName) == .orderedSame
                && entryLine.caseInsensitiveCompare(lineName) == .orderedSame
        }
    }
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var onAppear: (() -> Void)? = nil

    private var mainStations: [MetroStation] {
        if hasRitornoBranch {
            return stationsForCurrentDirection
        }
        
        let filtered = stationsForCurrentDirection
        let main = filtered.filter { $0.branch == "Main" }
        return main.isEmpty ? filtered : main
    }
    private var isBusLineForRoute: Bool {typeOfTransport == "Movibus" || typeOfTransport == "STAV" || typeOfTransport == "STAR Mobility"}
    private var hasRitornoBranch: Bool {stations.contains { $0.branch.localizedCaseInsensitiveContains("Ritorno") }}

    private var stationsForCurrentDirection: [MetroStation] {
        stations.filter { station in
            let branch = station.branch
            let branchHasRitorno = branch.localizedCaseInsensitiveContains("Ritorno")
            let branchIsOnlyRitorno = branch.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare("Ritorno") == .orderedSame
            return modalitaRitorno ? branchHasRitorno : !branchIsOnlyRitorno
        }
    }

    private var direzioneMappaText: String? {
        guard isBusLineForRoute, hasRitornoBranch else { return nil }
        let filtrate = stationsForCurrentDirection.filter { $0.name != "NO_DRAW" }
        
        guard !filtrate.isEmpty else { return nil }
        let destinazione = modalitaRitorno ? filtrate.first?.name : filtrate.last?.name
        
        guard let destinazione else { return nil }
        return "→  \(destinazione)"
    }

    @State private var branchData: [(coords: [CLLocationCoordinate2D], isPlanned: Bool)] = []
    
    private var metroLineIndex: Int? {
        switch lineName {
            case "M1": return 0
            case "M2": return 1
            case "M3": return 2
            case "M4": return 3
            case "M5": return 4
            default: return nil
        }
    }
    
    private var metroStatusInfo: (text: String, color: Color, icon: String)? {
        guard let index = metroLineIndex,viewModel.orariChiusura.indices.contains(index),viewModel.orariApertura.indices.contains(index), viewModel.orariAperturaFestivi.indices.contains(index), viewModel.metroStatus.indices.contains(index) else { return nil }
        
        let closingTime = viewModel.orariChiusura[index]
        let openingTime = isGiornoFestivo() ? viewModel.orariAperturaFestivi[index] : viewModel.orariApertura[index]
        
        let status = isMetroChiusaOra(closingTime: closingTime, openingTime: openingTime) ? "Chiusa" : viewModel.metroStatus[index]
        
        switch status {
            case "Regolare":
                return (String(localized: .statoMetroRegolare), getColor(for: "M2"), "checkmark")
            case "Tratta Sospesa":
                return (String(localized: .statoMetroTrattaSospesa), .red, "exclamationmark.triangle.fill")
            case "Fermata Sospesa":
                return (String(localized: .statoMetroFermataSospesa), Color(red: 237/255, green: 156/255, blue: 26/255), "exclamationmark.triangle.fill")
            case "Fermate Sospese":
                return (String(localized: .statoMetroFermateSospese), Color(red: 237/255, green: 156/255, blue: 26/255), "exclamationmark.triangle.fill")
            case "Rallentata":
                return (String(localized: .statoMetroRallentata), Color(red: 237/255, green: 156/255, blue: 26/255), "clock.badge.exclamationmark.fill")
            case "Interrotta":
                return (String(localized: .statoMetroInterrotta), .red, "xmark.circle.fill")
            case "Info":
                return (String(localized: .statoMetroInfo), getColor(for: "RE80"), "info")
            case "Chiusa":
                return (String(localized: .statoMetroChiusa), getColor(for: "S12"), "moon.fill")
            default:
                return nil
        }
    }
    
    private func isGiornoFestivo() -> Bool {
        Calendar.current.component(.weekday, from: Date()) == 1
    }
    
    private func isMetroChiusaOra(closingTime: String, openingTime: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "it_IT")
        
        guard let parsedClosing = formatter.date(from: closingTime),
              let parsedOpening = formatter.date(from: openingTime) else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        
        func todayTime(from date: Date) -> Date {
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: now) ?? now
        }
        
        let closing = todayTime(from: parsedClosing)
        let opening = todayTime(from: parsedOpening)
        
        let isAfterOrEqualClosing = now >= closing
        let isBeforeOpening = now < opening
        
        if closing < opening {return isAfterOrEqualClosing && isBeforeOpening}
        else {return isAfterOrEqualClosing || isBeforeOpening}
    }

    private func computeBranchData() -> [(coords: [CLLocationCoordinate2D], isPlanned: Bool)] {
        guard let mainStart = stations.firstIndex(where: { $0.branch == "Main" }),
              let mainEnd = stations.lastIndex(where: { $0.branch == "Main" })
        else { return [] }

        struct Block {
            let branch: String
            let startIndex: Int
            let endIndex: Int
        }

        var blocks: [Block] = []
        var i = 0
        while i < stations.count {
            let branch = stations[i].branch
            let isEligible = branch != "Main" && !branch.localizedCaseInsensitiveContains("Ritorno")
            if isEligible {
                let start = i
                var j = i
                while j < stations.count && stations[j].branch == branch { j += 1 }
                blocks.append(Block(branch: branch, startIndex: start, endIndex: j - 1))
                i = j
            }
            else {i += 1}
        }

        var branchEndIndex: [String: Int] = [:]
        for block in blocks {
            branchEndIndex[block.branch] = block.endIndex
        }

        return blocks.compactMap { block -> (coords: [CLLocationCoordinate2D], isPlanned: Bool)? in
            let blockStations = Array(stations[block.startIndex...block.endIndex])
            let isPlanned = block.branch.lowercased().contains("new")
                         || block.branch.lowercased().contains("nuova")

            let junctionIdx: Int

            let baseBranch = block.branch
                .replacingOccurrences(of: " - New", with: "")
                .replacingOccurrences(of: " - Nuova", with: "")
                .trimmingCharacters(in: .whitespaces)

            if baseBranch != block.branch, let parentEnd = branchEndIndex[baseBranch] {
                junctionIdx = parentEnd
            }
            else if block.endIndex < mainStart {
                junctionIdx = mainStart
            }
            else {
                junctionIdx = mainEnd
            }

            let junction = stations[junctionIdx].coordinate
            
            if junctionIdx < block.startIndex {return ([junction] + blockStations.map(\.coordinate), isPlanned)}
            else {return (blockStations.map(\.coordinate) + [junction], isPlanned)}
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                tabBarSection
                
                switch selectedTab {
                    case .map:
                        mapTabContent
                    case .works:
                        worksTabContent
                    case .interchanges:
                        interchangesTabContent
                    case .arrivi:
                        arriviTabContent
                }
            }
            .padding(.top, -20)
            .onAppear {
                onAppear?()
                if (viewModel.linesSupportedGTFS.contains(lineName) || isTram) && routeData == nil {
                    loadArrivalsData()
                }
                
                if !isDetailed && selectedTab == .map {
                    selectedTab = .works
                }
                
                if(isBusLineForRoute && !seenPopUpInfoMovibus) {
                    seenPopUpInfoMovibus = true
                    openPopUpMovibus = true
                }
                
                if(isTram && !seenPopUpInfoTram) {
                    seenPopUpInfoTram = true
                    openPopUpTram = true
                }
            }
            .sheet(isPresented: $openInfoAccessibility) {
                InfoAccessibilityView(showInfoView: $openInfoAccessibility)
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea(.all)
            }
            .sheet(isPresented: $openPopUpMovibus) {
                StructedMovibusView()
            }
            .sheet(isPresented: $openPopUpTram) {
                StructedTramView()
            }
            .alert("Errore di connessione", isPresented: $showErrorDBSavePopUp) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Si è verificato un errore di connessione durante il salvataggio. Controlla la tua connessione ad Internet.")
            }
            .alert("Salva le tue linee", isPresented: $showPopUpAccount) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Lo sapevi che, creando un Account LavoraMi, puoi salvare le tue linee preferite per ritrovarle su tutti i tuoi dispositivi? Che aspetti! Crea un Account!")
            }
            .alert("Bus con più direzioni", isPresented: $showPopUpMultipleRoutes) {
                Button("Chiudi", role: .cancel) { showPopUpMultipleRoutes = false }
            } message: {
                Text("Questa linea è soggetta a rotte diverse in base alla fascia oraria. Consulta gli schermi informativi prima di salire sul pullman.")
            }
            .fullScreenCover(item: $tramStopSelection) { selection in
                StopDetailView(
                    lineName: lineName,
                    stopName: selection.name,
                    stations: stations,
                    interchanges: getInterchanges(line: lineName),
                    initialRoute: routeData,
                    lineColor: getColor(for: lineName),
                    stationsClosed: viewModel.stazioniChiuse
                )
            }
            .navigationTitle("Dettagli Linea")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func sortedStops(route: GTFSRoute) -> [(id: String, name: String)] {
        route.stops.map { ($0.key, $0.value.n) }.sorted { $0.name < $1.name }
    }

    private func selezionaFermataDaMappa(_ stationName: String) {
        if isTram {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            tramStopSelection = TramStopSelection(name: stationName)
            
            return
        }
        else {
            guard let route = routeData,
                  let match = route.stops.first(where: { $0.value.n.caseInsensitiveCompare(stationName) == .orderedSame })
            else { return }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            selectedStopId = match.key
            selectedStopName = match.value.n

            withAnimation {
                selectedTab = .arrivi
            }
        }
    }

    private func loadArrivalsData() {
        guard let url = cdnURL else { return }
        isLoadingArrivals = true
        Task {
            do {
                let route = try await GTFSHelper.load(from: url)
                await MainActor.run {
                    self.routeData = route
                    self.isLoadingArrivals = false
                    if self.selectedStopId == nil {
                        self.selectedStopId = sortedStops(route: route).first?.id
                    }
                }
            } catch {
                await MainActor.run {
                    self.arrivalsErrorMessage = "Errore nel caricamento dati."
                    self.isLoadingArrivals = false
                }
            }
        }
    }
}

extension LineDetailView {
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                if(lineName.contains("S") || (lineName == "MXP1" || lineName == "MXP2") || lineName == "RE80" || lineName.contains("RE")) {
                    Text((lineName.contains("MXP")) ? "MXP" : lineName)
                        .foregroundStyle(Color.white)
                        .font(.custom("TitilliumWeb-Bold", size: 40))
                        .padding(.vertical, 2)
                        .padding(.horizontal, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill((typeOfTransport == String(localized: .tram)) ? .orange : getColor(for: lineName))
                        )
                }
                else if (lineName.contains("M") && (lineName != "MXP1" || lineName != "MXP2")){
                    Text(lineName)
                        .foregroundStyle(Color.white)
                        .font(.custom("HelveticaNeue-Bold", size: 40))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill((typeOfTransport == String(localized: .tram)) ? .orange : getColor(for: lineName))
                        )
                }
                else {
                    Text(lineName)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 40, weight: .bold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 15)
                        .fixedSize()
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill((typeOfTransport == String(localized: .tram)) ? .orange : getColor(for: lineName))
                        )
                }
                
                if(lineName == "MXP1" || lineName == "MXP2"){
                    Text("Malpensa Express")
                        .font(.custom("TitilliumWeb-Bold", size: 30))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                else {
                    if(lineName.contains("S")) {
                        Text("\(typeOfTransport)")
                            .font(.custom("TitilliumWeb-Bold", size: 40))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    else if(lineName.contains("M") && (lineName != "MXP1" || lineName != "MXP2")) {
                        Text("\(typeOfTransport) \(lineName)")
                            .font(.custom("HelveticaNeue-Bold", size: 30))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    else if (!isDetailed || isBusLineForRoute || lineName == "H") {
                        Text("\(typeOfTransport)")
                            .font(.system(size: 30))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    else if(lineName.starts(with: "R")) {
                        Text("\(typeOfTransport)")
                            .font(.system(size: 30))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    else {
                        Text("\(typeOfTransport) \(lineName)")
                            .font(.system(size: 30))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button(action: {
                    if(selectedWidgetLine == lineName) {
                        selectedWidgetLine = ""
                        DataManager.shared.deleteSavedLine()
                    }
                    else {
                        DataManager.shared.setSavedLine(SavedLine(id: lineName, name: lineName, longName: typeOfTransport, iconTransport: getCurrentTransportIcon(for: typeOfTransport), worksNow: workNow, worksScheduled: workScheduled, isDeviatedLine: (viewModel.suburbanWithInterruptions.contains(lineName) || viewModel.regionalWithInterruptions.contains(lineName))))
                        selectedWidgetLine = lineName
                        
                        if(!alreadySeenPopUp){
                            alreadySeenPopUp = true
                            openPopUpWidget = true
                        }
                    }
                }){
                    if #available(iOS 18, *){
                        Image(systemName: (selectedWidgetLine == lineName) ? "widget.small" : "widget.small.badge.plus")
                            .foregroundStyle((selectedWidgetLine == lineName) ? .yellow : .gray)
                            .scaleEffect(1.5)
                    }
                    else {
                        Image(systemName: (selectedWidgetLine == lineName) ? "app.badge.checkmark" : "plus.viewfinder")
                            .foregroundStyle((selectedWidgetLine == lineName) ? .yellow : .gray)
                            .scaleEffect(1.5)
                    }
                }
                .alert("Linea attivata", isPresented: $openPopUpWidget) {
                    Button("OK", role: .cancel){}
                } message: {
                    Text("Linea impostata per essere vista sul Widget dell'app!")
                }
                Button(action: {
                    if(linesSelected.contains(lineName)) {
                        linesSelected.removeAll { $0 == lineName }
                    }
                    else {
                        if(!alreadySeenPopUpLines){
                            alreadySeenPopUpLines = true
                            openPopUpLines = true
                        }
                        
                        linesSelected.append(lineName)
                    }
                    
                    if(authManager.isLoggedIn()) {
                        Task {
                            let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                            
                            if(preferences.enable_your_lines) {
                                let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                showErrorDBSavePopUp = !res
                            }
                        }
                    }
                    else if (!seenPopUpCreateAccount){
                        seenPopUpCreateAccount = true
                        showPopUpAccount = true
                    }
                }){
                    Image(systemName: (linesSelected.contains(lineName)) ? "heart.fill" : "heart")
                        .foregroundStyle((linesSelected.contains(lineName)) ? Color(red: 1, green: 93 / 255, blue: 162 / 255) : .gray)
                        .scaleEffect(1.5)
                }
                .padding(.leading, 10)
                .alert("Linea salvata", isPresented: $openPopUpLines) {
                    Button("OK", role: .cancel){}
                } message: {
                    Text("La linea \(lineName) è stata aggiunta nella sezione \"Le tue linee\"!")
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("DIREZIONI:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .bold()
                
                Text(branches)
                    .font(.title3)
                    .multilineTextAlignment(.leading)
                
                if(busWithMultipleDirections.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .busConRotteDiverse),
                        icon: "arrow.branch",
                        action: {
                            showPopUpMultipleRoutes = true
                        }
                    )
                }
                
                if(viewModel.linesWithSlowdowns.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .lineaConRallentamenti),
                        icon: "clock.badge.exclamationmark.fill",
                        action: {
                            openInfoSlowdowns = true
                        }
                    )
                }
                
                if(viewModel.linesWithInaccurateTimetables.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .orariImprecisiBannerTitle),
                        icon: "person.badge.clock.fill",
                        action: {
                            openInfoTimetables = true
                        }
                    )
                }
                
                if(viewModel.suburbanWithInterruptions.contains(lineName)){
                    WarningBanner(
                        text: String(localized: .interruzioniGeneraleLavori),
                        icon: "",
                        action: {
                            let url = getSuburbanDeviationLink(line: lineName, viewModel: viewModel)
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            }
                            else {
                                openURLAction(url)
                            }
                        }
                    )
                }
                if(viewModel.regionalWithInterruptions.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .interruzioniGeneraleLavori),
                        icon: "",
                        action: {
                            let url = getRegionalDeviationLink(line: lineName, viewModel: viewModel)
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            }
                            else {
                                openURLAction(url)
                            }
                        }
                    )
                }
                if(viewModel.lineeSostituiteBus.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .lineSubWithBus),
                        icon: "bus.fill",
                        action: {
                            openInfoBusOperation = true
                        }
                    )
                }
                if(viewModel.lineeSospeseInteramente.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .lineSuspendedUppercased),
                        icon: "",
                        action: {
                            openInfoLineSuspended = true
                        }
                    )
                }
                if(viewModel.linesDeviated.contains(lineName)){
                    WarningBanner(
                        text: String(localized: .tramDeviations),
                        icon: "",
                        action: {
                            let url = getLineDeviationLink(line: lineName, viewModel: viewModel)
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            }
                            else {
                                openURLAction(url)
                            }
                        }
                    )
                }
            }
            
            if !waitMinutes.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("TEMPO DI ATTESA MEDIO:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .bold()
                    
                    Text(waitMinutes)
                        .font(.title3)
                        .multilineTextAlignment(.leading)
                    
                    if(lineName == "S2" || lineName == "S12" || lineName == "S19"){
                        Text("LA LINEA È ATTIVA SOLO NEI GIORNI LAVORATIVI")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .bold()
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text("FERMATA DI INTERSCAMBIO:")
                        .font(.caption).foregroundStyle(.secondary).bold()
                    if let station = activeInterchange {
                        Label(station.displayName, systemImage: station.typeOfInterchange)
                            .font(.title3).multilineTextAlignment(.leading)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(station.lines, id: \.self) { line in
                                    TransportBadge(line: line)
                                }
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "nosign")
                                .font(.title3)
                                .foregroundColor(Color.white)
                            Text("Nessuna fermata di interscambio.")
                                .font(.title3)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if(workNow != 1) {
                            Text("\(workNow) attuali,")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        else {
                            Text("\(workNow) attuale,")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        if(workScheduled != 1) {
                            Text("\(workScheduled) programmati.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        else {
                            Text("\(workScheduled) programmato.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                if isDetailed && accessibilityStatus != ""{
                    Spacer()
                    Divider()
                        .frame(height: 36)
                    HStack(spacing: 6) {
                        Image(systemName: "figure.roll")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                        Image(systemName: accessibilityStatus == String(localized: .lineaAccessibile) ? "checkmark.circle.fill" : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile) ? "exclamationmark.circle.fill" : "xmark.circle.fill"))
                            .font(.system(size: 18))
                            .foregroundColor(accessibilityStatus == String(localized: .lineaAccessibile) ? .green : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile) ? .yellow : .red))
                        Text(accessibilityStatus)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Button(action: {
                            openInfoAccessibility = true
                        }) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(.vertical, 3)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(.top, 10)
        .background(Color(uiColor: .systemBackground))
        .alert("Linea sostituita da Bus", isPresented: $openInfoBusOperation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Questa linea è attualmente sostituita interamente da Autobus e non c'è alcun treno a servire questa tratta. Il servizio è comunque garantito tra tutte le stazioni della linea.")
        }
        .alert("Linea Interamente Sospesa", isPresented: $openInfoLineSuspended) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Questa linea è stata interrotta per tutto il suo tragitto per via di lavori sulla tratta o rimodulazioni di orario. Per saperne di più, vai nella sezione \"Lavori\" della linea.")
        }
        .alert("Linea Rallentata", isPresented: $openInfoSlowdowns) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Su questa linea ci sono lavori attualmente in corso che potrebbero comportare anticipi o ritardi nell'arrivo a destinazione. Controlla la sezione \"Lavori\".")
        }
        .alert("Orari Imprecisi o Mancanti", isPresented: $openInfoTimetables) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Sul tragitto di questa linea ultimamente si sono conclusi lavori che limitavano corse o interrompevano il servizio. Tra pochi giorni potremmo ricevere gli orari aggiornati e rimuovere questa informazione.")
        }
    }
    
    private var isS12Dark: Bool { lineName == "S12" && colorScheme == .dark }

    private func tabBackground(isSelected: Bool) -> Color {
        let base: Color = isS12Dark ? Color.white : getColor(for: lineName)
        return isSelected ? base : base.opacity(0.15)
    }

    private func tabForeground(isSelected: Bool) -> Color {
        if isSelected {
            return linesWithBlackText.contains(lineName) ? Color(.systemBackground) : Color.white
        }
        return isS12Dark ? Color.white : getColor(for: lineName)
    }
    
    @ViewBuilder
    private var tabBarSection: some View {
        HStack(spacing: 12) {
            if isDetailed {
                Button(action: {
                    if feedbacksEnabled { HapticManager.shared.trigger() }
                    
                    if(selectedTab != .map) {withAnimation(.snappy) { selectedTab = .map }}
                    else {
                        if(isBusLineForRoute){openPopUpMovibus = true}
                        if(isTram){openPopUpTram = true}
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                        
                        if selectedTab == .map {
                            Text("Mappa")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .frame(maxWidth: selectedTab == .map ? .infinity : 70)
                    .frame(height: 38)
                    .background(Capsule().fill(tabBackground(isSelected: selectedTab == .map)))
                    .foregroundStyle(tabForeground(isSelected: selectedTab == .map))
                }
            }
            Button(action: {
                if feedbacksEnabled { HapticManager.shared.trigger() }
                withAnimation(.snappy) { selectedTab = .works }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                    
                    if selectedTab == .works {
                        Text("Lavori")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .frame(maxWidth: selectedTab == .works ? .infinity : 70)
                .frame(height: 38)
                .background(Capsule().fill(tabBackground(isSelected: selectedTab == .works)))
                .foregroundStyle(tabForeground(isSelected: selectedTab == .works))
            }
            if isDetailed && !isBusLineForRoute {
                Button(action: {
                    if feedbacksEnabled { HapticManager.shared.trigger() }
                    withAnimation(.snappy) { selectedTab = .interchanges }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.title3)
                        
                        if selectedTab == .interchanges {
                            Text("Interscambi")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .frame(maxWidth: selectedTab == .interchanges ? .infinity : 70)
                    .frame(height: 38)
                    .background(Capsule().fill(tabBackground(isSelected: selectedTab == .interchanges)))
                    .foregroundStyle(tabForeground(isSelected: selectedTab == .interchanges))
                }
            }
            if viewModel.linesSupportedGTFS.contains(lineName) && !isTram {
                Button(action: {
                    if feedbacksEnabled { HapticManager.shared.trigger() }
                    withAnimation(.snappy) { selectedTab = .arrivi }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                        
                        if selectedTab == .arrivi {
                            Text("Arrivi")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .frame(maxWidth: selectedTab == .arrivi ? .infinity : 70)
                    .frame(height: 38)
                    .background(Capsule().fill(tabBackground(isSelected: selectedTab == .arrivi)))
                    .foregroundStyle(tabForeground(isSelected: selectedTab == .arrivi))
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .padding(.top, -10)
    }
    
    @ViewBuilder
    private var mapTabContent: some View {
        let lineColor = getColor(for: lineName)
        VStack(spacing: 0) {
            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: centerCoordinate,
                        span: MKCoordinateSpan(
                            latitudeDelta: (typeOfTransport.contains(String(localized: .tram)) || typeOfTransport.contains(String(localized: .filobus))) ? 0.02 : ((lineName.starts(with: "M")) ? 0.045 : lineName == "H" ? 0.009 : 0.14),
                            longitudeDelta: (typeOfTransport.contains(String(localized: .tram)) || typeOfTransport.contains(String(localized: .filobus))) ? 0.02 : ((lineName.starts(with: "M")) ? 0.045 : lineName == "H" ? 0.009 : 0.145)
                        )
                    )
                ),
                bounds: lombardyBounds,
                selection: $selectedStationIndex,
                content: {
                    UserAnnotation()

                    MapPolyline(coordinates: mainStations.map(\.coordinate))
                        .stroke(lineColor, lineWidth: 5)

                    if !modalitaRitorno {
                        ForEach(branchData.indices, id: \.self) { i in
                            if branchData[i].isPlanned {
                                MapPolyline(coordinates: branchData[i].coords)
                                    .stroke(lineColor, style: StrokeStyle(lineWidth: 4, dash: [6, 6]))
                            }
                            else {
                                MapPolyline(coordinates: branchData[i].coords)
                                    .stroke(lineColor, lineWidth: 5)
                            }
                        }
                    }

                    ForEach(Array(stationsForCurrentDirection.enumerated()), id: \.offset) { index, station in
                        stationAnnotation(station: station, index: index, lineColor: lineColor)
                    }
                }
            )
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .tint(getColor(for: lineName))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onChange(of: modalitaRitorno) {
                branchData = computeBranchData()
            }
            .onChange(of: selectedStationIndex) { _, newIndex in
                guard let newIndex else { return }
                let stations = stationsForCurrentDirection

                if stations.indices.contains(newIndex) {
                    selezionaFermataDaMappa(stations[newIndex].name)
                }
                
                selectedStationIndex = nil
            }
            .overlay(alignment: .topLeading) {
                if let status = metroStatusInfo {
                    if status.text == String(localized: .statoMetroRegolare) || status.text == String(localized: .statoMetroChiusa) {
                        HStack(spacing: 6) {
                            Image(systemName: status.icon)
                                .font(.system(size: 13, weight: .bold))
                            Text(status.text)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(status.color))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .padding(12)
                    } else {
                        Button {
                            openPopUpInfoStatus = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: status.icon)
                                    .font(.system(size: 13, weight: .bold))
                                Text(status.text)
                                    .font(.system(size: 14, weight: .semibold))
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(status.color))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(12)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isBusLineForRoute && hasRitornoBranch {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        withAnimation {
                            modalitaRitorno.toggle()
                        }
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 45, height: 45)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .padding(.bottom, 10)
                    .padding(.trailing, 10)
                }
            }
            .overlay(alignment: .topLeading) {
                if let direzioneMappaText {
                    Text(direzioneMappaText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.quaternary, lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.top, 15)
                        .padding(.leading, 12)
                        .transition(.opacity)
                }
            }
        }
        .alert("Stato Attuale Metro", isPresented: $openPopUpInfoStatus) {
            Button("Chiudi", role: .cancel) {}
        } message: {
            Text(viewModel.messageCurrentStatus)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 10)
        .onAppear {
            locationManager.requestPermission()
            
            if branchData.isEmpty {branchData = computeBranchData()}
            if metroLineIndex != nil {viewModel.fetchMetroStatus()}
        }
    }
    
    @MapContentBuilder
    private func stationAnnotation(station: MetroStation, index: Int, lineColor: Color) -> some MapContent {
        if station.name != "NO_DRAW" {
            let closed: Bool = isStationClosed(station.name)
            let size: CGFloat = closed ? 16 : 12
            let ringColor: Color = closed ? Color.red : lineColor
            let fillColor: Color = closed ? Color.red : Color.white

            Annotation(station.name, coordinate: station.coordinate) {
                ZStack {
                    Circle()
                        .fill(fillColor)
                        .frame(width: size, height: size)
                    Circle()
                        .stroke(ringColor, lineWidth: 3)
                        .frame(width: size, height: size)
                    if closed {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 40, height: 40)
                .contentShape(Circle())
            }
            .tag(index)
        }
    }
    
    @ViewBuilder
    private var worksTabContent: some View {
        VStack {
            ScrollView {
                let currentWorks = getCurrentWorks(line: (typeOfTransport.contains(String(localized: .filobus)) ? "Filobus \(lineName)" : lineName), viewModel: viewModel)
                if currentWorks.count > 0 {
                    LazyVStack(spacing: 12) {
                        ForEach(currentWorks) { work in
                            WorkInProgressRow(item: work)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Label {
                        Text((networkManager.isConnected) ? "Non ci sono lavori su questa linea." : "Nessuna connessione ad Internet.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: (networkManager.isConnected) ? "info.circle.fill" : "wifi.slash")
                            .foregroundStyle(.white)
                            .font(.system(size: 15))
                    }
                    .padding()
                    .bold()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(.bottom, 10)
    }
    
    @ViewBuilder
    private var interchangesTabContent: some View {
        let isMetro = lineName.starts(with: "M") && !lineName.starts(with: "MXP")
        let isMalpensaExpress = lineName.starts(with: "MXP")
        let isSuburban = lineName.starts(with: "S") && !isLineTILO(lineName: lineName)
        let isTilo = isLineTILO(lineName: lineName)
        let isRegional = lineName.starts(with: "R") && !lineName.starts(with: "RE")
        let isRegioExpress = lineName.starts(with: "RE")
        let isFilobus = lineName == "90" || lineName == "91" || lineName == "92" || lineName == "93"
        let isTram = typeOfTransport.contains(String(localized: .tram))
        let isMinimetro = lineName == "H"
        
        let isAvailable = (isMetro || isMinimetro || isMalpensaExpress || isSuburban || isTilo || isRegional || isFilobus || isTram || isRegioExpress)
        
        let allInterchanges = getInterchanges(line: lineName)
        let mainItems = allInterchanges.filter { $0.branch == "Main" }
        let branchMap = Dictionary(grouping: allInterchanges.filter { $0.branch != "Main" && $0.lines.first == lineName },by: \.branch)
        let availableBranches = branchMap.keys.sorted()

        VStack(spacing: 0) {
            if isAvailable && availableBranches.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableBranches, id: \.self) { branch in
                            Button(action: {
                                selectedBranch = branch
                                HapticManager.shared.trigger()
                            }) {
                                Text(branch)
                                    .font(.system(size: 15))
                                    .foregroundStyle(selectedBranch == branch ? .white : Color("TextColor"))
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 14)
                                    .background(Capsule().fill(selectedBranch == branch ? getColor(for: lineName) : Color(.secondarySystemBackground)))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            ScrollView {
                let toShow: [InterchangeInfo] = {
                    if isAvailable {
                        let validMain = mainItems.filter { $0.lines.first == lineName }
                        let sortedMain = validMain.sorted { $1.lineOrder > $0.lineOrder }
                        
                        if let branch = selectedBranch {
                            if(branch == "Assago Milanofiori Forum" || branch == "P.Za Abbiategrasso"){
                                let validBranch = (branchMap[branch] ?? []).filter { $0.lines.first == lineName }
                                let branchItems = validBranch.sorted { $0.lineOrder > $1.lineOrder }
                                return sortedMain + branchItems
                            }
                            else {
                                let validBranch = (branchMap[branch] ?? []).filter { $0.lines.first == lineName }
                                let branchItems = validBranch.sorted { $1.lineOrder > $0.lineOrder }
                                return branchItems + sortedMain
                            }
                        }
                        else {
                            let allBranch = availableBranches.flatMap { branch in
                                (branchMap[branch] ?? [])
                                    .filter { $0.lines.first == lineName }
                                    .sorted { $1.lineOrder > $0.lineOrder }
                            }
                            return sortedMain + allBranch
                        }
                    }
                    else {
                        return allInterchanges
                    }
                }()

                if !toShow.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(toShow.enumerated()), id: \.element.id) { idx, interchange in
                            InterchangeRow(
                                interchange: interchange,
                                currentLine: lineName,
                                isFirst: idx == 0,
                                isLast: idx == toShow.count - 1
                            )
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Text("Nessun interscambio con questa linea.")
                        .padding()
                        .bold()
                        .font(.system(size: 15))
                }
            }
        }
        .onAppear(){
            if selectedBranch == nil, let first = availableBranches.first {
                selectedBranch = first
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(.bottom, 10)
        .padding(.top, 6)
    }
    
    @ViewBuilder
    private var arriviTabContent: some View {
        VStack(spacing: 0) {
            if isLoadingArrivals {
                Spacer()
                ProgressView("Caricamento orari...")
                    .controlSize(.large)
                Spacer()
            }
            else if let route = routeData {
                stopPickerSection(route: route)

                if let stopId = selectedStopId, let departuresByDir = GTFSHelper.getDepartures(for: stopId, in: route, limit: 3) {
                    departuresListSection(departuresByDir: departuresByDir)
                }
                else if selectedStopId != nil {noDeparturesTodayView}
                else {selectAStopView}
            }
            else if let error = arrivalsErrorMessage {
                Spacer()
                ContentUnavailableView("Errore", systemImage: "exclamationmark.triangle", description: Text(error))
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(.bottom, 10)
        .id(currentTime)
        .onReceive(arrivalsTimer) { newTime in
            currentTime = newTime
        }
    }
    
    @ViewBuilder
    private func stopPickerSection(route: GTFSRoute) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "location.fill")
                    .font(.title2)

                Menu {
                    ForEach(sortedStops(route: route), id: \.id) { stop in
                        Button(stop.name) {
                            selectedStopId = stop.id
                            selectedStopName = stop.name
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedStopId.flatMap { route.stops[$0]?.n } ?? "Scegli una fermata...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color("TextColor"))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()
        }
    }

    @ViewBuilder
    private func departuresListSection(departuresByDir: [String: [Departure]]) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(Array(departuresByDir.keys).sorted(), id: \.self) { dirId in
                    let departures = departuresByDir[dirId] ?? []
                    directionCard(dirId: dirId, departures: departures)
                }
            }
        }
    }

    @ViewBuilder
    private func directionCard(dirId: String, departures: [Departure]) -> some View {
        let headsign = departures.first?.headsign ?? "Direzione \(dirId)"
        let isLastStop = selectedStopName.caseInsensitiveCompare(headsign) == .orderedSame

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.forward")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(isLastStop ? "PROSSIMI ARRIVI: \(headsign)" : "DIREZIONE: \(headsign.uppercased())")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if departures.isEmpty {
                Text("Nessuna corsa prevista per oggi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            } else {
                departureDetailCard(departures: departures)
            }
        }
    }

    @ViewBuilder
    private func departureDetailCard(departures: [Departure]) -> some View {
        let first = departures[0]
        let rest = Array(departures.dropFirst().prefix(3))

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(waitColor(first.minutesFromNow))
                    .font(.system(size: 18))

                Text(first.minutesFromNow == 0 ? String(localized: .inPartenza) : first.formattedWait)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(waitColor(first.minutesFromNow))
                Spacer()
                Text(first.time)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text("Il bus può fare un ritardo dai 3 ai 5 minuti, questo è l'orario programmato.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            if !rest.isEmpty {
                Divider()

                HStack(spacing: 16) {
                    ForEach(rest) { dep in
                        HStack(spacing: 5) {
                            Image(systemName: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(dep.formattedWait)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text(dep.time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
    
    private func waitColor(_ minutes: Int) -> Color {
        switch minutes {
            case 0: return .yellow
            case 1..<5: return .red
            case 5..<10: return .orange
            default: return .green
        }
    }

    @ViewBuilder
    private var noDeparturesTodayView: some View {
        Spacer()
        VStack(spacing: 10) {
            Image(systemName: "clock.badge.questionmark.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("Nessuna corsa prevista per oggi.")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
            Text("Per oggi non c'è nessuna corsa programmata per questa fermata, prova a sceglierne un' altra.")
                .font(.system(size: 12))
                .padding(.horizontal, 20)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        Spacer()
    }

    @ViewBuilder
    private var selectAStopView: some View {
        Spacer()
        VStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Seleziona una fermata")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        Spacer()
    }
}
