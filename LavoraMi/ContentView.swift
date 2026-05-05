//
//  ContentView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 05/01/26.
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
internal import Auth
import FirebaseMessaging
import Translation
import StoreKit
import Combine
import SystemConfiguration

struct WorkItem: Identifiable, Hashable, Codable {
    var id = UUID()
    
    let title: String
    let titleIcon: String
    let typeOfTransport: String
    let roads: String
    let lines: [String]
    let startDate: Date
    let endDate: Date
    let details: String
    let company: String
    
    enum CodingKeys: String, CodingKey {
        case title, titleIcon, typeOfTransport, roads, lines, startDate, endDate, details, company
    }
    
    var progress: Double {
        let now = Date()
        let total = endDate.timeIntervalSince(startDate)
        
        guard total > 0 else { return 1 }
        let elapsed = now.timeIntervalSince(startDate)
        let fraction = elapsed / total
        
        return min(max(fraction, 0), 1)
    }
}

//MARK: MAIN VIEW
struct ContentView: View {
    @StateObject private var viewModel = WorkViewModel()
    @Binding var showSetupScreen: Bool
    @Binding var showWhatsNewScreen: Bool
    @State private var showUpdatePopUp: Bool = false
    @State private var selectedTab: Int = 0
    @State private var showWhatsNew: Bool = false
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("showWhatsNewScreen") var showWhatsNewScreenToggle: Bool = true
    @AppStorage("latestVersionInstalled") var latestVersionInstalled: String = Bundle.main.shortVersion
    
    @Environment(\.openURL) private var openURLAction

    var body: some View {
        TabView(selection: $selectedTab){
            MainView(viewModel: viewModel)
                .tabItem {Label("Home", image: "homeIcon")}
                .tag(0)
            LinesView(viewModel: viewModel)
                .tabItem{Label("Linee", systemImage: "arrow.branch")}
                .tag(1)
            SettingsView(viewModel: viewModel)
                .tabItem{Label("Impostazioni", systemImage: "gear")}
                .tag(2)
        }
        .tint(.red)
        .onChange(of: selectedTab) {
            if(feedbacksEnabled){
                HapticManager.shared.trigger()
            }
        }
        .sheet(isPresented: $showSetupScreen){
            SetupView()
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewViewBase()
        }
        .onAppear() {
            checkForUpdates()
        }
        .onChange(of: showWhatsNewScreen) {
            if(showWhatsNewScreen && latestVersionInstalled != Bundle.main.shortVersion && showWhatsNewScreenToggle && viewModel.showWhatsNewScreen) {
                showWhatsNew = true
                latestVersionInstalled = Bundle.main.shortVersion
            }
        }
        .alert("Nuova versione disponibile!", isPresented: $showUpdatePopUp){
            Button("Aggiorna") {
                let url = URL(string: "https://apps.apple.com/us/app/lavorami/id6760344298")!
                openURLAction(url)
                
                showUpdatePopUp = false
                checkForUpdates()
            }
        } message: {
            Text("Una nuova versione di LavoraMi è disponibile! Per continuare la navigazione, aggiorna l'app.")
        }
    }
    
    func checkForUpdates() {
        viewModel.fetchRequirements {
            let current = Bundle.main.shortVersion
            let minimum = viewModel.minimumVersion
            
            let comparisonResult = current.compare(minimum, options: .numeric)
            
            if comparisonResult == .orderedAscending {
                showUpdatePopUp = true
            }
        }
    }
}

struct SetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    @State private var currentPage = 0
    @State private var showPopUpConfirmSkipSetup: Bool = false
    
    let pages = [
        SetupPage(
            title: "Benvenuto su LavoraMi",
            description: "Tieniti informato. Prima e durante il tuo viaggio.",
            transitionImage: "1",
            standardImage: "1",
            fallbackImage: "lightrail.fill"
        ),
        SetupPage(
            title: "Pianifica il Viaggio",
            description: "Pianifica il tuo viaggio sapendo dei disagi sul tragitto, ben prima di partire.",
            transitionImage: "mappin",
            standardImage: "mappin.and.ellipse"
        ),
        SetupPage(
            title: "Tieni sott'occhio i lavori",
            description: "Seleziona una linea da poter mostrare nel Widget per tenerla sempre sott'occhio.",
            transitionImage: "star.fill",
            standardImage: "widget.small",
            fallbackImage: "star.fill"
        ),
        SetupPage(
            title: "Tieniti Aggiornato",
            description: "Attiva le notifiche per rimanere al passo coi lavori. Senza perderti sorprese.",
            transitionImage: "bell.slash.fill",
            standardImage: "bell.fill"
        ),
        SetupPage(
            title: "Traduci i lavori, nella lingua che vuoi tu.",
            description: "Traduci i dettagli dei lavori in altre lingue, basta cliccare sui dettagli del lavoro e cliccare \"Traduci\".",
            transitionImage: "text.append",
            standardImage: "translate"
        ),
        SetupPage(
            title: "Accessibile, sempre.",
            description: "Guarda se una linea è completamente, parzialmente o per nulla accessibile. Tutto a colpo d'occhio.",
            transitionImage: "person.fill",
            standardImage: "figure.roll"
        ),
        SetupPage(
            title: "Tu ed ancora Tu.",
            description: "I tuoi dati sono al sicuro. Crea un Account per registrarti al nostro club LavoraMi.",
            transitionImage: "lock.open.fill",
            standardImage: "lock.fill"
        ),
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0 ..< pages.count, id: \.self) { index in
                        SetupPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color("TextColor") : Color.gray.opacity(0.4))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 8)
                Spacer()
                if currentPage == pages.count - 1 {
                    Button {
                        hasNotCompletedSetup = false
                        dismiss()
                    } label: {
                        Text("Fine")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                } else {
                    Button {
                        if(currentPage == 2){
                            NotificationManager.shared.requestPermission()
                        }
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("Avanti")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle(Text("LavoraMi"))
            .toolbar {
                if(currentPage == pages.count - 1) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showPopUpConfirmSkipSetup = true
                        } label: {
                            Text("Salta")
                        }
                    }
                }
            }
            .alert("Sei sicuro?", isPresented: $showPopUpConfirmSkipSetup){
                Button("Annulla", role: .cancel) { }
                Button("Continua", role: .destructive) {
                    hasNotCompletedSetup = false; dismiss()
                }
            } message: {
                Text("Sei sicuro di voler saltare la configurazione?")
            }
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
        NotificationManager.shared.requestPermission()
    }
}

// MARK: MAINTENANCE VIEW
struct MaintenanceView: View {
    var maintenanceDeps: String = ""
    var maintenanceDepsEn: String = ""
    var onResolved: () -> Void = {}
    
    @State private var showSetupScreen: Bool = true
    @StateObject private var viewModel = WorkViewModel()
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(Color("TextColor"))
            
            Text("Manutenzione in corso.")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            
            Text("I server di LavoraMi non sono attualmente disponibili. Ci scusiamo per il disagio.")
                .font(.system(size: 16))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 5)
            
            if !maintenanceDeps.isEmpty && Bundle.main.preferredLocalizations.first?.hasPrefix("en") == false {
                Text(maintenanceDeps)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            else if !maintenanceDepsEn.isEmpty && Bundle.main.preferredLocalizations.first?.hasPrefix("en") == true {
                Text(maintenanceDepsEn)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            
            Button {
                guard !isLoading else { return }
                isLoading = true
                
                viewModel.fetchRequirements {
                    if (!viewModel.maintenanceModeEnabled){
                        onResolved()
                    }
                    
                    stopLoading()
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isLoading ? "Caricamento..." : "Riprova")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isLoading ? Color.gray : Color.red)
                .cornerRadius(8)
            }
            .padding(.top, 25)
            
            Spacer()
        }
    }
    
    func stopLoading() {
        isLoading = false
    }
}

struct SetupPage {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let transitionImage: String
    let standardImage : String
    var fallbackImage: String? = nil
}

struct SetupPageView: View {
    @State var startImageTransition : Bool = false
    @State var imageTransitionFirstPage: Bool = false
    @State var i = 0
    @AppStorage("enableAnimations") var enableAnimations = true
    let page: SetupPage

    var body: some View {
        VStack(spacing: 30) {
            if #available(iOS 18.0, *), enableAnimations {
                if(page.standardImage != "1") {
                    Image(systemName: (startImageTransition) ? page.standardImage : page.transitionImage)
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .padding(.top, 50)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                        .onAppear{
                            Task{
                                try? await Task.sleep(for: .seconds(1))
                                withAnimation{
                                    startImageTransition = true
                                }
                            }
                        }
                        .onDisappear{
                            startImageTransition = false
                        }
                }
                else {
                    let images = ["tram.fill", "tram.fill.tunnel", "lightrail.fill", "bus.fill"]

                    Image(systemName: images[i])
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .padding(.top, 50)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                        .onAppear {
                            imageTransitionFirstPage = true
                            Task {
                                while imageTransitionFirstPage {
                                    try? await Task.sleep(for: .seconds(1))
                                    withAnimation {
                                        i = (i + 1) % images.count
                                    }
                                }
                            }
                        }
                        .onDisappear(){
                            imageTransitionFirstPage = false
                        }
                }
            }
            else{
                Image(systemName: page.fallbackImage ?? page.standardImage)
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.top, 50)
            }

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if(page.title == "Tu ed ancora Tu."){
                Text("Creando un Account LavoraMi, accetti i Termini di Servizio e la Privacy Policy. Vai in Impostazioni > Account per saperne di più.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            else if(page.title == "Traduci i lavori, nella lingua che vuoi tu."){
                Text("Per attivare questa Funzionalità anche in lingua Italiana, Vai in Impostazioni > Opzioni Avanzate ed attiva \"Mostra Pulsante Traduci\".")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }
}

struct MainView: View {
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    @AppStorage("showErrorMessages") var showErrorMessages: Bool = false
    @AppStorage("showStrikeBanner") var showStrikeBanner: Bool = true
    @AppStorage("linesFavorites") var linesFavorites: [String] = []
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    
    @State private var closedStrike: Bool = false
    @State private var selectedFilter: FilterBy = .all
    @State private var searchInput: String = ""
    @State private var alreadyRefreshed: Bool = false
    @State private var showMaintenanceMode: Bool = false
    
    @ObservedObject var viewModel: WorkViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var currentHintIndex: Int = 0
    
    private let searchHints = [
        String(localized: .cercaNeiLavori),
        String(localized: .scopriQualcosaDiNuovo),
        String(localized: .cercaLaTuaLinea),
        String(localized: .cercaCiòCheAmi),
        String(localized: .nonEssereLultimoASapereLeCose),
        String(localized: .scopriLeNovità),
        String(localized: .lavoriDellaSettimana)
    ]
    
    init(viewModel: WorkViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        _preferredFilter = AppStorage(wrappedValue: .all, "preferredFilter")
        _selectedFilter = State(initialValue: _preferredFilter.wrappedValue)
    }
    
    var filteredItems: [WorkItem] {
        let now = Date()
        let categoryFiltered: [WorkItem]
        let items = viewModel.items
        
        switch(selectedFilter){
            case .suggested:
                categoryFiltered = items.filter { item in
                    linesSelected.contains { item.lines.contains($0) }
                }
            case .all:
                categoryFiltered = items
            case .bus:
                categoryFiltered = items.filter{ $0.typeOfTransport.contains("bus") }
            case .tram:
                categoryFiltered = items.filter{ $0.typeOfTransport.contains("tram") && $0.typeOfTransport != "tram.fill.tunnel"}
            case .metro:
                categoryFiltered = items.filter { $0.typeOfTransport.contains("tram.fill.tunnel")}
            case .train:
                categoryFiltered = items.filter{ $0.typeOfTransport.contains("train") }
            case .ATM:
                categoryFiltered = items.filter{ $0.company.contains("ATM") }
            case .Trenord:
                categoryFiltered = items.filter{ $0.company.contains("Trenord") }
            case .Movibus:
                categoryFiltered = items.filter{ $0.company.contains("Movibus") }
            case .STAV:
                categoryFiltered = items.filter{ $0.company.contains("STAV") }
            case .Autoguidovie:
                categoryFiltered = items.filter{ $0.company.contains("Autoguidovie") }
            case .scheduled:
                categoryFiltered = items.filter { $0.startDate > now }
            case .working:
                categoryFiltered = items.filter { $0.startDate <= now && $0.endDate >= now }
        }
        
        if searchInput.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { item in
                item.lines.contains { $0.localizedCaseInsensitiveContains(searchInput) }
            }
        }
    }

