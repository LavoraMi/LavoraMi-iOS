//
//  MainView.swift
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

struct MainView: View {
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    @AppStorage("showErrorMessages") var showErrorMessages: Bool = false
    @AppStorage("showStrikeBanner") var showStrikeBanner: Bool = true
    @AppStorage("linesFavorites") var linesFavorites: [String] = []
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    
    @State private var closedStrike: Bool = false
    @State private var selectedFilter: FilterBy = .all
    @State private var searchInput: String = ""
    @State private var alreadyRefreshed: Bool = false
    @State private var adsRequested: Bool = false
    @State private var showInfoFavoriteLines: Bool = false
    @State private var showMaintenanceMode: Bool = false
    @State private var strikeExpanded: Bool = true
    @AppStorage("hasOpenedWrapped") private var hasOpenedWrapped: Bool = false
    @State private var showWrapped: Bool = false
    @State private var showWrappedOpenedInfo: Bool = false
    @State private var livePulse = true
    @State private var suggestedTrigger = 0
    @State private var marqueeOffset: CGFloat = 0
    @State private var marqueeContainerWidth: CGFloat = 0
    @State private var marqueeId = UUID()
    
    @ObservedObject var viewModel: WorkViewModel
    @StateObject var authManager = AuthManager()
    @StateObject var adMobManager = AdMobManager()
    @ObservedObject var consentManager = ConsentManager.shared
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
            case .Tilo:
                categoryFiltered = items.filter{ $0.company.contains("TILO") }
            case .Movibus:
                categoryFiltered = items.filter{ $0.company.contains("Movibus") }
            case .Net:
                categoryFiltered = items.filter{ $0.company.contains("NET") }
            case .STAV:
                categoryFiltered = items.filter{ $0.company.contains("STAV") }
            case .STAR:
                categoryFiltered = items.filter { $0.company.contains("STAR") }
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
                let matchLines = item.lines.contains { $0.localizedCaseInsensitiveContains(searchInput) }
                let matchRoads = item.roads.localizedCaseInsensitiveContains(searchInput)
                let matchDetails = item.details.localizedCaseInsensitiveContains(searchInput)
                
                return matchLines || matchRoads || matchDetails
            }
        }
    }

    var body: some View {
        NavigationStack{
            MainHeaderView(viewModel: viewModel, showMaintenanceMode: $showMaintenanceMode)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 5)
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentHintIndex = (currentHintIndex + 1) % searchHints.count
                    }
                }
            }
            if viewModel.wrappedEnabled && !hasOpenedWrapped {
                Button(action: {
                    if feedbacksEnabled { HapticManager.shared.trigger() }
                    showWrapped = true
                }) {
                    HStack(spacing: 8) {
                        Image("iconAppAndroid")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .clipShape(RoundedRectangle(cornerRadius: 5))

                        Text("SCOPRI IL WRAPPED DI QUESTO MESE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .tracking(0.5)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color(red: 224/255, green: 32/255, blue: 34/255))
                }
                .buttonStyle(.plain)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            if viewModel.strikeEnabled && showStrikeBanner {
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(duration: 0.3)) {
                            closedStrike.toggle()
                        }
                        if feedbacksEnabled { HapticManager.shared.trigger() }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)

                            Text("AVVISO SCIOPERO")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(0.5)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .rotationEffect(.degrees(closedStrike ? -90 : 0))
                                .animation(.spring(duration: 0.3), value: closedStrike)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Color.red)
                    }
                    .buttonStyle(.plain)
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
                            Text("Fasce garantite \(viewModel.guaranteed)")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Divider()
                            .padding(.vertical, 2)

                        if(viewModel.isStrikeToday) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.35))
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(livePulse ? 2.8 : 1.0)
                                        .opacity(livePulse ? 0.0 : 1.0)
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                }
                                .frame(width: 16, height: 16)
                                .onAppear {
                                    livePulse = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                                            livePulse = true
                                        }
                                    }
                                }

                                Text("LIVE: ")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)

                                MarqueeText(text: viewModel.strikeUpdateLive)
                                    .id(marqueeId)
                            }
                            
                            Divider()
                                .padding(.vertical, 2)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                            Text("Aderenti:")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            if viewModel.companiesStrikes.split(separator: ", ").count < 4 {
                                Text(viewModel.companiesStrikes)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        if viewModel.companiesStrikes.split(separator: ", ").count >= 4 {
                            Text(viewModel.companiesStrikes)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, closedStrike ? 0 : 12)
                    .background(Color(.secondarySystemBackground))
                    .frame(height: closedStrike ? 0 : nil, alignment: .top)
                    .opacity(closedStrike ? 0 : 1)
                    .clipped()
                }
                .onChange(of: closedStrike) { oldValue, newValue in
                    if !newValue {
                        marqueeId = UUID()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .red.opacity(0.12), radius: 8, x: 0, y: 3)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
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
                                    if(selectedFilter == .suggested) {
                                        if #available(iOS 18, *) {
                                            Label(filter.localizedTitle, systemImage: nameIcon)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .symbolEffect(.rotate, options: .nonRepeating, value: filter == .suggested ? suggestedTrigger : 0)
                                            .background(
                                                ZStack {
                                                    if selectedFilter == filter {
                                                        Capsule().fill(.red.gradient)
                                                    } else {
                                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                                    }
                                                }
                                            )
                                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                        } else {
                                            Label(filter.localizedTitle, systemImage: nameIcon)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(
                                                ZStack {
                                                    if selectedFilter == filter {
                                                        Capsule().fill(.red.gradient)
                                                    } else {
                                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                                    }
                                                }
                                            )
                                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                        }
                                    }
                                    else {
                                        Label(filter.localizedTitle, systemImage: nameIcon)
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
                                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                    }
                                }
                                else {
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
                                    .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                }
                            }
                            .id(filter)
                        }
                    }
                    .padding(.horizontal)
                    .onAppear(){
                        if(selectedFilter != .suggested && selectedFilter != .all && selectedFilter != .bus) {
                            withAnimation {
                                proxy.scrollTo(selectedFilter, anchor: .center)
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
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
                                        viewModel.fetchMetroStatus()
                                        
                                        showMaintenanceMode = viewModel.maintenanceModeEnabled
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
                                let currentFilteredItems = filteredItems
                                VStack(spacing: 12) {
                                    if currentFilteredItems.isEmpty && searchInput.isEmpty {
                                        if selectedFilter == .suggested {
                                            Button {
                                                showInfoFavoriteLines = true
                                            } label: {
                                                Label("Come funziona?", systemImage: "questionmark.circle.fill")
                                                    .font(.footnote.weight(.semibold))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.accentColor.opacity(0.15))
                                                    .foregroundStyle(Color.accentColor)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        VStack(spacing: 20) {
                                            Image(systemName: "rectangle.and.text.magnifyingglass")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.primary)
                                            VStack(spacing: 8) {
                                                Text("Nessun lavoro trovato per questo filtro")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.center)
                                                Text("Prova a modificare i filtri selezionati per trovare altri lavori.")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(.secondary)
                                                    .multilineTextAlignment(.center)
                                            }
                                            Button(action: {
                                                withAnimation(.snappy) {
                                                    if(feedbacksEnabled){
                                                        HapticManager.shared.trigger()
                                                    }
                                                    selectedFilter = .all
                                                }
                                            }) {
                                                Text("Mostra tutti i lavori")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 10)
                                                    .background(Color.red)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .padding(.horizontal, 32)
                                        .padding(.bottom, 50)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .containerRelativeFrame(.vertical)
                                    }
                                    else if currentFilteredItems.isEmpty && !searchInput.isEmpty {
                                        VStack(spacing: 20) {
                                            Image(systemName: "exclamationmark.magnifyingglass")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.primary)
                                            VStack(spacing: 8) {
                                                Text("Nessun lavoro trovato per: \"\(searchInput)\"")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.center)
                                                Text("Prova a cercare qualcos'altro.")
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
                                    else {
                                        if selectedFilter == .suggested {
                                            Button {
                                                showInfoFavoriteLines = true
                                            } label: {
                                                Label("Come funziona?", systemImage: "questionmark.circle.fill")
                                                    .font(.footnote.weight(.semibold))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.accentColor.opacity(0.15))
                                                    .foregroundStyle(Color.accentColor)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        let itemsToShow = currentFilteredItems.filter { !$0.isFinishedMoreThanOneDayAgo }
                                        let itemsWithAds = itemsToShow.withAdsInserted(adCount: adMobManager.nativeAds.count)

                                        ForEach(itemsWithAds, id: \.index) { entry in
                                            if entry.type == .item, let item = entry.item {
                                                WorkInProgressRow(item: item)
                                                    .padding(.horizontal)
                                            }
                                            else if entry.type == .ad, let adIndex = entry.adIndex, adIndex < adMobManager.nativeAds.count {
                                                NativeAdView(nativeAd: adMobManager.nativeAds[adIndex])
                                                    .frame(height: 290)
                                                    .padding(.horizontal)
                                            }
                                        }
                                        .transaction { $0.animation = nil }
                                        .padding(.top, 5)
                                    }
                                }
                                .padding(.bottom, 20)
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
                    viewModel.fetchMetroStatus()
                    viewModel.fetchRequirements {
                        showMaintenanceMode = viewModel.maintenanceModeEnabled
                    }
                    alreadyRefreshed = true
                }
                
                if viewModel.strikeEnabled && showStrikeBanner && !closedStrike {
                    marqueeId = UUID()
                }
                
                if !hasNotCompletedSetup {
                    consentManager.requestConsentInfoUpdate()
                }
                
                if consentManager.isReady && !adsRequested {
                    if let adUnitID = Bundle.main.infoDictionary?["AdUnitID"] as? String {
                        adsRequested = true
                        adMobManager.loadNativeAds(adUnitID: adUnitID)
                    }
                }
            }
            .onChange(of: hasNotCompletedSetup) { _, completed in
                if !completed {
                    consentManager.requestConsentInfoUpdate()
                }
            }
            .onChange(of: consentManager.isReady) { _, ready in
                if ready && !adsRequested, let adUnitID = Bundle.main.infoDictionary?["AdUnitID"] as? String {
                    adsRequested = true
                    adMobManager.loadNativeAds(adUnitID: adUnitID)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openTrainFilter)) { notification in
                selectedFilter = .train
            }
            .refreshable {
                viewModel.fetchWorks()
                viewModel.fetchVariables()
                viewModel.fetchMetroStatus()
                viewModel.fetchRequirements {
                    showMaintenanceMode = viewModel.maintenanceModeEnabled
                }
            }
            .fullScreenCover(isPresented: $showMaintenanceMode) {
                MaintenanceView(maintenanceDeps: viewModel.maintenanceDeps, maintenanceDepsEn: viewModel.maintenanceDepsEn) {
                    showMaintenanceMode = false
                }
            }
            .fullScreenCover(isPresented: $showWrapped, onDismiss: {
                hasOpenedWrapped = true
                showWrappedOpenedInfo = true
            }) {
                WrappedView()
            }
            .alert("Riguarda il Wrapped", isPresented: $showWrappedOpenedInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("D'ora in poi, troverai il Wrapped sotto la sezione \"Account\" nelle impostazioni.")
            }
            .onChange(of: selectedFilter) { oldValue, newValue in
                if newValue == .suggested && feedbacksEnabled {
                    suggestedTrigger += 1 ///TRIGGERS THE HAPTICS
                    playRotateHaptics()
                }
            }
            .sheet(isPresented: $showInfoFavoriteLines) {
                DetailSetYourLineView(showInfoView: $showInfoFavoriteLines)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openLetueLinkInfo)) { _ in
                selectedFilter = .suggested
                showInfoFavoriteLines = true
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    func playRotateHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        let pulses: [(delay: TimeInterval, intensity: CGFloat)] = [
            (0.00, 0.2),
            (0.10, 0.5),
            (0.20, 0.8),
            (0.30, 1.0),
            (0.40, 0.7),
            (0.50, 0.4),
            (0.58, 0.15)
        ]

        for pulse in pulses {
            DispatchQueue.main.asyncAfter(deadline: .now() + pulse.delay) {
                generator.impactOccurred(intensity: pulse.intensity)
            }
        }
    }
}

struct MainHeaderView: View {
    @ObservedObject var viewModel: WorkViewModel
    @Binding var showMaintenanceMode: Bool

    var body: some View {
        HStack {
            Text("Lavori in corso")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            Button(action: refresh) {
                refreshIcon
            }
        }
        .padding(.horizontal)
        .padding(.top, 57)
        .padding(.bottom, 5)
    }

    @ViewBuilder
    private var refreshIcon: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.0)
                .tint(.red)
        } else {
            Image(systemName: "arrow.clockwise")
                .font(.title2)
                .fontWeight(.semibold)
        }
    }

    private func refresh() {
        viewModel.isLoading = true
        viewModel.fetchWorks()
        viewModel.fetchVariables()
        viewModel.fetchMetroStatus()
        viewModel.fetchRequirements {
            showMaintenanceMode = viewModel.maintenanceModeEnabled
        }
    }
}