    var body: some View{
        NavigationStack{
            VStack(spacing: 0) {
                HStack {
                    Text("Lavori in corso")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        viewModel.isLoading = true
                        viewModel.fetchWorks()
                        viewModel.fetchVariables()
                        viewModel.fetchRequirements{
                            showMaintenanceMode = viewModel.maintenanceModeEnabled
                        }
                    }) {
                        if(viewModel.isLoading){
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.0)
                                .tint(.red)
                        }
                        else{
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 57)
                .padding(.bottom, 5)
            }
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                ZStack(alignment: .leading) {
                    if searchInput.isEmpty && !isSearchFocused {
                        Text(searchHints[currentHintIndex])
                            .foregroundColor(.gray.opacity(0.55))
                            .allowsHitTesting(false)
                            .id(currentHintIndex)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                    TextField("", text: $searchInput)
                        .foregroundColor(.primary)
                        .autocorrectionDisabled(true)
                        .focused($isSearchFocused)
                        .submitLabel(.done)
                }
                
                if !searchInput.isEmpty {
                    Button(action: {
                        searchInput = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentHintIndex = (currentHintIndex + 1) % searchHints.count
                    }
                }
            }
            if viewModel.strikeEnabled && !closedStrike && showStrikeBanner {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)

                        Text("AVVISO SCIOPERO")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .tracking(0.5)

                        Spacer()

                        Button(action: { withAnimation(.spring(duration: 0.3)) { closedStrike = true } }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(6)
                                .background(.white.opacity(0.2), in: Circle())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.red)
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                            Text("Sciopero proclamato per il **\(viewModel.dateStrike)**")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                                .padding(.top, 1)
                            Text("Le fasce garantite \(viewModel.guaranteed)")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Divider()
                            .padding(.vertical, 2)

                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                            Text("Aderenti:")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text(viewModel.companiesStrikes)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .red.opacity(0.12), radius: 8, x: 0, y: 3)
                .padding(.horizontal)
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FilterBy.allCases) { filter in
                        Button(action: {
                            withAnimation(.snappy){
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                selectedFilter = filter
                            }
                        }){
                            let nameIcon: String = getIconForFilter(for: filter.rawValue)
                            
                            if(nameIcon != ""){
                                Label(filter.localizedTitle, systemImage: nameIcon)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    ZStack {
                                        if selectedFilter == filter {
                                            if(selectedFilter == .suggested) {
                                                GradientCapsule()
                                            } else {
                                                Capsule()
                                                    .fill(.red)
                                            }
                                        } else {
                                            Capsule()
                                                .stroke(Color.secondary, lineWidth: 1)
                                        }
                                    }
                                )
                                .foregroundStyle(selectedFilter == filter ? Color(.systemBackground) : .primary)
                            }
                            else{
                                Text(filter.localizedTitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    ZStack {
                                        if selectedFilter == filter {
                                            Capsule()
                                                .fill(.red)
                                        } else {
                                            Capsule()
                                                .stroke(Color.secondary, lineWidth: 1)
                                        }
                                    }
                                )
                                .foregroundStyle(selectedFilter == filter ? Color(.systemBackground) : .primary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .scrollDismissesKeyboard(.immediately)
            .animation(.default, value: filteredItems)
            .padding(.bottom, 8)
            VStack(alignment: .leading, spacing: 16){
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12){
                            if viewModel.isLoading {
                                ForEach(0..<6, id: \.self) { _ in
                                    WorkRowSkeleton()
                                        .padding(.horizontal)
                                }
                            } else if let error = viewModel.errorMessage {
                                VStack (spacing: 10){
                                    Image(systemName: "wifi.exclamationmark")
                                        .font(.largeTitle)
                                    Text("Impossibile caricare i dati dal server.")
                                        .font(.title2)
                                    Text("Controlla la tua connessione e riprova.").font(.title3).foregroundColor(.gray)
                                    Button(action: {
                                        viewModel.fetchRequirements()
                                        viewModel.fetchVariables()
                                        viewModel.fetchWorks()
                                    })
                                    {
                                        Label("Riprova", systemImage: "arrow.clockwise")
                                    }
                                    .buttonStyle(.bordered)
                                    if(showErrorMessages){
                                        Text("\(error)")
                                            .font(.footnote)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .containerRelativeFrame(.vertical)
                                .padding()
                                .offset(y: -50)
                            } else {
                                VStack(spacing: 12) {
                                    if filteredItems.isEmpty && searchInput.isEmpty {
                                        if(selectedFilter == .suggested) {
                                            Text("Non hai aggiunto delle linee a questa sezione.")
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .multilineTextAlignment(.center)
                                                .containerRelativeFrame(.vertical)
                                                .foregroundStyle(.secondary)
                                        }
                                        else {
                                            Text("Nessun lavoro trovato per questo filtro.")
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .containerRelativeFrame(.vertical)
                                                .multilineTextAlignment(.center)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    else if filteredItems.isEmpty && !searchInput.isEmpty {
                                        Text("Nessun lavoro trovato per: \"\(searchInput)\".")
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .containerRelativeFrame(.vertical)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(.secondary)
                                    }
                                    else {
                                        ForEach(filteredItems) { item in
                                            if item.progress != 1 {
                                                WorkInProgressRow(item: item)
                                                    .padding(.horizontal)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .id("top")
                        .onChange(of: selectedFilter) { _, _ in
                            withAnimation {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                        .onChange(of: searchInput) { _, _ in
                            withAnimation {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                    }
                }
            }
            .onAppear(){
                if(!alreadyRefreshed) {
                    viewModel.fetchWorks()
                    viewModel.fetchVariables()
                    viewModel.fetchRequirements {
                        showMaintenanceMode = viewModel.maintenanceModeEnabled
                    }
                    alreadyRefreshed = true
                }
            }
            .refreshable {
                viewModel.fetchWorks()
                viewModel.fetchVariables()
                viewModel.fetchRequirements {
                    showMaintenanceMode = viewModel.maintenanceModeEnabled
                }
            }
            .fullScreenCover(isPresented: $showMaintenanceMode) {
                MaintenanceView(maintenanceDeps: viewModel.maintenanceDeps, maintenanceDepsEn: viewModel.maintenanceDepsEn) {
                    showMaintenanceMode = false
                }
            }
        }
    }
}

struct GradientCapsule: View {
    @State private var hueShift: Double = 0

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.0,  green: 0.55, blue: 0.10),
                        Color(red: 0.95, green: 0.28, blue: 0.52),
                        Color(red: 0.55, green: 0.45, blue: 0.88),
                        Color(red: 0.25, green: 0.65, blue: 1.00),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .hueRotation(.degrees(hueShift))
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
                    hueShift = 40
                }
            }
    }
}

struct WorkInProgressRow: View {
    let item: WorkItem
    @State private var isExpanded = false
    @State private var showTranslation = false
    
    @AppStorage("showTranslateButton") var showTranslateButton: Bool = false
    
    private let italianLoc = Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: "it_IT"))
    
    var shouldShowTranslationButton: Bool { Locale.current.language.languageCode?.identifier != "it" || showTranslateButton == true }
    var textToTranslate: String { "\(item.title)\n\n\(item.details)\n\nStrade: \(item.roads)\n\nLinee coinvolte: \(item.lines.joined(separator: ", "))" }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.details)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                } else if item.titleIcon == "arrow.trianglehead.2.counterclockwise" {
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
                } else {
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
                                Label(line, systemImage: "bolt.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: line))
                                    )
                            } else if line.starts(with: "N") {
                                Label(line, systemImage: "moon.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: line))
                                    )
                            } else {
                                Text(line)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: line))
                                    )
                            }
                        }
                    }
                }
                
                VStack(spacing: 6) {
                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                        .tint(item.progress == 1.0 ? .green : .red)

                    HStack {
                        Text(item.startDate.formatted(self.italianLoc))
                            .font(.caption)
                            .foregroundStyle(Color("TextColor"))
                        Spacer()
                            .frame(height: 8)
                        Text(item.endDate.formatted(self.italianLoc))
                            .font(.caption)
                            .foregroundStyle(Color("TextColor"))
                    }
                    Spacer()
                        .frame(height: 8)
                    Text(item.company)
                        .foregroundStyle(Color("TextColor"))
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        .translationPresentation(isPresented: $showTranslation, text: textToTranslate)
    }
}

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

//MARK: SETTINGS VIEW
struct SettingsView: View{
    @State private var expandedTrenord = false
    @State private var expandedATM = false
    @State private var expandedATMLines = false
    @State private var presentedAlertReset = false
    @State private var showBuildNumber = false
    @State private var selectedURL: URL?
    @State private var showWhatsNewScreen: Bool = false
    @StateObject var viewModel: WorkViewModel
    @StateObject var authManager = AuthManager()
    