private struct MarqueeTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct MarqueeText: View {
    let text: String
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isReady: Bool = false
    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(.system(size: 13))
                .fixedSize()
                .hidden()
                .background(
                    GeometryReader { tg in
                        Color.clear.preference(
                            key: MarqueeTextWidthKey.self,
                            value: tg.size.width
                        )
                    }
                )
            
            if isReady {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .frame(height: geo.size.height, alignment: .center)
                    .offset(x: offset)
            }
        }
        .frame(height: 18)
        .clipped()
        .onPreferenceChange(MarqueeTextWidthKey.self) { tw in
            textWidth = tw
            if containerWidth > 0 && tw > 0 && !isReady {
                isReady = true
                startMarquee()
            }
        }
        .background(
            GeometryReader { cg in
                Color.clear
                    .onAppear {
                        containerWidth = cg.size.width
                        if textWidth > 0 && containerWidth > 0 && !isReady {
                            isReady = true
                            startMarquee()
                        }
                    }
                    .onChange(of: cg.size.width) { _, cw in
                        containerWidth = cw
                        if textWidth > 0 && cw > 0 && !isReady {
                            isReady = true
                            startMarquee()
                        }
                    }
            }
        )
        .onDisappear {
            isAnimating = false
        }
        .onAppear {
            if isReady && !isAnimating {
                startMarquee()
            }
        }
    }

    private func startMarquee() {
        guard !isAnimating, textWidth > 0, containerWidth > 0 else { return }
        isAnimating = true
        animateMarquee()
    }

    private func animateMarquee() {
        guard isAnimating else { return }
        offset = containerWidth
        let totalWidth = containerWidth + textWidth
        let duration = Double(totalWidth) / 55.0
        
        withAnimation(.linear(duration: duration)) {
            offset = -textWidth
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard isAnimating else { return }
            animateMarquee()
        }
    }
}