    ///APP DATAS
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    @AppStorage("appearanceSelection") private var appearanceSelection: AppearanceType = .system
    @AppStorage("showErrorMessages") var showErrorMessages: Bool = false
    @AppStorage("showStrikeBanner") var showStrikeBanner: Bool = true
    @AppStorage("requireFaceID") var requireFaceID: Bool = true
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURLAction
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    NavigationLink(destination: AccountView(auth: authManager)) {
                        HStack(spacing: 12) {
                            if authManager.isLoggedIn() {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 44, height: 44)
                                    
                                    Text(authManager.getInitialIconName())
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            else {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 35))
                                    .foregroundStyle(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if authManager.isLoggedIn() {
                                    Text(authManager.getFullName())
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Il tuo Account")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                                
                                Text("Gestisci il tuo Account")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Preferiti"){
                    DisclosureGroup(isExpanded: $expandedTrenord){
                        HStack{
                            Label {
                                Text("Linee S")
                            } icon: {
                                Image("sLinesIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                
                                if linesFavorites.contains("S") {
                                    linesFavorites.removeAll { $0 == "S" }
                                } else {
                                    linesFavorites.append("S")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            }) {
                                Image(systemName: linesFavorites.contains("S") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("S") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label {
                                Text("Linee R")
                            } icon: {
                                Image("rLinesIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("R") {
                                    linesFavorites.removeAll { $0 == "R" }
                                } else {
                                    linesFavorites.append("R")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            }) {
                                Image(systemName: linesFavorites.contains("R") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("R") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label {
                                Text("Linee RE")
                            } icon: {
                                Image("reLinesIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("RE") {
                                    linesFavorites.removeAll { $0 == "RE" }
                                } else {
                                    linesFavorites.append("RE")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            }) {
                                Image(systemName: linesFavorites.contains("RE") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("RE") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    label: {
                        Label("Linee Trenord", systemImage: "train.side.front.car")
                    }
                    .onChange(of: expandedTrenord) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                    }
                    DisclosureGroup(isExpanded: $expandedATM){
                        HStack{
                            Label("Linee Metropolitane", systemImage: "tram.fill.tunnel")
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("Metro") {
                                    linesFavorites.removeAll { $0 == "Metro" }
                                } else {
                                    linesFavorites.append("Metro")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            }) {
                                Image(systemName: linesFavorites.contains("Metro") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("Metro") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label("Linee Tram", systemImage: "tram.fill")
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("Tram") {
                                    linesFavorites.removeAll { $0 == "Tram" }
                                } else {
                                    linesFavorites.append("Tram")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            }) {
                                Image(systemName: linesFavorites.contains("Tram") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("Tram") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label("Linee Bus", systemImage: "bus.fill")
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("Bus") {
                                    linesFavorites.removeAll { $0 == "Bus" }
                                } else {
                                    linesFavorites.append("Bus")
                                }
                                
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            }) {
                                Image(systemName: linesFavorites.contains("Bus") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("Bus") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    label: {
                        Label("Linee ATM", systemImage: "tram.fill")
                    }
                    .onChange(of: expandedATM) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                    }
                    HStack{
                        Label("Linee Movibus", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("z6") {
                                linesFavorites.removeAll { $0 == "z6" }
                            } else {
                                linesFavorites.append("z6")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                        }) {
                            Image(systemName: linesFavorites.contains("z6") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z6") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee STAV", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("z5") {
                                linesFavorites.removeAll { $0 == "z5" }
                            } else {
                                linesFavorites.append("z5")
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("z5") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z5") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee Autoguidovie", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("Autoguidovie") {
                                linesFavorites.removeAll { $0 == "Autoguidovie" }
                            } else {
                                linesFavorites.append("Autoguidovie")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                        }) {
                            Image(systemName: linesFavorites.contains("Autoguidovie") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("Autoguidovie") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                Section("Generali"){
                    NavigationLink(destination: NotificationsView(viewModel: viewModel)){
                        Label("Notifiche", systemImage: "bell.fill")
                    }
                    Picker(selection: $preferredFilter){
                        ForEach(FilterBy.allCases) { filter in
                            Text(filter.localizedTitle).tag(filter)
                                .foregroundStyle(Color("TextColor"))
                        }
                    } label: {
                        Label("Filtro Predefinito", systemImage: "line.3.horizontal.decrease")
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: preferredFilter) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                    }
                    NavigationLink(destination: AppearancePickerView()) {
                        HStack {
                            Label("Aspetto e Lingua", systemImage: "circle.righthalf.filled")
                        }
                    }
                    NavigationLink(destination: AdvancedOptionsView()){
                        Label("Opzioni Avanzate", systemImage: "gearshape.fill")
                    }
                }
                Section("Aiuto"){
                    NavigationLink(destination: InfoView()){
                        Label("Fonti & Sviluppo", systemImage: "person.crop.circle.badge.questionmark")
                    }
                    NavigationLink(destination: HowAppWorksView()){
                        Label("Funzioni dell'App", systemImage: "questionmark.circle.fill")
                    }
                    HStack{
                        Button(action: {
                            showBuildNumber = !showBuildNumber
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                        }){
                            Label {
                                Text("Versione")
                                    .foregroundColor(Color("TextColor"))
                            } icon: {
                                Image(systemName: "info.circle.fill")
                            }
                        }
                        Spacer()
                        if(showBuildNumber){Text("\(Bundle.main.shortVersion) (\(Bundle.main.buildVersion))")
                            .textSelection(.enabled)}
                        else{Text("\(Bundle.main.shortVersion)")
                            .textSelection(.enabled)}
                    }
                }
                Section("Collegamenti") {
                    ShareLink(item: URL(string: "https://apps.apple.com/us/app/lavorami/id6760344298")!) {
                        Label("Condividi LavoraMi", systemImage: "arrowshape.turn.up.right.fill")
                    }
                    Button(action: {
                        Task {@MainActor in
                            requestReview()
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                        }
                    }){
                        Label {
                            Text("Valuta LavoraMi")
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "star.fill")
                        }
                    }
                    Button(action: {
                        let url = URL(string: "https://www.buymeacoffee.com/lavorami")!
                                                
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    }){
                        Label {
                            Text("Supporta LavoraMi")
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "arrow.up.right")
                        }
                    }
                    Button(action: {
                        showWhatsNewScreen = true
                    }){
                        Label {
                            Text("Guarda le Novità")
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "app.badge.fill")
                        }
                    }
                }
                Section(footer: Text("Le impostazioni vengono salvate automaticamente.")) {
                    Button(role: .destructive) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                        presentedAlertReset = true
                    } label: {
                        Label("Ripristina impostazioni", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Impostazioni")
            .alert("Sei sicuro?", isPresented: $presentedAlertReset) {
                Button("Annulla", role: .cancel) { }
                Button("Continua", role: .destructive) {
                    enableNotifications = true
                    preferredFilter = .all
                    linesFavorites = []
                    showErrorMessages = false
                    showStrikeBanner = true
                    requireFaceID = true
                    howToOpenLinks = .inApp
                    appearanceSelection = .system
                }
            } message: {
                Text("Sei sicuro di voler ripristinare le impostazioni?")
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea(.all)
            }
            .sheet(isPresented: $showWhatsNewScreen) {
                WhatsNewViewBase()
            }
        }
    }
}

struct AppearancePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURLAction
    @AppStorage("appearanceSelection") private var appearanceSelection: AppearanceType = .system

    var body: some View {
        List {
            Section("Tema") {
                ForEach(AppearanceType.allCases) { filter in
                    Button {
                        appearanceSelection = filter
                        dismiss()
                    } label: {
                        HStack {
                            Label {
                                Text(filter.description)
                            } icon: {
                                Image(systemName: filter.iconName)
                                    .foregroundStyle(.red)
                            }
                            Spacer()
                            if appearanceSelection == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .foregroundColor(Color("TextColor"))
                }
            }
            Section("Lingua") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURLAction(url)
                    }
                } label: {
                    HStack {
                        Label {
                            Text("Cambia Lingua")
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Aspetto")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccountView: View {
    @StateObject var auth: AuthManager
    @State private var email: String = ""
    @State private var emailRecoverPassword: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    @State private var tabTitle: String = ""
    @State private var isLogginIn: Bool = true
    @State private var loggedIn: Bool = false
    @State private var resettingPassword: Bool = false
    @State private var passwordResetted: Bool = false
    @State private var popUpVerifyMail: Bool = false
    @State private var showError: Bool = false
    @State private var showDeletePopUp: Bool = false
    @State private var showEditPasswordPopUp: Bool = false
    @State private var showConfirmToExitPopUp: Bool = false
    @State private var isLocked: Bool = true
    @State private var text: String = ""
    @State private var selectedURL: URL?
    @State private var isBiometricAuthCompleted: Bool = false
    @State private var showMailApple: Bool = false
    @State private var logginIn: Bool = false
    @State var isRequiringData: Bool = false
    @State private var currentNonce: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURLAction
    
    @AppStorage("requireFaceID") var requireFaceID: Bool = true
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("emailSaved") var emailSaved: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                //MARK: LOGIN
                if isLogginIn && !loggedIn && !resettingPassword {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bentornato")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("Accedi al tuo account per continuare.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 40)

                    VStack(spacing: 20) {
                        HStack(spacing: 15) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.gray)
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .disabled(auth.isLoading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        HStack(spacing: 15) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.gray)
                            SecureField("Password", text: $password)
                                .disabled(auth.isLoading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        HStack {
                            Spacer()
                            Button("Password dimenticata?") {
                                resettingPassword = true
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                            
                            Button(action: {
                                isLogginIn = !isLogginIn
                            }){
                                Text("Non hai un account?")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    if let err = auth.errorMessage, !err.isEmpty {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                    HStack(spacing: 0) {
                        Text("Continuando, accetti i ")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            let url = URL(string: "https://www.lavorami.it/termsofservice")!
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            }
                            else {
                                openURLAction(url)
                            }
                        } label: {
                            Text("Termini")
                                .font(.subheadline)
                        }
                        
                        Text(" e la ")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            let url = URL(string: "https://www.lavorami.it/privacypolicy")!
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            } else {
                                openURLAction(url)
                            }
                        } label: {
                            Text("Privacy Policy.")
                                .font(.subheadline)
                        }
                    }
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        Task {
                            logginIn = true
                            switch result {
                            case .failure(let error):
                                print("Apple Sign In error: \(error)")
                            case .success(let authorization):
                                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                                      let idTokenData = credential.identityToken,
                                      let idToken = String(data: idTokenData, encoding: .utf8),
                                      let nonce = currentNonce
                                else {
                                    print("Error Guard, currentNonce: \(String(describing: currentNonce))")
                                    return
                                }
                                
                                await auth.signInWithApple(nonce: nonce, idToken: idToken, fullName: "")
                                loggedIn = auth.isLoggedIn()
                                logginIn = false
                                fullName = auth.getFullName()
                                tabTitle = "Account"
                            }
                        }
                    }
                    .signInWithAppleButtonStyle((colorScheme == .dark) ? .whiteOutline : .black)
                    .frame(height: 50)
                    .cornerRadius(16)
                    Button(action: {
                        logginIn = true
                        Task {
                            await auth.signIn(email: email, password: password)
                            loggedIn = auth.isLoggedIn()
                            logginIn = false
                            tabTitle = "Account"
                            if loggedIn {
                                if fullName.isEmpty { fullName = auth.getFullName() }
                                if email.isEmpty, let sess = auth.session { email = sess.user.email ?? email }
                            }
                        }
                    }) {
                        HStack {
                            if auth.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
                            Label(auth.isLoading ? "Accedo..." : "Accedi", systemImage: "rectangle.portrait.and.arrow.right.fill")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((!validateUserInputs(email: email, password: password) || logginIn) ? Color.gray.opacity(0.5) : Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5, y: 3)
                    }
                    .disabled(!validateUserInputs(email: email, password: password) || auth.isLoading || logginIn)
                };
                //MARK: CREATING ACCOUNT
                if !isLogginIn && !loggedIn && !resettingPassword {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Crea account")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("Registrati per iniziare.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 40)

                    VStack(spacing: 20) {
                        HStack(spacing: 15) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.gray)
                            TextField("Nome completo", text: $fullName)
                                .textInputAutocapitalization(.words)
                                .disabled(auth.isLoading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        HStack(spacing: 15) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.gray)
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .disabled(auth.isLoading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        HStack(spacing: 15) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.gray)
                            SecureField("Password", text: $password)
                                .disabled(auth.isLoading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        HStack{
                            Spacer()
                            Button(action: {
                                isLogginIn = !isLogginIn
                            }){
                                Text("Hai già un account?")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    if let err = auth.errorMessage, !err.isEmpty {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                    HStack(spacing: 0) {
                        Text("Continuando, accetti i ")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            let url = URL(string: "https://www.lavorami.it/termsofservice")!
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            }
                            else {
                                openURLAction(url)
                            }
                        } label: {
                            Text("Termini")
                                .font(.subheadline)
                        }
                        
                        Text(" e la ")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            let url = URL(string: "https://www.lavorami.it/privacypolicy")!
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            } else {
                                openURLAction(url)
                            }
                        } label: {
                            Text("Privacy Policy.")
                                .font(.subheadline)
                        }
                    }
                    SignInWithAppleButton(.signUp) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        logginIn = true
                        Task {
                            switch result {
                            case .failure(let error):
                                print("Apple Sign In error: \(error)")
                            case .success(let authorization):
                                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                                      let idTokenData = credential.identityToken,
                                      let idToken = String(data: idTokenData, encoding: .utf8),
                                      let nonce = currentNonce else {
                                    print("Guard fallito - currentNonce: \(String(describing: currentNonce))")
                                    return
                                }
                                
                                let name = credential.fullName?.givenName ?? String(localized: .utenteApple)
                                
                                await auth.signInWithApple(nonce: nonce, idToken: idToken, fullName: name)
                                loggedIn = auth.isLoggedIn()
                                logginIn = false
                                tabTitle = "Account"
                            }
                        }
                    }
                    .signInWithAppleButtonStyle((colorScheme == .dark) ? .whiteOutline : .black)
                    .frame(height: 50)
                    .cornerRadius(16)
                    Button(action: {
                        logginIn = true
                        Task {
                            await auth.signUp(email: email, password: password, name: fullName)
                            popUpVerifyMail = auth.errorMessage == nil
                            logginIn = false
                            tabTitle = "Account"
                        }
                    }) {
                        HStack {
                            if auth.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
                            Label(auth.isLoading ? "Registrazione..." : "Registrati", systemImage: "rectangle.portrait.and.arrow.right.fill")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((!validateUserInputs(email: email, password: password) || isLogginIn) ? Color.gray.opacity(0.5) : Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5, y: 3)
                    }
                    .disabled(!validateUserInputs(email: email, password: password) || auth.isLoading)
                    .alert("Conferma Mail", isPresented: $popUpVerifyMail) {
                        Button("Chiudi", role: .cancel) {
                            popUpVerifyMail = false
                            isLogginIn = true
                        }
                    } message: {
                        Text("Verifica il tuo indirizzo Email con la mail che ti abbiamo inviato per continuare.")
                    }
                }
                //MARK: LOGGED-IN
                if loggedIn && !resettingPassword {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("👋 Ciao \(fullName)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("Qua puoi gestire il tuo account e le tue informazioni.")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                            .padding(.top, -8)
                        
                        Section("Informazioni"){
                            VStack(alignment: .leading, spacing: 16) {
                                Label {
                                    Text(fullName)
                                        .foregroundColor(Color("TextColor"))
                                        .font(.system(size: 25))
                                } icon: {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.red)
                                        .font(.system(size: 25))
                                }
                                
                                if(email.contains("privaterelay")) {
                                    Label {
                                        Text("Apple Private Relay Email")
                                            .foregroundColor(Color("TextColor"))
                                            .font(.system(size: 25))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    } icon: {
                                        Image(systemName: "envelope.fill")
                                            .foregroundStyle(.red)
                                            .font(.system(size: 25))
                                    }
                                    Label {
                                        Text("ID: \(email.prefix(while: {$0 != "@"}))")
                                            .foregroundColor(Color("TextColor"))
                                            .font(.system(size: 25))
                                    } icon: {
                                        Image(systemName: "person.fill.viewfinder")
                                            .foregroundStyle(.red)
                                            .font(.system(size: 25))
                                    }
                                }
                                else{
                                    Label {
                                        Text(email)
                                            .foregroundColor(Color("TextColor"))
                                            .font(.system(size: 25))
                                    } icon: {
                                        Image(systemName: "envelope.fill")
                                            .foregroundStyle(.red)
                                            .font(.system(size: 25))
                                    }
                                }
                                
                                if(auth.isLoggedInWithApple()) {
                                    Label {
                                        Text("Account creato con Apple")
                                            .foregroundColor(Color("TextColor"))
                                            .font(.system(size: 25))
                                    } icon: {
                                        Image(systemName: "apple.logo")
                                            .foregroundStyle(Color("TextColor"))
                                            .font(.system(size: 25))
                                    }
                                }
                            }
                        }
                        .foregroundStyle(.gray)
                        
                        Section("Gestisci"){
                            VStack (spacing: 8){
                                if(!auth.isLoggedInWithApple()){
                                    Button(role: .destructive, action: {
                                        showEditPasswordPopUp = true
                                    }) {
                                        Label("Modifica Password", systemImage: "lock.fill")
                                            .font(.system(size: 15))
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(radius: 5, y: 3)
                                    }
                                }
                                Button(role: .destructive, action: {
                                    showDeletePopUp = true
                                }) {
                                    Label("Elimina Account", systemImage: "trash.fill")
                                        .font(.system(size: 15))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(radius: 5, y: 3)
                                }
                                
                                NavigationLink(destination: RequestDataDownload(isRequiringData: $isRequiringData)) {
                                    Label("Richiedi i tuoi dati", systemImage: "person.and.background.dotted")
                                        .font(.system(size: 15))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(radius: 5, y: 3)
                                }
                            }
                        }
                        .alert("Sei sicuro?", isPresented: $showDeletePopUp) {
                            Button("Annulla", role: .cancel) { }
                            Button("Continua", role: .destructive) {
                                Task {
                                    email = ""
                                    password = ""
                                    fullName = ""
                                    loggedIn = false
                                    isLogginIn = true
                                    await auth.deleteAccount()
                                }
                            }
                        } message: {
                            Text("Sei sicuro di voler Eliminare Definitivamente il tuo Account?")
                        }
                        .alert("Modifica Password", isPresented: $showEditPasswordPopUp) {
                            Button("Annulla", role: .cancel) { }
                            Button("Continua", role: .destructive) {
                                Task {
                                    await auth.requestPasswordReset(email: email)
                                }
                            }
                        } message: {
                            Text("Ti invieremo una mail per modificare la tua password, vuoi continuare?")
                        }
                        .foregroundStyle(.gray)
                        
                        Spacer()

                        Button(role: .destructive, action: {
                            showConfirmToExitPopUp = true
                        }) {
                            Label("Esci", systemImage: "person.crop.circle.fill.badge.minus")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 5, y: 3)
                        }
                    }
                    .onAppear {
                        if fullName.isEmpty { fullName = auth.getFullName() }
                        if email.isEmpty, let sess = auth.session { email = sess.user.email ?? email }
                        emailSaved = email
                    }
                }
                //MARK: RESET PASSWORD
                if(resettingPassword) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reset Password")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("Recupera qui la Password del tuo Account.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 40)
                    VStack(spacing: 20) {
                        HStack(spacing: 15) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.gray)
                            TextField("Email", text: $emailRecoverPassword)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    HStack{
                        Spacer()
                        Button(action: {
                            isLogginIn = true
                            resettingPassword = false
                            passwordResetted = false
                        }){
                            Text("Torna al Login")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.top, -10)
                    Spacer()
                    Button(role: .destructive, action: {
                        Task{
                            await auth.requestPasswordReset(email: emailRecoverPassword)
                            passwordResetted = true
                        }
                    }) {
                        Label("Invia Email", systemImage: "paperplane.fill")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((!validateEmail(emailRecoverPassword)) ? Color.gray.opacity(0.5) : Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 5, y: 3)
                    }
                    .disabled(!validateEmail(emailRecoverPassword))
                    .alert("Email inviata!", isPresented: $passwordResetted) {
                        Button("Chiudi", role: .cancel) {
                            resettingPassword = false
                            passwordResetted = false
                        }
                    } message: {
                        Text("Email inviata a \(emailRecoverPassword)!")
                    }
                }
            }
            .padding(25)
            .blur(radius: isLocked ? 12 : 0)
            .animation(.easeInOut(duration: 0.25), value: isLocked)
            .allowsHitTesting(!isLocked)
            .onAppear {
                loggedIn = auth.isLoggedIn()
                if loggedIn {
                    if fullName.isEmpty { fullName = auth.getFullName() }
                    if email.isEmpty, let sess = auth.session { email = sess.user.email ?? email }
                    tabTitle = "Account"
                }
                if(requireFaceID && loggedIn && isRequiringData == false && isBiometricAuthCompleted == false){
                    BiometricAuth.authenticate{
                        print("FaceID Recognized!")
                        isLocked = false
                    } onFailure: { error in
                        print("Error during read of FaceID")
                        dismiss()
                    }
                    isBiometricAuthCompleted = true
                }
                else {
                    isLocked = false
                    isRequiringData = false
                    isBiometricAuthCompleted = true
                }
            }
            .alert("Sei sicuro?", isPresented: $showConfirmToExitPopUp) {
                Button("Annulla", role: .cancel) { }
                Button("Conferma", role: .destructive) {
                    Task {
                        loggedIn = false
                        isLogginIn = true
                        email = ""
                        password = ""
                        fullName = ""
                        tabTitle = ""
                        await auth.signOut()
                    }
                }
            } message: {
                Text("Sei sicuro di voler uscire dall'account?")
            }
            .navigationTitle(tabTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea(.all)
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func validateEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func validateUserInputs(email: String, password: String) -> Bool {
        let mailIsValid = validateEmail(email)
        
        return password.count >= 8 && mailIsValid
    }
}

struct AdvancedOptionsView: View {
    @AppStorage("showErrorMessages") var showErrorMessages: Bool = false
    @AppStorage("showStrikeBanner") var showStrikeBanner: Bool = true
    @AppStorage("requireFaceID") var requireFaceID: Bool = true
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("showTranslateButton") var showTranslateButton: Bool = false
    @AppStorage("showWhatsNewScreen") var showWhatsNewScreen: Bool = true
    @AppStorage("showRecentSearches") var showRecentSearches: Bool = true
    private var currentDeviceBiometric: BiometricType = BiometricAuth.getBiometricType()
    @State private var presentedCacheAlert = false
    
    var iphoneGenIcon: String {
        let height = UIScreen.main.bounds.height
        
        switch height {
        case 852, 932:
            return "iphone.gen3.radiowaves.left.and.right"
        case 812, 844, 896, 926:
            return "iphone.gen2.radiowaves.left.and.right"
        default:
            return "iphone.gen1.radiowaves.left.and.right"
        }
    }
    
    var body: some View {
        List{
            Section(footer: Text("Mostra messaggi di errore quando fallisce il Download dei dati.")){
                Toggle(isOn: $showErrorMessages){
                    Label("Mostra messaggi di Errore", systemImage: "exclamationmark.bubble.fill")
                }
            }
            Section(footer: Text("Mostra il banner degli scioperi nella Home quando sono presenti.")){
                Toggle(isOn: $showStrikeBanner){
                    Label("Mostra banner Scioperi", systemImage: "text.append")
                }
            }
            Section(footer: Text("Attiva i Feedback di vibrazione su alcune schermate.")){
                Toggle(isOn: $feedbacksEnabled){
                    Label("Attiva Feedback Vibrazione", systemImage: iphoneGenIcon)
                }
            }
            Section(footer: Text("Mostra la schermata delle novità appena l'app viene aggiornata.")){
                Toggle(isOn: $showWhatsNewScreen){
                    Label("Mostra Schermata Novità", systemImage: "app.badge.fill")
                }
            }
            if(Locale.current.language.languageCode?.identifier == "it"){
                Section(footer: Text("Mostra il pulsante per tradurre i lavori anche nella lingua italiana.")){
                    Toggle(isOn: $showTranslateButton){
                        Label("Mostra Pulsante Traduci", systemImage: "translate")
                    }
                }
            }
            Section(footer: Text("Mostra le tue ricerche recenti nella pagina delle Linee.")){
                Toggle(isOn: $showRecentSearches){
                    Label("Mostra Ricerche Recenti", systemImage: "sparkles")
                }
            }
            Section(footer: Text("Richiedi \(getBiometricTypeByEnum()) per bloccare e sbloccare la sezione del tuo Account.")){
                Toggle(isOn: $requireFaceID){
                    Label("Richiedi \(getBiometricTypeByEnum())", systemImage: (getBiometricTypeByEnum() == "Codice") ? "lock.fill" : getBiometricTypeByEnum().lowercased())
                }
                .onChange(of: requireFaceID) { oldValue, newValue in
                    if(newValue == false){
                        BiometricAuth.authenticate{
                            print("FaceID Recognized!")
                            requireFaceID = false
                        } onFailure: { error in
                            print("Error during read of FaceID")
                            requireFaceID = true
                        }
                    }
                    else{
                        requireFaceID = requireFaceID
                    }
                }
            }
            Section(footer: Text("Seleziona la modalità in cui aprire i link.")){
                Label("Apri link:", systemImage: "network")
                Picker(selection: $howToOpenLinks, content: {
                    ForEach(linkOpenTypes.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                            .foregroundStyle(Color("TextColor"))
                    }
                }, label: {
                    Text("")
                })
                .pickerStyle(.inline)
                .labelsHidden()
            }
            Section(footer: Text("Elimina la memoria Cache dal dispositivo, liberando spazio su disco.")){
                Button(role: .destructive) {
                    if(feedbacksEnabled){
                        HapticManager.shared.trigger()
                    }
                    presentedCacheAlert = true
                } label: {
                    Label("Pulisci memoria Cache", systemImage: "trash.fill")
                }
                .confirmationDialog("Sei sicuro?", isPresented: $presentedCacheAlert) {
                    Button("Annulla", role: .cancel) { }
                    Button("Continua", role: .destructive) {
                        clearAllCache()
                    }
                } message: {
                    Text("Sei sicuro di voler pulire la memoria Cache?")
                }
            }
        }
        .navigationTitle("Opzioni Avanzate")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func getBiometricTypeByEnum() -> String {
        switch(currentDeviceBiometric){
            case .touchID:
                return "TouchID"
            case .faceID:
                return "FaceID"
            default:
                return "Codice"
        }
    }
    
    func clearAllCache() {
        URLCache.shared.removeAllCachedResponses()
        
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}

struct NotificationsView: View {
    @AppStorage("workScheduledNotifications") var workScheduledNotifications: Bool = true
    @AppStorage("workInProgressNotifications") var workInProgressNotifications: Bool = true
    @AppStorage("strikeNotifications") var strikeNotifications: Bool = true
    @AppStorage("enableNotifications") var enableNotifications: Bool = true
    @AppStorage("enablePushNotifications") var enablePushNotifications: Bool = true
    @AppStorage("linesFavorites") var linesFavorites: [String] = []
    @AppStorage("notificationConsent") var notificationConsent: Bool = false
    
    static var defaultTime: Date {
        //MARK: SET DEFAULT VALUE OF DATEPICKER
        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    @AppStorage("dateSchedule") var dateSchedule: Date = defaultTime
    
    @ObservedObject var viewModel: WorkViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            if(notificationConsent) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $enableNotifications) {
                        HStack (spacing: 15){
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.red)
                                .scaleEffect(1.5)
                            Text("Notifiche")
                                .font(.system(size: 20))
                                .bold()
                        }
                    }
                    .tint(.red)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .disabled(!notificationConsent)
                    
                    Text("Imposta tutte le notifiche su uno stato.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                .padding(.horizontal)
                .onChange(of: enableNotifications) { oldValue, newValue in
                    workScheduledNotifications = enableNotifications
                    workInProgressNotifications = enableNotifications
                    strikeNotifications = enableNotifications
                    enablePushNotifications = enableNotifications
                    
                    //SYNC NOTIFICATIONS
                    viewModel.fetchVariables()
                    NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                }
            }

            if(notificationConsent){
                List {
                    Section("Notifiche Lavori") {
                        Toggle(isOn: $workScheduledNotifications) {
                            Label("Notifiche Inizio Lavori", systemImage: "bell.badge.fill")
                        }
                        .onChange(of: workScheduledNotifications){
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                        }
                        .disabled(!enableNotifications)
                        
                        Toggle(isOn: $workInProgressNotifications) {
                            Label("Notifiche Fine Lavori", systemImage: "bell.badge.fill")
                        }
                        .onChange(of: workInProgressNotifications){
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                        }
                        .disabled(!enableNotifications)
                    }
                    
                    Section("Altre Notifiche") {
                        Toggle(isOn: $strikeNotifications) {
                            Label("Notifiche Scioperi", systemImage: "bell.badge.waveform.fill")
                        }
                        .onChange(of: strikeNotifications){
                            viewModel.fetchVariables()
                        }
                        .disabled(!enableNotifications)
                        Toggle(isOn: $enablePushNotifications) {
                            Label("Notifiche Push", systemImage: "bell.and.waves.left.and.right.fill")
                        }
                        .onChange(of: enablePushNotifications) { oldValue, enabled in
                            NotificationCenter.default.post(name: NSNotification.Name("pushNotificationsToggled"), object: enabled)
                        }
                        .disabled(!enableNotifications)
                    }
                    Section(header: Text("Impostazioni Notifiche"), footer: Text("Modifica l'orario di arrivo delle notifiche.")){
                        VStack{
                            DatePicker(selection: $dateSchedule, displayedComponents: .hourAndMinute){
                                Label("Orario Notifiche", systemImage: "clock.badge.fill")
                            }
                            .disabled(!enableNotifications)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            else {
                Label {
                    Text("Permesso Negato")
                        .font(.system(size: 25))
                } icon: {
                    Image(systemName: "bell.slash.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 25))
                }
                
                Text("Non hai dato il permesso per ricevere notifiche. Vai su Impostazioni > App > LavoraMi ed attiva le notifiche.")
                    .padding()
                    .font(.system(size: 13))
                    .bold()
                
                Link("Apri Impostazioni", destination: URL(string: UIApplication.openSettingsURLString)!)
                    .tint(.red)
            }
        }
        .onAppear{
            NotificationManager.shared.getPermissionOfNotifications()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Notifiche")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoView: View {
    let device = UIDevice.current
    
    @Environment(\.openURL) private var openURLAction
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @State private var selectedURL: URL?
    @State private var mailData: ComposeMailData = ComposeMailData(subject: String(localized: .titoloBugReport), recipients: ["info@lavorami.it"], message: "", attachments: nil)
    @State private var showMailView: Bool = false
    
    var body: some View {
        Section{
            HStack{
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("LavoraMi")
                    .font(.system(size: 35))
                    .bold()
            }
            .padding(.bottom, 10)
            Text("\(Bundle.main.shortVersion) (Build \(Bundle.main.buildVersion))")
            Divider()
                .padding(.top, 10)
            ScrollView{
                Section(){
                    Text("Fonti Dati")
                        .font(.system(size: 30))
                        .bold()
                    Text("Questa applicazione aggrega dati pubblici, accessibili a tutti, per facilitarne la consultazione.")
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .italic()
                    Text("""
                    LavoraMi è un'applicazione indipendente sviluppata da terze parti e NON è in alcun modo affiliata, supportata, autorizzata o sponsorizzata da ATM S.p.A., Trenord S.r.l., Gruppo FNM, RFI o altri enti di trasporto citati.

                    Tutti i dati visualizzati in questa applicazione (orari, stati del servizio, avvisi) sono raccolti da fonti pubbliche al solo scopo di migliorarne la comprensione ed a solo scopo informativo.
                    
                    Non si fornisce alcuna garanzia, esplicita o implicita, riguardo l'accuratezza, la completezza, l'affidabilità o la tempestività delle informazioni fornite. Le informazioni potrebbero non riflettere variazioni dell'ultimo minuto.

                    L'uso dell'applicazione è interamente a proprio rischio. Lo sviluppatore declina ogni responsabilità per eventuali inesattezze, ritardi, mancati servizi, danni diretti o indiretti derivanti dall'affidamento sulle informazioni fornite da questa app.
                    
                    Per le decisioni di viaggio critiche, si raccomanda di fare sempre riferimento ai canali ufficiali, agli annunci sonori e alla segnaletica presente in stazione.
                    
                    Tutti i marchi, i loghi e i nomi commerciali citati appartengono ai legittimi proprietari.
                    """)
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                }
                Divider()
                Section(){
                    VStack(spacing: 12){
                        Text("Team di Sviluppo")
                            .font(.system(size: 30))
                            .bold()
                            .padding(.top, 20)
                        
                        Text("Sviluppatore iOS:")
                            .font(.system(size: 20))
                        Text("Andrea Filice")
                            .bold()
                            .font(.system(size: 25))
                            .padding(.top, -5)
                        
                        Text("Sviluppatori Android:")
                            .font(.system(size: 20))
                            .padding(.top, 20)
                        Text("Andrea Filice")
                            .bold()
                            .font(.system(size: 25))
                        Text("Alessandro Rebuscini")
                            .bold()
                            .font(.system(size: 25))
                        Text("Tommaso Ruggeri")
                            .bold()
                            .font(.system(size: 25))
                        
                        Text("Sviluppatori Web:")
                            .font(.system(size: 20))
                            .padding(.top, 20)
                        Text("Riccardo De Diana")
                            .bold()
                            .font(.system(size: 25))
                        Text("Simone Gallotti")
                            .bold()
                            .font(.system(size: 25))
                    }
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Supportaci")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    Text("Se ti piace LavoraMi e vuoi tenerla priva di pubblicità, puoi aiutarci facendoci una donazioni tramite Patreon o Buy Me A Coffee!")
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .padding(.top, 1)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.patreon.com/cw/LavoraMi")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Supportaci su Patreon", systemImage: "person.2.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.buymeacoffee.com/lavorami")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Supportaci su Buy Me A Coffee", systemImage: "cup.and.saucer.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Spacer()
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Seguici su")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    Button {
                        let url = URL(string: "https://www.instagram.com/lavoramiapp_official")!
                        openURLAction(url)
                    } label: {
                        HStack{
                            Image("instagram")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("Instagram")
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.tiktok.com/@applavorami.official")!
                        openURLAction(url)
                    } label: {
                        HStack{
                            Image("tiktok")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("TikTok")
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Contatti")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    
                    Button {
                        showMailView = true
                    } label: {
                        Label("Segnala un bug", systemImage: "ladybug.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.lavorami.it")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Sito web", systemImage: "network")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    NavigationLink(destination: LibrariesView()) {
                        Label("Librerie Open-Source", systemImage: "books.vertical.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    .sheet(isPresented: $showMailView) {
                        MailView(data: $mailData) { result in
                            print(result)
                        }
                    }
                    Spacer()
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Informazioni")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    Button {
                        let url = URL(string: "https://www.lavorami.it/privacyPolicy")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Privacy Policy", systemImage: "lock.shield.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.lavorami.it/termsofservice")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Termini di Servizio", systemImage: "doc.text.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
                .ignoresSafeArea(.all)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LibraryRowView: View {
    let name: String
    let version: String
    let license: String
    let copyright: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(version)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
            }

            HStack {
                Text(license)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text(copyright)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .cornerRadius(12)
    }
}

struct LibraryDetailView: View {
    let name: String
    let version: String
    let license: String
    let copyright: String
    let licenseText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Informazioni sul componente")
                        .font(.title2).bold()
                        .padding(.bottom, 10)

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nome:").font(.caption).foregroundColor(.secondary)
                            Text(name).font(.body).bold()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Versione:").font(.caption).foregroundColor(.secondary)
                            Text(version).font(.body).bold()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Licenza:").font(.caption).foregroundColor(.secondary)
                            Text(license).font(.body).bold()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Copyright")
                        .font(.title2).bold()

                    Text(copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Testo della licenza")
                        .font(.title2).bold()

                    Text(licenseText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HowAppWorksView: View {
    let interchangeInfo: InterchageInfo = .init(name: "Romolo", lines: ["M2", "R31", "S9", "S19"], typeOfInterchange: "lightrail.fill")
    let workItem: WorkItem = .init(title: "Rallentamenti", titleIcon: "clock.badge.fill", typeOfTransport: "train.side.front.car", roads: "Palazzolo, Camnago Lentate, Seveso", lines: ["R16", "S2", "S4"], startDate: ISO8601DateFormatter().date(from: "2026-02-23T00:00:00+01:00") ?? Date(), endDate: ISO8601DateFormatter().date(from: "2026-04-30T00:00:00+01:00") ?? Date(), details: "Lavori di potenziamento infrastrutturale nella tratta Palazzolo, Camnago Lentate, Seveso con modifiche alla circolazione dei treni", company: "Trenord")
    let stations: [MetroStation] = StationsDB.stationsM1;
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                SectionHeader(icon: "chart.bar.fill", title: String(localized: .barraDiProgresso))
                Text("Vedi visivamente a che punto sono i lavori e quando è prevista la fine del disagio (basato su data di inizio e fine lavori PREVISTI).")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                CardView {
                    VStack(spacing: 0) {
                        HStack {
                            Text("12 Nov 2025")
                                .font(.system(size: 12))
                            Spacer()
                            Text("15 Dic 2026")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 10)

                        ProgressView(value: 0.38)
                            .progressViewStyle(.linear)
                            .tint(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                
                SectionDivider()
                
                SectionHeader(icon: "arrow.branch", title: String(localized: .scegliLaTuaLinea))
                Text("Salva fra i preferiti la linea che usi ogni giorno e quando ci sarà un lavoro su di essa, sarai già aggiornato.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                CardView {
                    HStack {
                        Image(systemName: "bus.fill")
                            .foregroundColor(.red)
                            .frame(width: 28, height: 28)
                        Text("Linee Movibus")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .frame(width: 18, height: 18)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                }

                SectionDivider()

                SectionHeader(icon: "arrow.left.arrow.right", title: String(localized: .visualizzaGliInterscambi))

                Text("Visualizza le linee che interscambiano con la TUA linea, oppure sui bus visualizza dove fanno capolinea con una fermata di interscambio.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                InterchangeView(item: interchangeInfo, currentLine: "M2")
                    .padding(.top, 20)
                SectionDivider()
                SectionHeader(icon: "hand.raised.fill", title: String(localized: .fermataCantiere))

                Text("Non solo \"lavori in via\", ti spieghiamo che tipo di lavoro si sta svolgendo ed anche le conseguenze che può portare quel cantiere (Deviazioni, Fermate Sospese...)")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                WorkInProgressRow(item: workItem)
                    .padding()

                SectionDivider()

                SectionHeader(icon: "map.fill", title: String(localized: .visualizzaLaMappa))

                Text("Visualizza i percorsi delle linee che preferisci sulla mappa, per non perdersi e per sapere sempre dove vai.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .frame(width: 380, height: 280)
                    .overlay(
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 45.4850, longitude: 9.1600),
                            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                        ))) {
                            let lineColor = getColor(for: "M1")
                            
                            MapPolyline(coordinates: stations.filter { $0.branch == "Main" }.map(\.coordinate))
                                .stroke(lineColor, lineWidth: 5)
                            let pagano = stations.first(where: { $0.name == "Pagano" })!
                            let bisceglie = stations.first(where: { $0.name == "Bisceglie" })!
                            let rhoBranch = [pagano] + stations.filter { $0.branch == "Rho" }
                            MapPolyline(coordinates: rhoBranch.map(\.coordinate))
                                .stroke(lineColor, lineWidth: 5)
                            
                            let bisceglieBranch = [pagano] + stations.filter { $0.branch == "Bisceglie" }
                            MapPolyline(coordinates: bisceglieBranch.map(\.coordinate))
                                .stroke(lineColor, lineWidth: 5)
                        
                            let bisceglieBranchNew = [bisceglie] + stations.filter { $0.branch == "Bisceglie - New" }
                            MapPolyline(coordinates: bisceglieBranchNew.map(\.coordinate))
                            .stroke(lineColor, style: StrokeStyle(lineWidth: 4, dash: [6, 6]))
                        
                            ForEach(stations) { station in
                                Annotation(station.name, coordinate: station.coordinate) {
                                    ZStack {
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 12, height: 12)
                                        Circle()
                                            .stroke(lineColor, lineWidth: 3)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                            }
                        }
                        .allowsHitTesting(false)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .padding(.top, 10)

                SectionDivider()

                SectionHeader(icon: "bell.fill", title: String(localized: .aggiornatoSempre))

                Text("Ti avvisiamo il giorno prima della fine dei lavori, quando spuntano nuovi cantieri sulla tua linea preferita ed anche quando sarà un Venerdì no.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                SectionDivider()

                Text("Tutti gli esempi riportati sono a scopo esemplificativo, possono essere eventi attualmente in corso o passati.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 20)
            }
            .padding(.top, 10)
        }
        .navigationTitle("Funzioni dell'app")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.red)
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.red)
        }
        .padding(.top, 10)
    }
}

private struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 56/255, green: 56/255, blue: 58/255))
            .frame(height: 1)
            .padding(20)
    }
}

private struct CardView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(Color("disclosureBg"))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 10)
    }
}

struct LibrariesView: View {
    let libraries: [LibraryDetailView] = [
        LibraryDetailView(
            name: "abseil",
            version: "1.2024072200.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2017 The Abseil Authors",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "AppCheck",
            version: "11.2.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2020 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "Firebase",
            version: "12.13.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2016 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleAdsOnDeviceConversion",
            version: "3.5.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleAppMeasurement",
            version: "12.13.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2016 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleDataTransport",
            version: "10.1.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2019 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleUtilities",
            version: "8.1.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2017 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "gRPC",
            version: "1.69.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2015 gRPC authors",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GTMSessionFetcher",
            version: "5.2.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2014 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "InteropForGoogle",
            version: "101.0.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2019 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "leveldb",
            version: "1.22.5",
            license: "BSD 3-Clause License",
            copyright: "Copyright (c) 2011 The LevelDB Authors",
            licenseText: """
            Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

            1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
            2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
            3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

            THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.
            """
        ),
        LibraryDetailView(
            name: "nanopb",
            version: "2.30910.0",
            license: "Zlib License",
            copyright: "Copyright (c) 2011 Petteri Aimonen",
            licenseText: """
            This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.

            Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

            1. The origin of this software must not be misrepresented.
            2. Altered source versions must be plainly marked as such.
            3. This notice may not be removed or altered from any source distribution.
            """
        ),
        LibraryDetailView(
            name: "Promises",
            version: "2.4.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2018 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "Supabase",
            version: "2.46.0",
            license: "MIT License",
            copyright: "Copyright (c) 2021 Supabase",
            licenseText: """
            MIT License

            Copyright (c) 2021 Supabase

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView(
            name: "swift-asn1",
            version: "1.7.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2022 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "swift-clocks",
            version: "1.0.6",
            license: "MIT License",
            copyright: "Copyright (c) 2022 Point-Free, Inc.",
            licenseText: """
            MIT License

            Copyright (c) 2022 Point-Free, Inc.

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView(
            name: "swift-concurrency-extras",
            version: "1.3.2",
            license: "MIT License",
            copyright: "Copyright (c) 2023 Point-Free, Inc.",
            licenseText: """
            MIT License

            Copyright (c) 2023 Point-Free, Inc.

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView(
            name: "swift-crypto",
            version: "4.5.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2019 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "swift-http-types",
            version: "1.5.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "SwiftUIMailView",
            version: "1.0.1",
            license: "MIT License",
            copyright: "Copyright (c) 2021 Gordan Glavaš",
            licenseText: """
            MIT License

            Copyright (c) 2021 Gordan Glavaš

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView (
            name: "xctest-dynamic-overlay",
            version: "1.9.0",
            license: "MIT License",
            copyright: "Copyright (c) 2021 Point-Free, Inc.",
            licenseText: """
            MIT License

            Copyright (c) 2021 Point-Free, Inc.

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        )
    ]
    
    var body: some View {
        List {
            ForEach(libraries, id: \.name) { library in
                NavigationLink(destination: LibraryDetailView(
                    name: library.name,
                    version: library.version,
                    license: library.license,
                    copyright: library.copyright,
                    licenseText: library.licenseText
                )) {
                    LibraryRowView(
                        name: library.name,
                        version: library.version,
                        license: library.license,
                        copyright: library.copyright
                    )
                }
            }
        }
        .navigationTitle("Librerie Open-Source")
    }
}

struct RequestDataDownload: View {
    @AppStorage("emailSaved") var emailSaved: String = ""
    
    @State private var mailData: ComposeMailData = ComposeMailData(subject: "Richiesta di Dati", recipients: ["info@lavorami.it"], message: "Buongiorno,\nVorrei richiedere l'invio dei miei dati in formato JSON dell'Account con mail: mail@mail.com", attachments: nil)
    @State private var showMailView: Bool = false
    @State private var selectedFileType: fileFormatType = .json
    
    @Binding var isRequiringData: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "person.and.background.dotted")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.red)
                    
                    Text("Richiedi i tuoi Dati")
                        .font(.system(size: 30, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Invia una richiesta al nostro Team per scaricare i tuoi dati.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            List{
                Section(footer: Text("Seleziona il formato in cui i tuoi dati verranno esportati.")){
                    Label("Formato del File:", systemImage: "arrow.down.doc.fill")
                    Picker(selection: $selectedFileType, content: {
                        ForEach(fileFormatType.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                                .foregroundStyle(Color("TextColor"))
                        }
                    }, label: {
                        Text("")
                    })
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            Spacer()
            Button(action: {
                let localizedString = String(localized: .messaggioEmailDati(selectedFileType.rawValue, emailSaved))
                let formattedBody = localizedString.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\", with: "")
                mailData = ComposeMailData(subject: String(localized: .richiestaDeiDati), recipients: ["info@lavorami.it"], message: formattedBody, attachments: nil)
                showMailView = true
            }) {
                Label("Richiedi Dati", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red)
                    .foregroundStyle(.white)
                    .cornerRadius(16)
            }
            .sheet(isPresented: $showMailView) {
                MailView(data: $mailData) { result in
                    print(result)
                }
            }
        }
        .padding()
        .navigationTitle("Aiuto")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear{
            isRequiringData = true
        }
    }
}

//MARK: LINES VIEW
struct LineRow: View {
    let line: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String
    let accessibilityStatus: String
    let stations: [MetroStation]
    @State private var supportedLines: [String] = ["1", "3", "5", "7", "9", "10", "24", "31", "33"]
    @ObservedObject var viewModel: WorkViewModel
    var onTap: (() -> Void)? = nil

    private var isDetailView: Bool {
        (typeOfTransport != "Tram" || supportedLines.contains(line))
        && typeOfTransport != "Movibus"
        && typeOfTransport != "STAV"
        && typeOfTransport != "Autoguidovie"
    }

    @ViewBuilder
    private var destination: some View {
        if isDetailView {
            LineDetailView(
                lineName: line,
                typeOfTransport: typeOfTransport,
                branches: branches,
                waitMinutes: waitMinutes,
                workScheduled: getWorkScheduled(line: line, viewModel: viewModel),
                workNow: getWorkNow(line: line, viewModel: viewModel),
                viewModel: viewModel,
                stations: stations,
                accessibilityStatus: accessibilityStatus,
                onAppear: { onTap?() }
            )
        } else {
            LineSmallDetailedView(
                lineName: line,
                typeOfTransport: typeOfTransport,
                branches: branches,
                waitMinutes: waitMinutes,
                workScheduled: getWorkScheduled(line: line, viewModel: viewModel),
                workNow: getWorkNow(line: line, viewModel: viewModel),
                accessibilityStatus: accessibilityStatus,
                viewModel: viewModel,
                onAppear: { onTap?() }
            )
        }
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Text(line)
                    .foregroundStyle(.white)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill((typeOfTransport == "Tram") ? .orange : getColor(for: line))
                    )

                if line == "MXP1" || line == "MXP2" {
                    Text(typeOfTransport)
                } else {
                    Text("\(typeOfTransport) \(line)")
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct LinesView: View {
    @Environment(\.openURL) private var openURLAction
    @ObservedObject var viewModel: WorkViewModel
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("showRecentSearches") var showRecentSearches: Bool = true

    @State private var searchInput: String = ""
    @State private var selectedURL: URL?
    @State private var showDeletePopUp: Bool = false
    @FocusState private var isSearchFocused: Bool

    // MARK: - Search helpers
    private func matches(_ line: LineInfo, query: String) -> Bool {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return true }
        
        let typeKeywords: [String: [String]] = [
            "Metro": ["metro", "metropolitana", "m"],
            "Suburbano": ["suburbano", "s"],
            "Tram": ["tram", "t"],
            "Movibus": ["bus", "movibus", "z"],
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
    var filteredSuburban: [LineInfo] { filtered(suburban) }
    var filteredTrams: [LineInfo] { filtered(trams) }
    var filteredMovibus: [LineInfo] { filtered(bus) }
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
        let all = metros + suburban + crossBorderLines + malpensaExpress + trams + bus + stav + autoguidovie
        return all.first { $0.name == name }
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
            LineInfo(name: "M1", branches: "Sesto F.S. - Rho Fiera / Bisceglie", type: "Metro", waitMinutes: "Sesto FS: 3 min | Rho/Bisceglie: 7-8 min.", stations: StationsDB.stationsM1, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M2", branches: "Gessate / Cologno - Assago / Abbiategrasso", type: "Metro", waitMinutes: "Gessate / Cologno: 12-15 min | Assago / Abbiategrasso: 9-10 min", stations: StationsDB.stationsM2, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M3", branches: "Comasina - San Donato", type: "Metro", waitMinutes: "4-5 min.", stations: StationsDB.stationsM3, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "M4", branches: "Linate Aereoporto - San Cristoforo", type: "Metro", waitMinutes: "2-3 min.",stations: StationsDB.stationsM4, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M5", branches: "Bignami - San Siro Stadio", type: "Metro", waitMinutes: "4 min.", stations: StationsDB.stationsM5, accessibilityStatus: String(localized: .lineaAccessibile))
        ]
    }
    
    var suburban: [LineInfo] {
        [
            LineInfo(name: "S1", branches: "Saronno - Lodi", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS1, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S2", branches: "Mariano Comense - Milano Rogoredo", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS2,  accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S3", branches: "Saronno - Milano Cadorna", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS3, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S4", branches: "Camnago - Milano Cadorna", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS4, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S5", branches: "Varese - Treviglio", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS5, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S6", branches: "Novara - Pioltello Limito/Treviglio", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS6, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S7", branches: "Lecco - Milano Pta Garibaldi", type: "Suburbano", waitMinutes: "30 min - \(String(localized: ._1Ora))", stations: StationsDB.stationsS7, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "S8", branches: "Lecco - Carnate - Milano Pta Garibaldi", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS8, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "S9", branches: "Saronno - Albairate Vermezzo", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS9, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "S11", branches: "Rho - Como S. Giovanni", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS11, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S12", branches: "Melegnano - Cormano Cusano Milanino", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS12, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S13", branches: "Pavia - Milano Bovisa", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS13, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S19", branches: "Albairate Vermezzo - Milano Rogoredo", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS19, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S31", branches: "Brescia - Iseo", type: "Suburbano", waitMinutes: String(localized: ._1Ora), stations: StationsDB.stationsS31, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile))
        ]
    }
    
    var crossBorderLines: [LineInfo] {
        [
            LineInfo(name: "S10", branches: "Biasca - Como S. Giovanni", type: "TILO", waitMinutes: "\(String(localized: ._1Ora)) - 45 min.", stations: StationsDB.tiloS10, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S30", branches: "Cadenazzo - Gallarate", type: "TILO", waitMinutes: String(localized: ._2Ore), stations: StationsDB.tiloS30, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S40", branches: "Como S. Giovanni - Varese", type: "TILO", waitMinutes: String(localized: ._1Ora), stations: StationsDB.tiloS40, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S50", branches: "Biasca - Milano Malpensa", type: "TILO", waitMinutes: String(localized: ._1Ora), stations: StationsDB.tiloS50, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE80", branches: "Locarno - Milano Centrale", type: "TILO", waitMinutes: "30 min - \(String(localized: ._1Ora))", stations: StationsDB.tiloRE80, accessibilityStatus: String(localized: .lineaAccessibile))
        ]
    }
    
    var malpensaExpress: [LineInfo] {
        [
            LineInfo(name: "MXP1", branches: "Gallarate - Malpensa - Milano Centrale", type: "Malpensa Express 1", waitMinutes: "30 min.", stations: StationsDB.mxp1, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "MXP2", branches: "Malpensa - Milano Cadorna", type: "Malpensa Express 2", waitMinutes: "30 min.", stations: StationsDB.mxp2, accessibilityStatus: String(localized: .lineaAccessibile)),
        ]
    }
    
    var trams: [LineInfo] {
        [
            LineInfo(name: "1", branches: "Roserio - Greco", type: "Tram", waitMinutes: "5-20 min.", stations: StationsDB.tram1, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "2", branches: "P.Le Negrelli - P.Za Bausan", type: "Tram", waitMinutes: "5-20 min.", stations: [], accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "3", branches: "Duomo M1 M3 - Gratosoglio", type: "Tram", waitMinutes: "5-20 min.", stations: StationsDB.tram3, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "4", branches: "Cairoli M1 - Niguarda (Parco Nord)", type: "Tram", waitMinutes: "5-20 min.", stations: [], accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "5", branches: "Niguarda (Ospedale) - Ortica", type: "Tram", waitMinutes: "5-20 min.", stations: StationsDB.tram5, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "7", branches: "P.Le Lagosta - Q.Re Adriano", type: "Tram", waitMinutes: "5-20 min.", stations: StationsDB.tram7, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "9", branches: "Centrale FS M2 M3 - P.Ta Genova M2", type: "Tram", waitMinutes: "5-20 min.", stations: StationsDB.tram9, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "10", branches: "P.Za 24 Maggio - V.Le Lunigiana", type: "Tram", waitMinutes: "5-20 min.", stations: StationsDB.tram10, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "12", branches: "P.Za Ovidio - Roserio (Ospedale Sacco)", type: "Tram", waitMinutes: "5-20 min.", stations: [], accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "14", branches: "Lorenteggio - Cimitero Maggiore", type: "Tram", waitMinutes: "5-20 min.", stations: [], accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "15", branches: "Duomo M1 M3 - Rozzano (Via G. Rossa)", type: "Tram", waitMinutes: "5-20 min.", stations: [], accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "16", branches: "San Siro Stadio M5 - Via Monte Velino", type: "Tram", waitMinutes: "5-20 min.", stations: [], accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "19", branches: "P.Za Castelli - Lambrate FS M2", type: "Tram", waitMinutes: "5-20 min.", stations: [], accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "24", branches: "Piazza Fontana - Vigentino", type: "Tram", waitMinutes: "5-20 min.", stations: StationsDB.tram24, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "27", branches: "V.Le Ungheria - Duomo M1 M3", type: "Tram", waitMinutes: "5-20 min.", stations: [], accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "31", branches: "Bicocca M5 - Cinisello (1° Maggio)", type: "Tram", waitMinutes: "5-20 min.", stations: StationsDB.tram31, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "33", branches: "P.Le Lagosta - Rimembranze di Lambrate", type: "Tram", waitMinutes: "5-20 min.", stations: StationsDB.tram33, accessibilityStatus: String(localized: .lineaNonAccessibile)),
        ]
    }
    
    var bus : [LineInfo] {
        [
            LineInfo(name: "z601", branches: "Legnano - Rho - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z602", branches: "Legnano - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z603", branches: "Vittore Olona / Nerviano - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z6C3", branches: "Vittore Olona - Cerro Maggiore - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z606", branches: "Cerro Maggiore - Rho - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z611", branches: "Legnano - Canegrate - Parabiago", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z612", branches: "Legnano - Cerro Maggiore - Arese", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z616", branches: "Pregnana Milanese - Rho", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z617", branches: "Origgio / Lainate - Molino Dorino M1 ", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z618", branches: "Vanzago - Pogliano M. - Rho", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z619", branches: "Pogliano M. - Plesso IST Maggiolini", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z620", branches: "Magenta - Vittuone - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z621", branches: "Cuggiono - Ossona - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z622", branches: "Cuggiono - Ossona - Cornaredo", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z625", branches: "Busto Arsizio - Busto Garolfo", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z627", branches: "Castano Primo - Legnano", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z636", branches: "Nosate - Legnano", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z641", branches: "Castano Primo - Magenta", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z642", branches: "Magenta - Legnano", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z643", branches: "Vittuone - Parabiago", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z644", branches: "Arconate - Parabiago", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z646", branches: "Magenta - Castano Primo", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z647", branches: "Cornaredo - Castano Primo", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z648", branches: "Arconate - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z649", branches: "Magenta - Arluno - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: "")
        ]
    }
    
    var stav: [LineInfo] {
        [
            LineInfo(name: "z551", branches: "Abbiategrasso Vittorio Veneto - Bisceglie M1", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z552", branches: "Abbiategrasso Vittorio Veneto - S. Stefano Ticino", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z553", branches: "Abbiategrasso - Rosate - Milano Romolo", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z554", branches: "Albairate - Albairate Vermezzo FS - Bubbiano", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z555", branches: "Abbiategrasso Vittorio Veneto - Binasco / Rosate", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z556", branches: "Abbiategrasso FS - Motta Visconti", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z557", branches: "Gaggiano De Gasperi - Gaggiano FS - San Vito", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z559", branches: "Abbiategrasso Stazione FS - Magenta FS", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z560", branches: "Abbiategrasso FS - Corsico - Bisceglie M1", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: "")
        ]
    }

    var autoguidovie: [LineInfo] {
        [
            LineInfo(name: "z401", branches: "Melzo FS - Vignate - Villa Fiorita M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z402", branches: "Cernusco M2 - Pioltello FS - S.Felice", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z403", branches: "Gorgonzola M2 - Melzo (Circolare)", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z404", branches: "Melzo FS - Inzago - Gessate M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z405", branches: "Gessate M2 - Cassano d'Adda - Treviglio", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z406", branches: "Trecella FS - Bellinzago - Gessate M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z407", branches: "Gorgonzola M2 - Truccazzano", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z409", branches: "Rodano - S. Felice - Linate Aereoporto", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z410", branches: "Pantigliate - Peschiera - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z411", branches: "Melzo FS - Settala - Pantigliate - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z412", branches: "Zelo B.P. - Paullo - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z413", branches: "Tribiano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z415", branches: "Melegnano - Dresano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z418", branches: "S.Zenone FS - Casalmaiocco", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z419", branches: "Paullo - Melzo - Gorgonzola M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z420", branches: "Vizzolo - Melegnano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z431", branches: "Melegnano FS - Carpiano/Cerro L.", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z432", branches: "Melegnano FS - Dresano  - Vizzolo (Circolare)", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),

            LineInfo(name: "z203", branches: "Muggiò - Monza FS - Cologno Nord M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z205", branches: "Limbiate Mombello - Varedo - Monza FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z209", branches: "Cesano FN - Desio - Lissone", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z219", branches: "Monza FS - Muggiò - Paderno Dugnano", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z221", branches: "Sesto S.G. - Monza FS - Carate", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z222", branches: "Monza FS - S.Fruttuoso - Sesto S.G.", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z225", branches: "Sesto S.G. - Cinisello B. - Nova M.se", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z227", branches: "Monza H/Lissone FS - Muggiò - Cinisello", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z228", branches: "Seregno FS - Lissone - Monza FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z229", branches: "Paderno ITC - Cusano - Cinisello B.", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z231", branches: "Carate - Giussano - Seregno FS - Desio", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z232", branches: "Desio - Seregno - Carate - Besana FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z233", branches: "Triuggio - Albiate - Seregno FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z234", branches: "Vedano al L. - Lissone - Muggiò", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z242", branches: "Desio - Seregno FS - Renate", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z250", branches: "Lissone FS - Desio FS - Cesano FN", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z251", branches: "Desio FS - Bovisio M. - Limbiate - Cesano FN", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: "")
        ]
    }
    
    enum linkOpenTypes: String, CaseIterable, Identifiable{
        case inApp = "In App"
        case safari = "Safari"
        
        var id: String{self.rawValue}
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
            .padding()
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
                                    Label {
                                        Text("Cercate di recente")
                                            .font(.title3)
                                            .bold()
                                            .foregroundStyle(.primary)
                                            .textCase(nil)
                                            .padding(.leading, -10)
                                    } icon: {
                                        Image(systemName: "sparkles")
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
                                    }) {
                                        Image(systemName: "delete.backward.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.bottom, 4)
                                }
                            }
                        }
                    }
                }
                Section(){
                    if(!filteredMetros.isEmpty){
                        ForEach(filteredMetros, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredMetros.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Metropolitane")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("ATM")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://giromilano.atm.it/assets/images/schema_rete_metro.jpg")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(){
                    if(!filteredSuburban.isEmpty){
                        ForEach(filteredSuburban, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredSuburban.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Suburbane")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Trenord")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.trenord.it/linee-e-orari/circolazione/le-nostre-linee/")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(){
                    if(!filteredCrossBorders.isEmpty){
                        ForEach(filteredCrossBorders, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredCrossBorders.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Transfrontaliere")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("TILO")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.tilo.ch")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(){
                    if(!filteredMalpensaExpress.isEmpty){
                        ForEach(filteredMalpensaExpress, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredMalpensaExpress.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Malpensa Express")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Trenord")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.malpensaexpress.it")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(){
                    if(!filteredTrams.isEmpty){
                        ForEach(filteredTrams, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header: {
                    if(!filteredTrams.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Tramviarie")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("ATM")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.atm.it/it/AltriServizi/Trasporto/Documents/Carta%20ATM_WEB_2025.11.pdf")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(){
                    if(!filteredMovibus.isEmpty){
                        ForEach(filteredMovibus, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, accessibilityStatus: bus.accessibilityStatus, stations: bus.stations, viewModel: viewModel, onTap: { addToRecent(bus) })
                        }
                    }
                }
                header: {
                    if(!filteredMovibus.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee di Bus")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Movibus")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://movibus.it/news/")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(){
                    if(!filteredSTAV.isEmpty){
                        ForEach(filteredSTAV, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, accessibilityStatus: bus.accessibilityStatus, stations: bus.stations, viewModel: viewModel, onTap: { addToRecent(bus) })
                        }
                    }
                }
                header: {
                    if(!filteredSTAV.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee di Bus")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("STAV")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://stavautolinee.it/reti-servite/")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(){
                    if(!filteredAutoguidovie.isEmpty){
                        ForEach(filteredAutoguidovie, id: \.id){ bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, accessibilityStatus: bus.accessibilityStatus, stations: bus.stations, viewModel: viewModel, onTap: { addToRecent(bus) })
                        }
                    }
                }
                header: {
                    if(!filteredAutoguidovie.isEmpty) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee di Bus")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Autoguidovie")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://autoguidovie.it/it/avvisi")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
            }
            .navigationTitle("Linee")
            .overlay {
                let allFiltered = [filteredMetros, filteredSuburban, filteredCrossBorders, filteredMalpensaExpress, filteredTrams, filteredMovibus, filteredSTAV, filteredAutoguidovie]
                if allFiltered.allSatisfy({ $0.isEmpty }) {
                    Text("Nessun risultato per: \"\(searchInput)\".")
                        .foregroundStyle(.secondary)
                }
            }
            .alert("Sei sicuro?", isPresented: $showDeletePopUp) {
                Button("Annulla", role: .cancel){showDeletePopUp = false}
                Button("Continua"){recentlySearchedLinesData = Data()}
            } message: {
                Text("Sei sicuro di voler cancellare le ricerche recenti?")
            }
        }
    }
}

func getWorkNow(line: String, viewModel: WorkViewModel) -> Int{
    let now = Date()
    
    return viewModel.items.filter {
        ($0.startDate <= now && $0.endDate >= now) && $0.lines.contains(line)}.count
}

func getWorkScheduled(line: String, viewModel: WorkViewModel) -> Int{
    let now = Date()
    
    return viewModel.items.filter{($0.startDate > now) && $0.lines.contains(line)}.count
}

func getCurrentWorks(line: String, viewModel: WorkViewModel) -> [WorkItem]{
    return viewModel.items.filter{$0.lines.contains(line)}
}

func getLineDeviationLink(line: String, viewModel: WorkViewModel) -> URL {
    if let i = viewModel.linesDeviated.firstIndex(of: line) {
        return URL(string: viewModel.linesDeviatedLink[i])!
    }
    
    return URL(string: "www.lavorami.it?redirect=nourlfounds")!
}

func getInterchanges(line: String) -> [InterchageInfo] {
    if Int(line) != nil {
        return StationsDB.interchangesTrams.filter { $0.lines.contains(line) }
    } else {
        return StationsDB.interchanges.filter { $0.lines.contains(line) }
    }
}

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
    
    @AppStorage("selectedWidgetLine") private var selectedWidgetLine: String = ""
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("alreadySeenPopUp") var alreadySeenPopUp: Bool = false
    @AppStorage("alreadySeenPopUpLines") var alreadySeenPopUpLines: Bool = false
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @StateObject private var networkManager = NetworkMonitor()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURLAction
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @State private var selectedURL: URL?
    
    private enum LineDetailTab { case map, works, interchanges }
    @State private var selectedTab: LineDetailTab = .map
    @State private var openPopUpWidget: Bool = false
    @State private var openPopUpLines: Bool = false
    @State private var openInfoAccessibility: Bool = false
    @State private var tramLinesSupported: [String] = ["1", "3", "5", "7", "9", "10", "24", "31", "33"]
    
    private var centerIndex: Int { max(0, stations.count / 2) }
    private var centerCoordinate: CLLocationCoordinate2D {
        stations.isEmpty ? CLLocationCoordinate2D(latitude: 45.46443, longitude: 9.18927) : stations[centerIndex].coordinate
    }
    
    private var lombardyBounds: MapCameraBounds {
        MapCameraBounds(
            centerCoordinateBounds: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 45.46443, longitude: 9.18927),
                span: MKCoordinateSpan(latitudeDelta: 1.8, longitudeDelta: 2.5)
            ),
            minimumDistance: 1000,
            maximumDistance: 175000
        )
    }
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var onAppear: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        if(lineName.contains("S") || (lineName == "MXP1" || lineName == "MXP2") || lineName == "RE80") {
                            Text(lineName)
                                .foregroundStyle(.white)
                                .font(.custom("TitilliumWeb-Bold", size: 40))
                                .padding(.vertical, 2)
                                .padding(.horizontal, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill((typeOfTransport == "Tram") ? .orange : getColor(for: lineName))
                                )
                        }
                        else if (lineName.contains("M") && (lineName != "MXP1" || lineName != "MXP2")){
                            Text(lineName)
                                .foregroundStyle(.white)
                                .font(.custom("HelveticaNeue-Bold", size: 40))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill((typeOfTransport == "Tram") ? .orange : getColor(for: lineName))
                                )
                        }
                        else {
                            Text(lineName)
                                .foregroundStyle(.white)
                                .font(.system(size: 40, weight: .bold))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill((typeOfTransport == "Tram") ? .orange : getColor(for: lineName))
                                )
                        }
                        
                        if(lineName == "MXP1" || lineName == "MXP2"){
                            Text("\(typeOfTransport)")
                                .font(.custom("TitilliumWeb-Bold", size: 30))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                        else {
                            if(lineName.contains("S") || (lineName == "MXP1" || lineName == "MXP2") || lineName == "RE80"){
                                Text("\(typeOfTransport) \(lineName)")
                                    .font(.custom("TitilliumWeb-Bold", size: 40))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                            else if(lineName.contains("M") && (lineName != "MXP1" || lineName != "MXP2")){
                                Text("\(typeOfTransport) \(lineName)")
                                    .font(.custom("HelveticaNeue-Bold", size: 30))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                            else{
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
                                DataManager.shared.setSavedLine(SavedLine(id: lineName, name: lineName, longName: typeOfTransport, iconTransport: getCurrentTransportIcon(for: typeOfTransport), worksNow: workNow, worksScheduled: workScheduled))
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
                            else{
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
                        }){
                            Image(systemName: (linesSelected.contains(lineName)) ? "star.fill" : "star")
                                .foregroundStyle((linesSelected.contains(lineName)) ? .yellow : .gray)
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
                        if(!accessibilityStatus.isEmpty){
                            HStack{
                                Image(systemName: "figure.roll")
                                    .foregroundStyle(.gray)
                                    .scaleEffect(1.5)
                                Image(systemName: (accessibilityStatus == String(localized: .lineaAccessibile) ? "checkmark.circle.fill" : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile) ? "exclamationmark.circle.fill" : "xmark.circle.fill")))
                                    .foregroundStyle(accessibilityStatus == String(localized: .lineaAccessibile) ? .green : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile) ? .yellow : .red))
                                    .scaleEffect(1.5)
                                    .padding(.leading, 5)
                                Text(accessibilityStatus)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                Spacer()
                                Button(action: {
                                    openInfoAccessibility = true;
                                }) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 5) {
                        Text("DIREZIONI:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        
                        Text(branches)
                            .font(.title3)
                            .multilineTextAlignment(.leading)
                        
                        if(lineName == "S12"){
                            Text("ATTUALMENTE LA LINEA ATTESTA A: MILANO BOVISA.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .bold()
                        }
                        if(viewModel.linesDeviated.contains(lineName)){
                            HStack {
                                Text("QUESTA LINEA DI TRAM É SOGGETTA A DEVIAZIONI.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .bold()
                                Button(action: {
                                    let url = getLineDeviationLink(line: lineName, viewModel: viewModel)
                                    
                                    if(howToOpenLinks == .inApp) {
                                        selectedURL = url
                                    }
                                    else {
                                        openURLAction(url)
                                    }
                                }) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("TEMPO DI ATTESA MEDIO:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        
                        Text(waitMinutes)
                            .font(.title3)
                            .multilineTextAlignment(.leading)
                        
                        if(lineName == "S2" || lineName == "S12" || lineName == "S19"){
                            Text("LA LINEA E' ATTIVA SOLO NEI GIORNI LAVORATIVI.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .bold()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LAVORI SULLA LINEA:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        
                        Text("\(workNow) attuali, \(workScheduled) programmati.")
                            .font(.title3)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .padding(.top, 20)
                .background(Color(uiColor: .systemBackground))
                HStack(spacing: 8) {
                    Button(action: {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                        withAnimation(.snappy) { selectedTab = .map }
                    }) {
                        Text("Mappa")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if selectedTab == .map {
                                        Capsule().fill((lineName == "S12" && colorScheme == .dark) ? .white : getColor(for: lineName))
                                    } else {
                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                    }
                                }
                            )
                            .foregroundStyle(selectedTab == .map ? ((lineName == "S19" || lineName == "S1" || lineName == "M1" || lineName == "M4") ? .white : Color(.systemBackground)) : .primary)
                    }

                    Button(action: {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                        withAnimation(.snappy) { selectedTab = .works }
                    }) {
                        Text("Lavori linea")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if selectedTab == .works {
                                        Capsule().fill((lineName == "S12" && colorScheme == .dark) ? .white : getColor(for: lineName))
                                    } else {
                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                    }
                                }
                            )
                            .foregroundStyle(selectedTab == .works ? ((lineName == "S19" || lineName == "S1" || lineName == "M1" || lineName == "M4") ? .white : Color(.systemBackground)) : .primary)
                    }
                    Button(action: {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                        withAnimation(.snappy) { selectedTab = .interchanges }
                    }) {
                        Text("Interscambi")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if selectedTab == .interchanges {
                                        Capsule().fill((lineName == "S12" && colorScheme == .dark) ? .white : getColor(for: lineName))
                                    } else {
                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                    }
                                }
                            )
                            .foregroundStyle(selectedTab == .interchanges ? ((lineName == "S19" || lineName == "S1" || lineName == "M1" || lineName == "M4") ? .white : Color(.systemBackground)) : .primary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                if selectedTab == .map {
                    Map(
                        initialPosition: .region(
                            MKCoordinateRegion(
                                center: centerCoordinate,
                                span: MKCoordinateSpan(latitudeDelta: ((tramLinesSupported.contains(lineName)) ? 0.02 : 0.15), longitudeDelta: ((tramLinesSupported.contains(lineName)) ? 0.02 : 0.15))
                            )
                        ),
                        bounds: lombardyBounds,
                        content: {
                            let lineColor: Color = getColor(for: lineName)
                            switch(lineName){
                                case "M1":
                                    MapPolyline(coordinates: stations.filter { $0.branch == "Main" }.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                    let pagano = stations.first(where: { $0.name == "Pagano" })!
                                    let bisceglie = stations.first(where: { $0.name == "Bisceglie" })!
                                    let rhoBranch = [pagano] + stations.filter { $0.branch == "Rho" }
                                    MapPolyline(coordinates: rhoBranch.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                    
                                    let bisceglieBranch = [pagano] + stations.filter { $0.branch == "Bisceglie" }
                                    MapPolyline(coordinates: bisceglieBranch.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                
                                    let bisceglieBranchNew = [bisceglie] + stations.filter { $0.branch == "Bisceglie - New" }
                                    MapPolyline(coordinates: bisceglieBranchNew.map(\.coordinate))
                                    .stroke(lineColor, style: StrokeStyle(lineWidth: 4, dash: [6, 6]))
                                
                                    ForEach(stations) { station in
                                        Annotation(station.name, coordinate: station.coordinate) {
                                            ZStack {
                                                Circle()
                                                    .fill(.white)
                                                    .frame(width: 12, height: 12)
                                                Circle()
                                                    .stroke(lineColor, lineWidth: 3)
                                                    .frame(width: 12, height: 12)
                                            }
                                        }
                                    }
                                case "M2":
                                    MapPolyline(coordinates: stations.filter { $0.branch == "Main" }.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                    let famagosta = stations.first(where: { $0.name == "Famagosta" })!
                                    let assagoBranch = [famagosta] + stations.filter { $0.branch == "Assago" }
                                    MapPolyline(coordinates: assagoBranch.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                    
                                    let abbiategrassoBranch = [famagosta] + stations.filter { $0.branch == "Abbiategrasso" }
                                    MapPolyline(coordinates: abbiategrassoBranch.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)

                                    let cascinaGobba = stations.first(where: { $0.name == "Cascina Gobba" })!
                                    let colognoBranch = [cascinaGobba] + stations.filter { $0.branch == "Cologno" }
                                    MapPolyline(coordinates: colognoBranch.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                    
                                    let gessateBranch = [cascinaGobba] + stations.filter { $0.branch == "Gessate" }
                                    MapPolyline(coordinates: gessateBranch.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                
                                    ForEach(stations) { station in
                                        Annotation(station.name, coordinate: station.coordinate) {
                                            ZStack {
                                                Circle()
                                                    .fill(.white)
                                                    .frame(width: 12, height: 12)
                                                Circle()
                                                    .stroke(lineColor, lineWidth: 3)
                                                    .frame(width: 12, height: 12)
                                            }
                                        }
                                    }

                                default:
                                    MapPolyline(coordinates: stations.filter { $0.branch == "Main" }.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                
                                    ForEach(stations) { station in
                                        Annotation(station.name, coordinate: station.coordinate) {
                                            ZStack {
                                                Circle()
                                                    .fill(.white)
                                                    .frame(width: 12, height: 12)
                                                Circle()
                                                    .stroke(lineColor, lineWidth: 3)
                                                    .frame(width: 12, height: 12)
                                            }
                                        }
                                    }
                            }
                        })
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                        .padding(.bottom, 100)
                        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                        .ignoresSafeArea(edges: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if selectedTab == .works{
                    VStack {
                        ScrollView {
                            let currentWorks = getCurrentWorks(line: lineName, viewModel: viewModel)
                            if currentWorks.count > 0 {
                                LazyVStack(spacing: 12) {
                                    ForEach(currentWorks) { work in
                                        WorkInProgressRow(item: work)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical, 8)
                            } else {
                                Label((networkManager.isConnected) ? "Non ci sono lavori su questa linea." : "Nessuna connessione ad Internet.", systemImage: (networkManager.isConnected) ? "info.circle.fill" : "wifi.slash")
                                    .padding()
                                    .bold()
                                    .font(.system(size: 15))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 10)
                }
                else {
                    VStack {
                        ScrollView {
                            let interchanges = getInterchanges(line: lineName)
                            if interchanges.count > 0 {
                                LazyVStack(spacing: 12) {
                                    ForEach(interchanges) { interchange in
                                        let item = InterchageInfo(name: interchange.name, lines: interchange.lines, typeOfInterchange: interchange.typeOfInterchange)
                                        
                                        InterchangeView(item: item, currentLine: lineName)
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
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 10)
                    .padding(.top, 6)
                }
            }
            .onAppear{
                onAppear?()
            }
            .sheet(isPresented: $openInfoAccessibility) {
                InfoAccessibilityView(showInfoView: $openInfoAccessibility)
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea(.all)
            }
            .navigationTitle("Dettagli Linea")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LineSmallDetailedView: View {
    @AppStorage("selectedWidgetLine") private var selectedWidgetLine: String = ""
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("alreadySeenPopUp") var alreadySeenPopUp: Bool = false
    @AppStorage("alreadySeenPopUpLines") var alreadySeenPopUpLines: Bool = false
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @State private var openPopUpWidget: Bool = false
    @State private var openInfoAccessibility: Bool = false
    @StateObject private var networkManager = NetworkMonitor()
    @Environment(\.openURL) private var openURLAction
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @State private var selectedURL: URL?

    let lineName: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String

    let workScheduled: Int
    let workNow: Int
    let accessibilityStatus: String
    let viewModel: WorkViewModel
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    private enum LineSmallTab { case works, arrivi }
    @State private var selectedTab: LineSmallTab = .works
    
    private var cdnURL: URL? {
        let upper = lineName.uppercased()
        return URL(string: "https://cdn.lavorami.it/gtfs/\(upper).json")
    }
    
    @State private var routeData: GTFSRoute? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var selectedStopId: String? = nil
    @State private var selectedStopName: String = ""
    @State private var currentTime = Date()
    @State private var isStartingAnimation = false
    @State private var opacity: Double = 1.0
    @State private var openPopUpLines: Bool = false

    let interchanges: [InterchangeStation] = [
        .init(key: "Molino Dorino", displayName: "Molino Dorino MM", lines: ["M1", "z601", "z606", "z617", "z620", "z621", "z648", "z649"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Cadorna FN", displayName: "Milano Cadorna FN", lines: ["M1", "M2", "MXP", "R16", "R17", "R22", "R27", "RE1", "RE7", "S3", "S4", "z602", "z603", "z6C3"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Parabiago", displayName: "Parabiago", lines: ["z611", "z644", "z643"], typeOfInterchange: "bus.fill"),
        .init(key: "Rho", displayName: "Rho FS", lines: ["S5", "S6", "S11", "z616", "z618"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Busto Garolfo", displayName: "Busto Garolfo", lines: ["z625", "z627", "z644", "z647", "z648", "z649"], typeOfInterchange: "bus.fill"),
        .init(key: "Legnano", displayName: "Legnano", lines: ["z601", "z602", "z611", "z612", "z642", "z627"], typeOfInterchange: "bus.fill"),
        .init(key: "Bisceglie", displayName: "Bisceglie MM", lines: ["M1", "z551", "z560"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Romolo", displayName: "Romolo FS", lines: ["M2", "S9", "S19", "R31"], typeOfInterchange: "train.side.front.car"),
        .init(key: "S. Stefano Ticino", displayName: "Santo Stefano Ticino - Corbetta", lines: ["S6"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Magenta", displayName: "Magenta FS", lines: ["S6", "RV", "z641", "z646", "z559"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Abbiategrasso Vittorio Veneto", displayName: "Abbiategrasso V. Veneto", lines: ["z551", "z552", "z553", "z555", "z560"], typeOfInterchange: "bus.fill"),
        .init(key: "Abbiategrasso FS", displayName: "Abbiategrasso FS", lines: ["R31", "z551", "z552", "z553", "z555", "z556", "z560"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Albairate Vermezzo FS", displayName: "Albairate Vermezzo FS", lines: ["R31", "S9", "S19"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Melzo FS", displayName: "Melzo FS", lines: ["R4", "S5", "S6", "z401", "z404", "z411"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Pioltello FS", displayName: "Pioltello Limito FS", lines: ["R4", "RE2", "RE6", "S5", "S6", "z402"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Gorgonzola", displayName: "Gorgonzola M2", lines: ["M2", "z403", "z407", "z419"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Gessate", displayName: "Gessate M2", lines: ["M2", "z405", "z406"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Linate Aereoporto", displayName: "Linate Aereoporto", lines: ["M4", "z409"], typeOfInterchange: "airplane.departure"),
        .init(key: "Donato", displayName: "San Donato M3", lines: ["M3", "z410", "z411", "z412", "z413", "z415", "z420"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Melegnano FS", displayName: "Melegnano FS", lines: ["REG", "S1", "S12", "z431", "z432"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Monza FS", displayName: "Monza FS", lines: ["R7", "R13", "R14", "RE8", "RE80", "S7", "S8", "S9", "S11", "z203", "z205", "z219", "z221", "z222", "z228"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Sesto S.G", displayName: "Sesto San Giovanni FS M1", lines: ["M1", "R13", "R14", "RE8", "S7", "S8", "S9", "S11", "z221", "z222", "z225"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Seregno", displayName: "Seregno FS", lines: ["RE80", "S9", "S11", "z231", "z232", "z233", "z242"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Desio FS", displayName: "Desio FS", lines: ["RE80", "S9", "S11", "z250", "z251"], typeOfInterchange: "train.side.front.car")
    ]

    var activeInterchange: InterchangeStation? {
        interchanges.first { branches.contains($0.key) }
    }
    
    var onAppear: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Text(lineName)
                            .foregroundStyle(.white)
                            .font(.system(size: 40, weight: .bold))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill((typeOfTransport == "Tram") ? .orange : getColor(for: lineName))
                            )

                        Text("\(typeOfTransport) \(lineName)")
                            .font(.system(size: 30))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Spacer()

                        Button(action: {
                            if selectedWidgetLine == lineName {
                                selectedWidgetLine = ""
                                DataManager.shared.deleteSavedLine()
                            } else {
                                DataManager.shared.setSavedLine(SavedLine(
                                    id: lineName, name: lineName, longName: typeOfTransport,
                                    iconTransport: getCurrentTransportIcon(for: typeOfTransport),
                                    worksNow: workNow, worksScheduled: workScheduled
                                ))
                                selectedWidgetLine = lineName
                                if(!alreadySeenPopUp) {
                                    alreadySeenPopUp = true
                                    openPopUpWidget = true
                                }
                            }
                        }) {
                            Image(systemName: (selectedWidgetLine == lineName) ? "widget.small" : "widget.small.badge.plus")
                                .foregroundStyle((selectedWidgetLine == lineName) ? .yellow : .gray)
                                .scaleEffect(1.5)
                        }
                        .alert("Linea attivata", isPresented: $openPopUpWidget) {
                            Button("OK", role: .cancel) {}
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
                        }){
                            Image(systemName: (linesSelected.contains(lineName)) ? "star.fill" : "star")
                                .foregroundStyle((linesSelected.contains(lineName)) ? .yellow : .gray)
                                .scaleEffect(1.5)
                        }
                        .padding(.leading, 10)
                        .alert("Linea salvata", isPresented: $openPopUpLines) {
                            Button("OK", role: .cancel){}
                        } message: {
                            Text("La linea \(lineName) è stata aggiunta nella sezione \"Le tue linee\"!")
                        }
                    }

                    if !accessibilityStatus.isEmpty {
                        HStack {
                            Image(systemName: "figure.roll")
                                .foregroundStyle(.gray)
                                .scaleEffect(1.5)
                            Image(systemName: accessibilityStatus == String(localized: .lineaAccessibile)
                                ? "checkmark.circle.fill"
                                : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile)
                                    ? "exclamationmark.circle.fill"
                                    : "xmark.circle.fill"))
                                .foregroundStyle(accessibilityStatus == String(localized: .lineaAccessibile)
                                    ? .green
                                    : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile) ? .yellow : .red))
                                .scaleEffect(1.5)
                                .padding(.leading, 5)
                            Text(accessibilityStatus)
                                .foregroundColor(.secondary)
                                .padding(.leading, 5)
                            Spacer()
                            Button(action: { openInfoAccessibility = true }) {
                                Image(systemName: "info.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 5) {
                        Text("DIREZIONI:")
                            .font(.caption).foregroundStyle(.secondary).bold()
                        Text(branches)
                            .font(.title3).multilineTextAlignment(.leading)

                        if viewModel.linesDeviated.contains(lineName) {
                            HStack {
                                Text("QUESTA LINEA DI TRAM É SOGGETTA A DEVIAZIONI.")
                                    .font(.system(size: 12)).foregroundStyle(.secondary).bold()
                                Button(action: {
                                    let url = getLineDeviationLink(line: lineName, viewModel: viewModel)
                                    if howToOpenLinks == .inApp { selectedURL = url }
                                    else { openURLAction(url) }
                                }) {
                                    Image(systemName: "info.circle.fill").foregroundColor(.gray)
                                }
                            }
                        }
                    }

                    if !waitMinutes.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("TEMPO DI ATTESA MEDIO:")
                                .font(.caption).foregroundStyle(.secondary).bold()
                            Text(waitMinutes)
                                .font(.title3).multilineTextAlignment(.leading)
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
                                Text("Nessuna fermata di interscambio.").foregroundColor(.secondary)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("LAVORI SULLA LINEA:")
                            .font(.caption).foregroundStyle(.secondary).bold()
                        Text("\(workNow) attuali, \(workScheduled) programmati.")
                            .font(.title3).multilineTextAlignment(.leading)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .background(Color(uiColor: .systemBackground))

                // MARK: - Tab Bar
                HStack(spacing: 8) {
                    Button(action: {
                        if feedbacksEnabled { HapticManager.shared.trigger() }
                        withAnimation(.snappy) { selectedTab = .works }
                    }) {
                        Text("Lavori linea")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if selectedTab == .works {
                                        Capsule().fill(getColor(for: lineName))
                                    } else {
                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                    }
                                }
                            )
                            .foregroundStyle(selectedTab == .works ? .white : .primary)
                    }

                    if(viewModel.linesSupportedGTFS.contains(lineName)) {
                        Button(action: {
                            if feedbacksEnabled { HapticManager.shared.trigger() }
                            withAnimation(.snappy) { selectedTab = .arrivi }
                        }) {
                            Text("Arrivi")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    ZStack {
                                        if selectedTab == .arrivi {
                                            Capsule().fill(getColor(for: lineName))
                                        } else {
                                            Capsule().stroke(Color.secondary, lineWidth: 1)
                                        }
                                    }
                                )
                                .foregroundStyle(selectedTab == .arrivi ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // MARK: - Tab Content
                if selectedTab == .works {
                    VStack {
                        ScrollView {
                            let currentWorks = getCurrentWorks(line: lineName, viewModel: viewModel)
                            if currentWorks.count > 0 {
                                LazyVStack(spacing: 12) {
                                    ForEach(currentWorks) { work in
                                        WorkInProgressRow(item: WorkItem(
                                            title: work.title, titleIcon: work.titleIcon,
                                            typeOfTransport: work.typeOfTransport, roads: work.roads,
                                            lines: work.lines, startDate: work.startDate,
                                            endDate: work.endDate, details: work.details,
                                            company: work.company
                                        ))
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical, 8)
                            } else {
                                Label((networkManager.isConnected) ? "Non ci sono lavori su questa linea." : "Nessuna connessione ad Internet.", systemImage: (networkManager.isConnected) ? "info.circle.fill" : "wifi.slash")
                                    .padding().bold().font(.system(size: 15))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 10)
                } else if selectedTab == .arrivi {
                    VStack(spacing: 0) {
                        if isLoading {
                            Spacer()
                            ProgressView("Caricamento orari...")
                                .controlSize(.large)
                            Spacer()
                        } else if let route = routeData {
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
                            if let stopId = selectedStopId, let departuresByDir = GTFSHelper.getDepartures(for: stopId, in: route, limit: 3) {
                                ScrollView {
                                    VStack(spacing: 14) {
                                        ForEach(Array(departuresByDir.keys).sorted(), id: \.self) { dirId in
                                            let departures = departuresByDir[dirId] ?? []
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
                                                    let first = departures[0]
                                                    let rest = Array(departures.dropFirst().prefix(3))
                                                    
                                                    VStack(alignment: .leading, spacing: 12) {
                                                        HStack(alignment: .center, spacing: 10) {
                                                            Image(systemName: "clock.fill")
                                                                .foregroundStyle((first.minutesFromNow < 10) ? ((first.minutesFromNow < 5) ? ((first.minutesFromNow == 0) ? .yellow : .red) : .orange) : .green)
                                                                .font(.system(size: 18))

                                                            Text(first.minutesFromNow == 0 ? "In partenza" : "\(first.minutesFromNow) min")
                                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                                .foregroundStyle((first.minutesFromNow < 10) ? ((first.minutesFromNow < 5) ? ((first.minutesFromNow == 0) ? .yellow : .red) : .orange) : .green)

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
                                                                        Image(systemName: "clock")
                                                                            .font(.caption2)
                                                                            .foregroundStyle(.secondary)
                                                                        Text("\(dep.minutesFromNow) min")
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
                                            }
                                        }
                                    }
                                }

                            } else if selectedStopId != nil {
                                Spacer()
                                ContentUnavailableView("Nessuna corsa", systemImage: "clock.badge.exclamationmark", description: Text("Non ci sono corse disponibili per questa fermata oggi."))
                                Spacer()
                            } else {
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

                        } else if let error = errorMessage {
                            Spacer()
                            ContentUnavailableView("Errore", systemImage: "exclamationmark.triangle", description: Text(error))
                            Spacer()
                        }
                    }
                    .id(currentTime)
                    .onReceive(timer) { newTime in
                        currentTime = newTime
                    }
                }
            }
            .onAppear {
                onAppear?()
            }
            .sheet(isPresented: $openInfoAccessibility) {
                InfoAccessibilityView(showInfoView: $openInfoAccessibility)
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url).ignoresSafeArea(.all)
            }
            .onAppear { if routeData == nil { loadData() } }
            .navigationTitle("Dettagli Linea")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func sortedStops(route: GTFSRoute) -> [(id: String, name: String)] {
        route.stops.map { ($0.key, $0.value.n) }.sorted { $0.name < $1.name }
    }

    private func loadData() {
        guard let url = cdnURL else { return }
        isLoading = true
        Task {
            do {
                let route = try await GTFSHelper.load(from: url)
                await MainActor.run {
                    self.routeData = route
                    self.isLoading = false
                    if self.selectedStopId == nil {
                        self.selectedStopId = sortedStops(route: route).first?.id
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Errore nel caricamento dati."
                    self.isLoading = false
                }
            }
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeIn(duration: 0.15).delay(1.05)) {
            opacity = 0.5
        }
        withAnimation(.easeIn(duration: 0.15).delay(1.35)) {
            opacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            startAnimation()
        }
    }
}

struct InfoAccessibilityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage = 0
    @State var startImageTransition: Bool = false
    @State var imageTransitionFirstPage: Bool = false
    @State var i = 0
    @Binding var showInfoView: Bool
    @AppStorage("enableAnimations") var enableAnimations = true

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {
                    ScrollView {
                        VStack(spacing: 30) {
                            if #available(iOS 18.0, *), enableAnimations {
                                Image(systemName: startImageTransition ? "figure.roll" : "person.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                                    .padding(.top, 50)
                                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                                    .onAppear {
                                        Task {
                                            try? await Task.sleep(for: .seconds(1))
                                            withAnimation {
                                                startImageTransition = true
                                            }
                                        }
                                    }
                                    .onDisappear {
                                        startImageTransition = false
                                    }
                            } else {
                                Image(systemName: "figure.roll")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                                    .padding(.top, 40)
                            }

                            Text("Informazioni sull'Accessibilità")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text("LavoraMi mostra l'accessibilità di una linea in base agli impianti nelle stazioni ed alla tipologia di mezzo utilizzato.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("LavoraMi prende queste informazioni da fonti autorevoli e affidabili, i dati potrebbero non essere aggiornati all'ultimo minuto.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            VStack(alignment: .leading, spacing: 20) {
                                accessibilitySection(
                                    icon: "checkmark.circle.fill",
                                    color: .green,
                                    title: String(localized: .completamenteAccessibile),
                                    description: String(localized: .completamenteAccessibileDeps)
                                )
                                Divider()
                                accessibilitySection(
                                    icon: "exclamationmark.circle.fill",
                                    color: .orange,
                                    title: String(localized: .parzialmenteAccessibile),
                                    description: String(localized: .parzialmenteAccessibileDeps)
                                )
                                Divider()
                                accessibilitySection(
                                    icon: "xmark.circle.fill",
                                    color: .red,
                                    title: String(localized: .nonAccessibile),
                                    description: String(localized: .nonAccessibileDeps)
                                )
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(15)
                        }
                        .padding()
                    }
                    .tag(0)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Accessibilità")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func dismiss() {
        showInfoView = false
        presentationMode.wrappedValue.dismiss()
    }

    @ViewBuilder
    private func accessibilitySection(icon: String, color: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.roll")
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                .font(.headline)

                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }

            Text(description)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

struct WhatsNewViewBase: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage = 0
    
    let pages = [
        SetupPage(
            title: "Cosa c'è di nuovo?",
            description: "Scorri e scopri cosa abbiamo aggiunto, migliorato oppure sistemato!",
            transitionImage: "person.fill.questionmark",
            standardImage: "checkmark.seal.fill",
            fallbackImage: "checkmark.seal.fill"
        ),
        SetupPage(
            title: "Consulta gli orari dei bus",
            description: "Ora puoi consultare le prossime 3 partenze della tua linea di bus preferita, basta andare nella nuova scheda \"Arrivi\"!",
            transitionImage: "clock.fill",
            standardImage: "bus.fill",
            fallbackImage: "bus.fill"
        ),
        SetupPage(
            title: "Nuove linee con le mappe",
            description: "Ora le linee di Tram 9 e 31 hanno le mappe! Vai a consultarle subito!",
            transitionImage: "location.fill",
            standardImage: "tram.fill",
            fallbackImage: "tram.fill"
        ),
        SetupPage(
            title: "Supportaci con le donazioni!",
            description: "Abbiamo aggiunto le donazioni! Ora puoi supportarci su Buy Me A Coffee e Patreon!",
            transitionImage: "square.and.arrow.up",
            standardImage: "arrow.up.right",
            fallbackImage: "arrow.up.right"
        ),
        SetupPage(
            title: "Le tue ricerche, sempre lì.",
            description: "Ora puoi vedere le tue ricerche e riprendere il tuo viaggio da dove lo hai interrotto.",
            transitionImage: "sparkles.2",
            standardImage: "sparkles",
            fallbackImage: "sparkles"
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0 ..< pages.count, id: \.self) { index in
                        WhatsNewView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color("TextColor") : Color.gray.opacity(0.4))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 8)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Chiudi")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle(Text("Novità"))
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
        NotificationManager.shared.requestPermission()
    }
}

struct WhatsNewView: View {
    @State var startImageTransition : Bool = false
    @State var imageTransitionFirstPage: Bool = false
    @State var i = 0
    @AppStorage("enableAnimations") var enableAnimations = true
    let page: SetupPage

    var body: some View {
        VStack(spacing: 30) {
            if #available(iOS 18.0, *), enableAnimations {
                Image(systemName: (startImageTransition) ? page.standardImage : page.transitionImage)
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.top, 50)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                    .onAppear {
                        startImageTransition = false
                        Task{
                            try? await Task.sleep(for: .seconds(1))
                            withAnimation{
                                startImageTransition = true
                            }
                        }
                    }
                    .onDisappear{
                        startImageTransition = false
                    }
            }
            else {
                Image(systemName: page.fallbackImage ?? page.standardImage)
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.top, 50)
            }

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

struct AIFeaturesInfo: View {
    @State var startImageTransition : Bool = false
    @State var imageTransitionFirstPage: Bool = false
    @State var i = 0
    @AppStorage("enableAnimations") var enableAnimations = true

    var body: some View {
        VStack(spacing: 30) {
            if #available(iOS 18.0, *), enableAnimations {
                Image(systemName: (startImageTransition) ? "sparkles.2" : "sparkle")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.top, 50)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                    .onAppear {
                        startImageTransition = false
                        Task{
                            try? await Task.sleep(for: .seconds(1))
                            withAnimation{
                                startImageTransition = true
                            }
                        }
                    }
                    .onDisappear{
                        startImageTransition = false
                    }
            }
            else {
                Image(systemName: "sparkle")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.top, 50)
            }

            Text("Seleziona le tue linee.")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("La nuova funzione \"Le tue linee\" mostra i lavori delle linee che ti interessano. Nessuna distrazione da altri lavori.")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Per un uso corretto di questa funzione, potremmo chiederti di attivare la Posizione per vedere le linee che sono vicino a te.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

struct InterchangeView: View {
    let item: InterchageInfo
    let currentLine: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if(item.name == "Lodi TIBB"){
                Label("Milano Scalo Romana FS", systemImage: "arrow.left.and.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("TextColor"))
            }
            else{
                Label(item.name, systemImage: "arrow.left.and.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("TextColor"))
            }
            
            HStack {
                Text(currentLine)
                    .font(.headline)
                Image(systemName: item.typeOfInterchange)
                Text(item.name)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(item.lines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(getColor(for: line))
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}

struct TransportBadge: View {
    let line: String
    private var badgeColor: Color {
        if line.starts(with: "z") {
            return getColor(for: "z")
        }
        return getColor(for: line)
    }

    var body: some View {
        Text(line)
            .foregroundStyle(.white)
            .font(.system(size: 20, weight: .bold))
            .padding(.vertical, 4)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(badgeColor)
            )
    }
}

//MARK: UTILITIES
//NOTE: FILTERS
enum FilterBy: String, CaseIterable, Identifiable {
    case suggested = "Le tue linee"
    case all = "Tutti"
    case bus = "Bus"
    case tram = "Tram"
    case metro = "Metropolitana"
    case train = "Treno"
    case working = "In Corso"
    case scheduled = "Programmati"
    case ATM = "di ATM"
    case Trenord = "di Trenord"
    case Movibus = "di Movibus"
    case STAV = "di STAV"
    case Autoguidovie = "di Autoguidovie"
    
    var localizedTitle: String {
        switch self {
            case .suggested: return "Le tue linee"
            case .all: return String(localized: .tutti)
            case .bus: return "Bus"
            case .tram: return "Tram"
            case .metro : return String(localized: .metropolitana)
            case .train: return String(localized: .treno)
            case .working: return String(localized: .inCorso)
            case .scheduled: return String(localized: .programmati)
            case .ATM: return String(localized: .diAtm)
            case .Trenord: return String(localized: .diTrenord)
            case .Movibus: return String(localized: .diMovibus)
            case .STAV: return String(localized: .diStav)
            case .Autoguidovie: return String(localized: .diAutoguidovie)
        }
    }
    
    var id: String{self.rawValue}
}

enum AppearanceType: Int, CaseIterable, Identifiable {
    case system = 0
    case dark = 1
    case light = 2
    
    var description: String {
        switch self {
            case .system: return String(localized: .sistema)
            case .light: return String(localized: .chiaro)
            case .dark: return String(localized: .scuro)
        }
    }
    
    var iconName: String {
        switch self {
            case .system: return "gear"
            case .dark: return "moon.fill"
            case .light: return "sun.max.fill"
        }
    }
    
    var id: Int{self.rawValue}
}

struct LineInfo: Identifiable{
    let id = UUID()
    let name: String
    let branches: String
    let type: String
    let waitMinutes: String
    let stations: [MetroStation]
    let accessibilityStatus: String
}

struct LineShortInfo: Identifiable{
    let id = UUID()
    let name: String
}

struct InterchageInfo: Identifiable {
    let id = UUID()
    let name: String
    let lines: [String]
    let typeOfInterchange: String
}

struct MetroStation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let branch: String
}

struct InterchangeStation: Identifiable {
    let id = UUID()
    let key: String
    let displayName: String
    let lines: [String]
    let typeOfInterchange: String
}

enum linkOpenTypes: String, CaseIterable, Identifiable{
    case inApp = "In App"
    case safari = "Safari"
    
    var id: String{self.rawValue}
}

enum fileFormatType: String, CaseIterable, Identifiable{
    case json = "Json"
    case html = "HTML"
    
    var id: String{self.rawValue}
}

func getColor(for line: String) -> Color {
    switch line {
        ///SUBURBAN LINES
        case "S1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "S2": return Color(red: 0, green: 152/255, blue: 121/255)
        case "S3": return Color(red: 169/255, green: 10/255, blue: 46/255)
        case "S4": return Color(red: 131/255, green: 187/255, blue: 38/255)
        case "S5": return Color(red: 243/255, green: 145/255, blue: 35/255)
        case "S6": return Color(red: 246/255, green: 210/255, blue: 0)
        case "S7": return Color(red: 229/255, green: 0, blue: 113/255)
        case "S8": return Color(red: 246/255, green: 182/255, blue: 182/255)
        case "S9": return Color(red: 162/255, green: 51/255, blue: 138/255)
        case "S11": return Color(red: 165/255, green: 147/255, blue: 198/255)
        case "S12": return .black
        case "S13": return Color(red: 167/255, green: 109/255, blue: 17/255)
        case "S19": return Color(red: 102/255, green: 13/255, blue: 54/255)
        case "S31": return .gray
        
        ///TILO LINES
        case "S10": return Color(red: 228/255, green: 35/255, blue: 19/255)
        case "S30": return Color(red: 0, green: 166/255, blue: 81/255)
        case "S40": return Color(red: 117/255, green: 188/255, blue: 118/255)
        case "S50": return Color(red: 131/255, green: 76/255, blue: 22/255)
        case "RE80": return .blue
        
        ///METRO LINES
        case "M1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "NM1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "M2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "NM2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "M3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "NM3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "M4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "NM4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "M5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        case "NM5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        
        ///BUS LINES
        case _ where line.contains("z"): return Color(red: 28/255, green: 28/255, blue: 1)
        case _ where line.contains("Filobus"): return Color(red: 101/255, green: 179/255, blue: 46/255)
        case _ where line.contains("P") && !(line.contains("MXP")): return Color(red: 69/255, green: 56/255, blue: 0)
        
        ///OTHER LINES
        case "MXP": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP1": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP2": return Color(red: 140/255, green: 0, blue: 118/255)
        case "AV": return .red
        case "Aereoporto": return .cyan
        case _ where line.contains("R") && !line.contains("RE"): return Color.blue
        case _ where line.contains("RE"): return Color.red
        case let s where (1...33).contains(Int(s) ?? 0): return .orange
        case _ where line.starts(with: "N"): return Color(red: 2/255, green: 27/255, blue: 129/255)
        
        ///FALLBACK CASE
        default: return Color(red: 101/255, green: 179/255, blue: 46/255)
    }
}

func getCurrentTransportIcon(for lineLongName: String) -> String{
    switch(lineLongName){
        case "Suburbano":
            return "train.side.front.car"
        case "TILO":
            return "train.side.front.car"
        case "Malpensa Express":
            return "train.side.front.car"
            
        case "Metro":
            return "tram.tunnel.fill"
            
        case "Autoguidovie":
            return "bus.fill"
        case "STAV":
            return "bus.fill"
        case "Movibus":
            return "bus.fill"
            
        case "Tram":
            return "tram.fill"
        
        default:
            return "train.side.front.car"
    }
}

func getIconForFilter(for filterName: String) -> String{
    switch(filterName){
        case "Le tue linee":
            return "sparkle"
        case "Tutti":
            return "line.3.horizontal.decrease"
        case "Bus":
            return "bus.fill"
        case "Tram":
            return "tram.fill"
        case "Metropolitana":
            return "tram.tunnel.fill"
        case "Treno":
            return "train.side.front.car"
        case "In Corso":
            return "clock.badge.exclamationmark.fill"
        case "Programmati":
            return "calendar.badge.clock"
            
        default:
            return ""
    }
}

//EXTENSION: Save files also with arrays
extension Array: @retroactive RawRepresentable where Element == String {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([String].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

extension WorkItem {
    func matchesFavorites(_ favorites: [String]) -> Bool {
        let transport = self.typeOfTransport.lowercased()
        
        let linesLower = self.lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        
        if favorites.contains("Bus") {
            let isRubberTire = transport.contains("bus") || transport.contains("autobus")
            let isMovibus = transport.contains("movibus") || linesLower.contains { $0.hasPrefix("z6") }
            let isStav = transport.contains("stav") || linesLower.contains { $0.hasPrefix("z5") }
            let isAutoguidovie = transport.contains("Autoguidovie") || linesLower.contains {
                $0.hasPrefix("z4") || $0.hasPrefix("z2")
            }
            
            if isRubberTire && !isMovibus && !isStav && !isAutoguidovie {
                return true
            }
        }
        
        if favorites.contains("z6") {
            if transport.contains("movibus") { return true }
            if linesLower.contains(where: { $0.hasPrefix("z6") }) { return true }
        }
        
        if favorites.contains("z5"){
            if transport.contains("stav") { return true }
            if linesLower.contains(where: { $0.hasPrefix("z5") }) { return true }
        }
        
        if favorites.contains("Autoguidovie") {
            if transport.contains("Autoguidovie") { return true }
            if linesLower.contains(where: {
                $0.hasPrefix("z4") || $0.hasPrefix("z2")
            }) {
                return true
            }
        }
        
        if favorites.contains("Tram") {
            let isTram = transport.contains("tram") &&
                        !transport.contains("tram.fill.tunnel") &&
                        !transport.contains("metro")
            if isTram { return true }
        }
        
        for workLine in self.lines {
            let cleanWorkLine = workLine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let upperLine = workLine.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            for fav in favorites {
                let cleanFav = fav.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if cleanWorkLine == cleanFav {
                    return true
                }
            }
            
            if favorites.contains("S") && upperLine.hasPrefix("S") {
                let suffix = upperLine.dropFirst()
                if !suffix.isEmpty && suffix.allSatisfy({ $0.isNumber }) {
                    return true
                }
            }
            
            if favorites.contains("R") && upperLine.hasPrefix("R") && !upperLine.hasPrefix("RE") {
                return true
            }
            
            if favorites.contains("RE") && upperLine.hasPrefix("RE") {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Bundle version helpers
extension Bundle {
    /// CFBundleShortVersionString (e.g., 1.2.3)
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// CFBundleVersion (build number)
    var buildVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}

extension URL: @retroactive Identifiable { public var id: String { absoluteString }}

extension Date: @retroactive RawRepresentable {
    private static let isoFormatter = ISO8601DateFormatter()

    public var rawValue: String {
        Date.isoFormatter.string(from: self)
    }

    public init?(rawValue: String) {
        if let date = Date.isoFormatter.date(from: rawValue) {
            self = date
        } else {
            self = Date()
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        
        let safariVC = SFSafariViewController(url: url, configuration: configuration)
        safariVC.preferredControlTintColor = .systemBlue
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct HapticManager {
    static let shared = HapticManager()
    private let generator = UIImpactFeedbackGenerator(style: .light)
        
    func trigger() {
        generator.prepare()
        generator.impactOccurred()
    }
}


#Preview{
    @Previewable @State var showSetupScreen: Bool = false
    @Previewable @State var showWhatsNewScreen: Bool = false
    ContentView(showSetupScreen: $showSetupScreen, showWhatsNewScreen: $showWhatsNewScreen)
}
