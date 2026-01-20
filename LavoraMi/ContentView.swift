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

struct ContentView: View {
    @StateObject private var viewModel = WorkViewModel()
    
    var body: some View {
        TabView{
            MainView(viewModel: viewModel)
                .tabItem{
                    Label("Home", systemImage: "house")
                }
            LinesView(viewModel: viewModel)
                .tabItem{
                    Label("Linee", systemImage: "arrow.branch")
                }
            SettingsView(viewModel: viewModel)
                .tabItem{Label("Impostazioni", systemImage: "gear")}
        }
        .tint(.red)
    }
}

struct MainView: View{
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    @State private var closedStrike: Bool = false
    @State private var selectedFilter: FilterBy = .all
    @State private var searchInput: String = ""
    @State private var alreadyRefreshed: Bool = false
    @ObservedObject var viewModel: WorkViewModel
    @FocusState private var isSearchFocused: Bool
    
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
                        viewModel.fetchWorks()
                        viewModel.fetchVariables()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 57)
                .padding(.bottom, 5)
            }
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Cerca linea (es. S5, RE8)...", text: $searchInput)
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
            if(viewModel.strikeEnabled && !closedStrike){
                VStack(spacing: 8) {
                    Label("AVVISO SCIOPERO", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 25, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(Color("TextColor"))
                   
                    Text("Sciopero proclamato per il \(viewModel.dateStrike).")
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(Color("TextColor"))
                   
                    Text("Le fasce garantite (06:00 - 09:00, 18:00 - 21:00) \(viewModel.guaranteed)")
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(Color("TextColor"))
                        .padding(.horizontal, 10)
                        .multilineTextAlignment(.center)
                    HStack {
                        Text("Aderenti: \(viewModel.companiesStrikes)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color("TextColor"))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                    }
                    Button(action:{
                        closedStrike = true
                    }){
                        Label("Chiudi", systemImage: "xmark")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FilterBy.allCases) { filter in
                        Button(action: {
                            withAnimation(.snappy){
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedFilter = filter
                            }
                        }){
                            Text(filter.rawValue)
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
                .padding(.horizontal)
            }
            .scrollDismissesKeyboard(.immediately)
            .animation(.default, value: filteredItems)
            .padding(.bottom, 8)
            VStack(alignment: .leading, spacing: 16){
                ScrollView{
                    LazyVStack(spacing: 12){
                        if viewModel.isLoading {
                            ProgressView("Caricamento in corso...")
                                .padding()
                                .containerRelativeFrame(.vertical)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            
                        } else if let error = viewModel.errorMessage {
                            VStack (spacing: 10){
                                Image(systemName: "wifi.slash")
                                    .font(.largeTitle)
                                Text("Impossibile caricare i dati dal server.")
                                    .font(.title2)
                                Text("Controlla la tua connessione e riprova.").font(.title3).foregroundColor(.gray)
                                Button(action: {
                                    viewModel.fetchWorks()
                                })
                                {
                                    Label("Riprova", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.bordered)
                                Text("Codice Errore: \(error)")
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .containerRelativeFrame(.vertical)
                            .padding()
                            .offset(y: -50)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    if(filteredItems.isEmpty){
                                        Text("Nessuna corrispondenza trovata.")
                                    }
                                    else{
                                        ForEach(filteredItems) { item in
                                            if(item.progress != 1){
                                                WorkInProgressRow(item: item)
                                                    .padding(.horizontal)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .refreshable {
                                viewModel.fetchWorks()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .onAppear(){
                if(!alreadyRefreshed){
                    viewModel.fetchWorks()
                    viewModel.fetchVariables()
                    alreadyRefreshed = true
                }
                NotificationManager.shared.requestPermission()
            }
        }
    }
}

struct WorkInProgressRow: View {
    let item: WorkItem
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(item.details)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label(item.title, systemImage: item.titleIcon)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("TextColor"))
                
                Label(item.roads, systemImage: "mappin")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("TextColor"))

                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
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
                
                VStack(spacing: 6) {
                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                        .tint(item.progress == 1.0 ? .green : .red)

                    HStack {
                        let italianLoc = Date.FormatStyle(date: .abbreviated, time: .omitted)
                                .locale(Locale(identifier: "it_IT"))
                        
                        Text(item.startDate.formatted(italianLoc))
                            .font(.caption)
                            .foregroundStyle(Color("TextColor"))
                        Spacer()
                        Text(item.endDate.formatted(italianLoc))
                            .font(.caption)
                            .foregroundStyle(Color("TextColor"))
                    }
                    Spacer()
                    Text(item.company)
                        .foregroundStyle(Color("TextColor"))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct SettingsView: View{
    @State private var expandedTrenord = false
    @State private var expandedATM = false
    @State private var expandedATMLines = false
    @State private var presentedAlertReset = false
    @State private var showBuildNumber = false
    @StateObject var viewModel: WorkViewModel
    
    //APP DATAS
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    
    let metroLines = ["M1", "M2", "M3", "M4", "M5"]
    
    var body: some View {
        NavigationStack {
            List {
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
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                
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
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
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
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
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
                    DisclosureGroup(isExpanded: $expandedATM){
                        DisclosureGroup(isExpanded: $expandedATMLines) {
                            ForEach(metroLines, id: \.self) { line in
                                LineFavouritesRow(line: line, favorites: $linesFavorites, viewModel: viewModel)
                            }
                        } label: {
                            Label("Linee Metro", systemImage: "tram.fill.tunnel")
                        }
                        HStack{
                            Label("Linee Tram", systemImage: "tram.fill")
                            Spacer()
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
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
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
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
                    HStack{
                        Label("Linee Movibus", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
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
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
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
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            if linesFavorites.contains("z4") {
                                linesFavorites.removeAll { $0 == "z4" }
                                linesFavorites.removeAll { $0 == "z2" }
                                linesFavorites.removeAll { $0 == "k" }
                                linesFavorites.removeAll { $0 == "p" }
                            } else {
                                linesFavorites.append("z4")
                                linesFavorites.append("z2")
                                linesFavorites.append("k")
                                linesFavorites.append("p")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                        }) {
                            Image(systemName: linesFavorites.contains("z4") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z4") ? .orange : .gray)
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
                            Text(filter.rawValue).tag(filter)
                                .foregroundStyle(Color("TextColor"))
                        }
                    } label: {
                        Label("Filtro Predefinito", systemImage: "line.3.horizontal.decrease.circle.fill")
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Informazioni"){
                    NavigationLink(destination: InfoView()){
                        Label("Fonti & Sviluppo", systemImage: "person.crop.circle.badge.questionmark")
                    }
                    HStack{
                        Button(action: {
                            showBuildNumber = !showBuildNumber
                        }){
                            Label {
                                    Text("Versione")
                                        .foregroundColor(Color("TextColor"))
                                } icon: {
                                    Image(systemName: "info.circle.fill")
                                }
                        }
                        Spacer()
                        if(showBuildNumber){Text("\(Bundle.main.shortVersion) (\(Bundle.main.buildVersion))")}
                        else{Text("\(Bundle.main.shortVersion)")}
                        
                    }
                }
                Section(footer: Text("Le impostazioni vengono salvate automaticamente.")) {
                    Button(role: .destructive) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
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
                }
            } message: {
                Text("Sei sicuro di voler ripristinare le impostazioni?")
            }
        }
    }
}

struct NotificationsView: View {
    @AppStorage("workScheduledNotifications") var workScheduledNotifications: Bool = true
    @AppStorage("workInProgressNotifications") var workInProgressNotifications: Bool = true
    @AppStorage("strikeNotifications") var strikeNotifications: Bool = true
    @AppStorage("enableNotifications") var enableNotifications: Bool = true
    @AppStorage("linesFavorites") var linesFavorites: [String] = []
    
    @ObservedObject var viewModel: WorkViewModel
    
    var body: some View {
        NavigationStack{
            Spacer()
            List {
                Section(footer: Text("Imposta tutte le notifiche su uno stato.")){
                    Toggle(isOn: $enableNotifications){
                        Label("Notifiche", systemImage: "bell.fill")
                    }
                    .onChange(of: enableNotifications){
                        workScheduledNotifications = enableNotifications
                        workInProgressNotifications = enableNotifications
                        strikeNotifications = enableNotifications
                        print("-- INIZIO SYNCH DELLE NOTIFICHE --")
                        
                        //SYNC NOTIFICATIONS
                        viewModel.fetchVariables() //SYNC STRIKES NOTIFICATIONS
                        NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                    }
                }
                Section("Notifiche Lavori") {
                    Toggle(isOn: $workScheduledNotifications){
                        Label("Notifiche Inizio Lavori", systemImage: "bell.badge.fill")
                    }
                    .onChange(of: workScheduledNotifications){
                        NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                        print("-- INIZIO SYNCH NOTIFICHE IN PROGRESS --")
                    }
                    .disabled(!enableNotifications)
                    Toggle(isOn: $workInProgressNotifications){
                        Label("Notifiche Fine Lavori", systemImage: "bell.badge.fill")
                    }
                    .onChange(of: workInProgressNotifications){
                        NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                        print("-- INIZIO SYNCH NOTIFICHE IN PROGRESS --")
                    }
                    .disabled(!enableNotifications)
                }
                Section("Notifiche Scioperi"){
                    Toggle(isOn: $strikeNotifications){
                        Label("Notifiche Scioperi", systemImage: "bell.badge.waveform.fill")
                    }
                    .onChange(of: strikeNotifications){
                        viewModel.fetchVariables()
                        print("-- INIZIO SYNCH NOTIFICHE STRIKE --")
                    }
                    .disabled(!enableNotifications)
                }
            }
            .navigationTitle("Notifiche")
        }
    }
}

struct InfoView: View {
    var body: some View {
        Section{
            HStack{
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                Text("LavoraMi")
                    .font(.system(size: 35))
                    .bold()
            }
            Text(Bundle.main.shortVersion)
            Divider()
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

                    Tutti i dati visualizzati in questa applicazione (orari, stati del servizio, avvisi) sono raccolti da fonti pubbliche ed elaborati automaticamente al solo scopo di migliorarne la comprensione e la leggibilità per l'utente finale.
                    
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
                        
                        Text("Sviluppatore Android:")
                            .font(.system(size: 20))
                            .padding(.top, 20)
                        Text("Tommaso Ruggeri")
                            .bold()
                            .font(.system(size: 25))
                    }
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Contatti")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    
                    Link(destination: URL(string: "mailto:help.playepik@gmail.com")!) {
                        Label("Segnala un bug", systemImage: "ladybug.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.bottom, 20)
                    Spacer()
                }
            }
        }
    }
}

struct LineFavouritesRow: View {
    let line: String
    @Binding var favorites: [String]
    @StateObject var viewModel: WorkViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Text(line)
                .foregroundStyle(.white)
                .font(.system(size: 12, weight: .bold))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(getColor(for: line))
                )
            
            Text("Metro \(line)")
            
            Spacer()
            
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                if favorites.contains(line) {
                    favorites.removeAll { $0 == line }
                } else {
                    favorites.append(line)
                }
                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: favorites)
            }) {
                Image(systemName: favorites.contains(line) ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundColor(favorites.contains(line) ? .orange : .gray)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

struct LineRow: View {
    let line: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String
    let stations: [MetroStation]
    @ObservedObject var viewModel: WorkViewModel
    
    var body: some View {
        if typeOfTransport != "Tram" && typeOfTransport != "Movibus" && typeOfTransport != "STAV" && typeOfTransport != "Autoguidovie"{
            NavigationLink(
                destination: LineDetailView(
                    lineName: line,
                    typeOfTransport: typeOfTransport,
                    branches: branches,
                    waitMinutes: waitMinutes,
                    workScheduled: getWorkScheduled(line: line, viewModel: viewModel),
                    workNow: getWorkNow(line: line, viewModel: viewModel),
                    viewModel: viewModel,
                    stations: stations
                )
            ) {
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

                    if(line == "MXP"){Text("\(typeOfTransport)")}
                    else{Text("\(typeOfTransport) \(line)")}
                }
                .padding(.vertical, 4)
            }
        } else{
            NavigationLink(
                destination: LineSmallDetailedView(
                    lineName: line,
                    typeOfTransport: typeOfTransport,
                    branches: branches,
                    waitMinutes: waitMinutes,
                    workScheduled: getWorkScheduled(line: line, viewModel: viewModel),
                    workNow: getWorkNow(line: line, viewModel: viewModel),
                    viewModel: viewModel
                )
            ) {
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

                    Text("\(typeOfTransport) \(line)")
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct LinesView: View {
    @ObservedObject var viewModel: WorkViewModel

    @State private var searchInput: String = ""
    @State private var selectedURL: URL?
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
    var filteredUrbano: [LineInfo] { filtered(urbanoPavia) }
    var filteredCrossBorders: [LineInfo] { filtered(crossBorderLines) }
    var filteredMalpensaExpress: [LineInfo] { filtered(malpensaExpress) }
    
    var metros: [LineInfo] {
        [
            LineInfo(name: "M1", branches: "Sesto F.S. - Rho Fiera / Bisceglie", type: "Metro", waitMinutes: "Sesto FS: 3 min | Rho/Bisceglie: 7-8 min.", stations: StationsDB.stationsM1),
            LineInfo(name: "M2", branches: "Gessate / Cologno - Assago / Abbiategrasso", type: "Metro", waitMinutes: "Gessate / Cologno: 12-15 min | Assago / Abbiategrasso: 9-10 min", stations: StationsDB.stationsM2),
            LineInfo(name: "M3", branches: "Comasina - San Donato", type: "Metro", waitMinutes: "4-5 min.", stations: StationsDB.stationsM3),
            LineInfo(name: "M4", branches: "Linate Aereoporto - San Cristoforo", type: "Metro", waitMinutes: "2-3 min.",stations: StationsDB.stationsM4),
            LineInfo(name: "M5", branches: "Bignami - San Siro Stadio", type: "Metro", waitMinutes: "4 min.", stations: StationsDB.stationsM5)
        ]
    }
    
    var suburban: [LineInfo] {
        [
            LineInfo(name: "S1", branches: "Saronno - Lodi", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS1),
            LineInfo(name: "S2", branches: "Mariano Comense - Milano Rogoredo", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS2),
            LineInfo(name: "S3", branches: "Saronno - Milano Cadorna", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS3),
            LineInfo(name: "S4", branches: "Camnago - Milano Cadorna", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS4),
            LineInfo(name: "S5", branches: "Varese - Treviglio", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS5),
            LineInfo(name: "S6", branches: "Novara - Pioltello Limito/Treviglio", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS6),
            LineInfo(name: "S7", branches: "Lecco - Milano Pta Garibaldi", type: "Suburbano", waitMinutes: "1 ora - 30 min.", stations: StationsDB.stationsS7),
            LineInfo(name: "S8", branches: "Lecco - Carnate - Milano Pta Garibaldi", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS8),
            LineInfo(name: "S9", branches: "Saronno - Albairate Vermezzo", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS9),
            LineInfo(name: "S11", branches: "Rho - Como S. Giovanni", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS11),
            LineInfo(name: "S12", branches: "Melegnano - Cormano", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS12),
            LineInfo(name: "S13", branches: "Pavia - Milano Bovisa", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS13),
            LineInfo(name: "S19", branches: "Albairate Vermezzo - Milano Rogoredo", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS19),
            LineInfo(name: "S31", branches: "Brescia - Iseo", type: "Suburbano", waitMinutes: "1 ora.", stations: StationsDB.stationsS31)
        ]
    }
    
    var crossBorderLines: [LineInfo] {
        [
            LineInfo(name: "S10", branches: "Biasca - Como S. Giovanni", type: "Transfrontaliera", waitMinutes: "1 ora - 45 min.", stations: StationsDB.tiloS10),
            LineInfo(name: "S30", branches: "Cadenazzo - Gallarate", type: "Transfrontaliera", waitMinutes: "2 ore.", stations: StationsDB.tiloS30),
            LineInfo(name: "S40", branches: "Como S. Giovanni - Varese", type: "Transfrontaliera", waitMinutes: "1 ora.", stations: StationsDB.tiloS40),
            LineInfo(name: "S50", branches: "Biasca - Milano Malpensa", type: "Transfrontaliera", waitMinutes: "1 ora", stations: StationsDB.tiloS50),
            LineInfo(name: "RE80", branches: "Locarno - Milano Centrale", type: "Transfrontaliera", waitMinutes: "30 min - 1 ora.", stations: StationsDB.tiloRE80)
        ]
    }
    
    var malpensaExpress: [LineInfo] {
        [
            LineInfo(name: "MXP", branches: "Milano Cadorna - Malpensa Aereoporto", type: "Malpensa Express 1", waitMinutes: "30 min.", stations: StationsDB.mxp1),
            LineInfo(name: "MXP", branches: "Milano Centrale - Malpensa Aereoporto", type: "Malpensa Express 2", waitMinutes: "30 min.", stations: StationsDB.mxp2)
        ]
    }
    
    var trams: [LineInfo] {
        [
            LineInfo(name: "1", branches: "Roserio - Centrale FS", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "2", branches: "P.Le Negrelli - P.Za Bausan", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "3", branches: "Duomo M1 M3 - Gratosoglio", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "4", branches: "Cairoli M1 - Niguarda (Parco Nord)", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "5", branches: "Niguarda (Ospedale) - Ortica", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "7", branches: "P.Le Lagosta - Q.Re Adriano", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "9", branches: "Centrale FS M2 M3 - P.Ta Genova M2", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "10", branches: "P.Za 24 Maggio - V.Le Lunigiana", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "12", branches: "P.Za Ovidio - Roserio (Ospedale Sacco)", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "14", branches: "Lorenteggio - Cimitero Maggiore", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "15", branches: "Duomo M1 M3 - Rozzano (Via G. Rossa)", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "16", branches: "San Siro Stadio M5 - Via Monte Velino", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "19", branches: "P.Za Castelli - Lambrate FS M2", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "24", branches: "Duomo M1 M3 - Vigentino", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "27", branches: "V.Le Ungheria - Duomo M1 M3", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "31", branches: "Bicocca M5 - Cinisello (1° Maggio)", type: "Tram", waitMinutes: "5-20 min.", stations: []),
            LineInfo(name: "33", branches: "P.Le Lagosta - Rimembranze di Lambrate", type: "Tram", waitMinutes: "5-20 min.", stations: []),
        ]
    }
    
    var bus : [LineInfo] {
        [
            LineInfo(name: "z601", branches: "Legnano - Rho - Milano Molino Dorino", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z602", branches: "Legnano - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z603", branches: "Vittore Olona / Nerviano - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z6C3", branches: "Vittore Olona - Cerro Maggiore - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z606", branches: "Cerro Maggiore - Rho - Milano Molino Dorino", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z611", branches: "Legnano - Canegrate - Parabiago", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z612", branches: "Legnano - Cerro Maggiore - Arese", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z616", branches: "Pregnana Milanese - Rho", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z617", branches: "Origgio / Lainate - Milano Molino Dorino ", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z618", branches: "Vanzago - Pogliano M. - Rho", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z619", branches: "Pogliano M. - Plesso IST Maggiolini", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z620", branches: "Magenta - Vittuone - Milano Molino Dorino", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z621", branches: "Cuggiono - Ossona - Milano Molino Dorino", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z622", branches: "Cuggiono - Ossona - Cornaredo", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z625", branches: "Busto Arsizio - Busto Garolfo", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z627", branches: "Castano Primo - Legnano", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z636", branches: "Nosate - Legnano", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z641", branches: "Castano Primo - Magenta", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z642", branches: "Magenta - Legnano", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z643", branches: "Vittuone - Parabiago", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z644", branches: "Arconate - Parabiago", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z646", branches: "Magenta - Castano Primo", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z647", branches: "Cornaredo - Castano Primo", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z648", branches: "Arconate - Milano Molino Dorino", type: "Movibus", waitMinutes: "", stations: []),
            LineInfo(name: "z649", branches: "Magenta - Arluno - Milano Molino Dorino", type: "Movibus", waitMinutes: "", stations: [])
        ]
    }
    
    var stav: [LineInfo] {
        [
            LineInfo(name: "z551", branches: "Abbiategrasso Vittorio Veneto - Milano Bisceglie", type: "STAV", waitMinutes: "", stations: []),
            LineInfo(name: "z552", branches: "Abbiategrasso Vittorio Veneto - S. Stefano Ticino", type: "STAV", waitMinutes: "", stations: []),
            LineInfo(name: "z553", branches: "Abbiategrasso - Rosate - Milano Romolo", type: "STAV", waitMinutes: "", stations: []),
            LineInfo(name: "z554", branches: "Albairate - Albairate Vermezzo FS - Bubbiano", type: "STAV", waitMinutes: "", stations: []),
            LineInfo(name: "z555", branches: "Abbiategrasso Vittorio Veneto - Binasco / Rosate", type: "STAV", waitMinutes: "", stations: []),
            LineInfo(name: "z556", branches: "Abbiategrasso FS - Motta Visconti", type: "STAV", waitMinutes: "", stations: []),
            LineInfo(name: "z557", branches: "Gaggiano De Gasperi - Gaggiano FS - San Vito", type: "STAV", waitMinutes: "", stations: []),
            LineInfo(name: "z559", branches: "Abbiategrasso Stazione FS - Magenta FS", type: "STAV", waitMinutes: "", stations: []),
            LineInfo(name: "z560", branches: "Abbiategrasso FS - Corsico - Milano Bisceglie", type: "STAV", waitMinutes: "", stations: []),
        ]
    }
    
    var autoguidovie: [LineInfo] {
        [
            LineInfo(name: "z401", branches: "Melzo FS - Gorgonzola M2", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z402", branches: "Cernusco S/N - San Felice - Peschiera B.", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z403", branches: "Melzo - Gessate M2 - Gorgonzola M2", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z404", branches: "Melzo - Inzago - Gessate M2", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z405", branches: "Gessate M2 - Cassano d'Adda - Treviglio", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z406", branches: "Gessate M2 - Inzago - Cassano d'Adda", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z407", branches: "Gessate M2 - Bellinzago L. - Cassano d'Adda", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z409", branches: "Rodano - Settala - Liscate - Truccazzano", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z410", branches: "Liscate - Rodano - Pantigliate", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z411", branches: "Melzo FS - Liscate - Pantigliate - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z412", branches: "Zelo B.P. - Comazzo - Merlino - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z413", branches: "Paullo - Mombretto - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z415", branches: "S.Donato M3 - Paullo - Zelo B.P.", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z418", branches: "San Giuliano M. - Melegnano - Riozzo", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z419", branches: "Paullo - Melzo - Gorgonzola", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z420", branches: "S.Zenone al L. - Melegnano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z431", branches: "Melegnano - Vizzolo P. - Carpiano - Locate T.", type: "Autoguidovie", waitMinutes: "", stations: []),

            // MARK: - Area Monza e Brianza
            LineInfo(name: "z219", branches: "Paderno D. - Nova M. - Cinisello B. - Monza", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z221", branches: "Sesto S.G. - Monza - Carate B. - Mariano C.", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z222", branches: "Monza FS - S.Fruttuoso - Sesto S.G.", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z225", branches: "Sesto S.G. - Nova M. - Paderno D.", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z227", branches: "Monza - Lissone - Muggiò - Cinisello - Sesto S.G.", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z228", branches: "Seregno FS - Lissone - Monza FS", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z229", branches: "Paderno Dugnano - Cinisello B.", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z231", branches: "Desio - Seregno FS - Carate B.", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z232", branches: "Desio - Seregno - Carate B. - Besana B.", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z233", branches: "Triuggio - Albiate - Seregno FS", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z234", branches: "Vedano al L. - Biassono - Macherio - Lissone - Muggiò", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z250", branches: "Desio FS - Cesano M. - Limbiate", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "z251", branches: "Desio FS - Bovisio M. - Varedo - Limbiate - Senago", type: "Autoguidovie", waitMinutes: "", stations: []),

            // MARK: - Area Crema
            LineInfo(name: "k501", branches: "Crema - Pandino - Milano S.Donato", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k502", branches: "Crema - Agnadello - Rivolta - Milano S.Donato", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k503", branches: "Crema - Rivolta d'Adda - Milano", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k505", branches: "Crema - Treviglio - Milano", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k506", branches: "Crema - Pandino - Milano Bisceglie", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k507", branches: "Crema - Mediglia - Milano", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k510", branches: "Rivolta d'Adda - Pioltello - Linate", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k511", branches: "Vailate - Melzo - Linate - Milano S.Donato", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k512", branches: "Crema - Spino d'Adda - Milano S.Donato", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k520", branches: "Crema - Magnacavallo", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k521", branches: "Crema - Milano S.Donato (Diretta)", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k522", branches: "Crema - Montodine - S.Zenone - Milano S.Donato", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k523", branches: "Crema - Cremosano - Trescore - Milano S.Donato", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k524", branches: "Crema - Chieve - Milano S.Donato", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k525", branches: "Crema - Palazzo P. - Vaiano - Milano S.Donato", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k601", branches: "Crema - Soncino", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k208", branches: "Cremona - S.Daniele - Casalmaggiore", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "k214", branches: "Cremona - Pieve d'Olmi - Viadana", type: "Autoguidovie", waitMinutes: "", stations: []),
        ]
    }
    
    var urbanoPavia: [LineInfo] {
        [
            // MARK: - Area Pavia (Urbano ed Extraurbano)
            LineInfo(name: "P1", branches: "Montemontanino - S.Genesio - C.na Pelizza (Urbano PV)", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P2", branches: "Vallisneri - Pavia FS - Cravino (Urbano PV)", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P3", branches: "Maugeri/Mondino - Stazione FS - Montebolone (Urbano PV)", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P4", branches: "Vallone - Stazione FS - Sora (Urbano PV)", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P6", branches: "Cascina Pelizza - Pavia FS - Travaco (Urbano PV)", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P7", branches: "Maugeri/Mondino - Pavia FS - Cura Carpignano (Urbano PV)", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P172", branches: "Pavia - Binasco - Milano Romolo M2", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P175", branches: "Pavia - Siziano - Milano Famagosta", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P94", branches: "Pavia - Vidigulfo - Milano Famagosta", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P96", branches: "Pavia - Gropello - Milano Famagosta", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P165", branches: "Pavia - Inverno - S.Angelo Lodigiano", type: "Autoguidovie", waitMinutes: "", stations: []),
            LineInfo(name: "P182", branches: "Pavia - Garlasco - Mortara", type: "Autoguidovie", waitMinutes: "", stations: []),
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
            .padding()
            List{
                Section(){
                    if(!filteredMetros.isEmpty){
                        ForEach(filteredMetros, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, stations: line.stations, viewModel: viewModel)
                        }
                    }
                    else{
                        Text("Nessuna corrispondenza trovata.")
                    }
                }
                header:{
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
                            selectedURL = URL(string: "https://giromilano.atm.it/assets/images/schema_rete_metro.jpg")
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                Section(){
                    if(!filteredSuburban.isEmpty){
                        ForEach(filteredSuburban, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, stations: line.stations, viewModel: viewModel)
                        }
                    }
                    else{
                        Text("Nessuna corrispondenza trovata.")
                    }
                }
                header:{
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
                            selectedURL = URL(string: "https://www.trenord.it/linee-e-orari/circolazione/le-nostre-linee/")
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                Section(){
                    if(!filteredCrossBorders.isEmpty){
                        ForEach(filteredCrossBorders, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, stations: line.stations, viewModel: viewModel)
                        }
                    }
                    else{
                        Text("Nessuna corrispondenza trovata.")
                    }
                }
                header:{
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
                            selectedURL = URL(string: "https://www.tilo.ch")
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                Section(){
                    if(!filteredMalpensaExpress.isEmpty){
                        ForEach(filteredMalpensaExpress, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, stations: line.stations, viewModel: viewModel)
                        }
                    }
                    else{
                        Text("Nessuna corrispondenza trovata.")
                    }
                }
                header:{
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
                            selectedURL = URL(string: "https://www.malpensaexpress.it")
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                Section(){
                    if(!filteredTrams.isEmpty){
                        ForEach(filteredTrams, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, stations: line.stations, viewModel: viewModel)
                        }
                    }
                    else{
                        Text("Nessuna corrispondenza trovata.")
                    }
                }
                header: {
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
                            selectedURL = URL(string: "https://www.atm.it/it/AltriServizi/Trasporto/Documents/Carta%20ATM_WEB_2025.11.pdf")
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                Section(){
                    if(!filteredMovibus.isEmpty){
                        ForEach(filteredMovibus, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, stations: bus.stations, viewModel: viewModel)
                        }
                    }
                    else{
                        Text("Nessuna corrispondenza trovata.")
                    }
                }
                header: {
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
                            selectedURL = URL(string: "https://movibus.it/news/")
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                Section(){
                    if(!filteredSTAV.isEmpty){
                        ForEach(filteredSTAV, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, stations: bus.stations, viewModel: viewModel)
                        }
                    }
                    else{
                        Text("Nessuna corrispondenza trovata.")
                    }
                }
                header: {
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
                            selectedURL = URL(string: "https://stavautolinee.it/reti-servite/")
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                Section(){
                    if(!filteredAutoguidovie.isEmpty){
                        ForEach(filteredAutoguidovie, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, stations: bus.stations, viewModel: viewModel)
                        }
                    }
                    else{
                        Text("Nessuna corrispondenza trovata.")
                    }
                }
                header: {
                    HStack{
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
                            selectedURL = URL(string: "https://autoguidovie.it/it/avvisi")!
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                Section(){
                    if(!filteredUrbano.isEmpty){
                        ForEach(filteredUrbano, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, stations: bus.stations, viewModel: viewModel)
                        }
                    }
                    else{
                        Text("Nessuna corrispondenza trovata.")
                    }
                }
                header: {
                    HStack{
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Linee di Bus")
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.primary)
                                .textCase(nil)
                            
                            Text("Urbano di Pavia")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                        .padding(.bottom, 4)
                        Spacer()
                        Button(action: {
                            selectedURL = URL(string: "https://pavia.autoguidovie.it/it/l/news/index")!
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
            }
            .navigationTitle("Linee")
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

func getInterchanges(line: String) -> [InterchageInfo]{
    return StationsDB.interchanges.filter{$0.lines.contains(line)}
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
    
    @AppStorage("selectedWidgetLine") private var selectedWidgetLine: String = ""
    
    private enum LineDetailTab { case map, works, interchanges }
    @State private var selectedTab: LineDetailTab = .map
    @State private var openPopUpWidget: Bool = false
    
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Text(lineName)
                            .foregroundStyle(.white)
                            .font(.system(size: 40, weight: .bold))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill((typeOfTransport == "Tram") ? .orange : getColor(for: lineName))
                            )
                        
                        if(lineName == "MXP"){
                            Text("\(typeOfTransport)")
                                .font(.system(size: 30))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                        else{
                            Text("\(typeOfTransport) \(lineName)")
                                .font(.system(size: 30))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
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
                                openPopUpWidget = true
                            }
                        }){
                            Image(systemName: (selectedWidgetLine == lineName) ? "widget.small" : "widget.small.badge.plus")
                                .foregroundStyle((selectedWidgetLine == lineName) ? .yellow : .gray)
                                .scaleEffect(1.5)
                        }
                        .alert("Linea attivata", isPresented: $openPopUpWidget) {
                            Button("OK", role: .cancel){}
                        } message: {
                            Text("Linea impostata per essere vista sul Widget dell'app!")
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
                            Text("LA LINEA E' ATTIVA SOLO NEI GIORNI SETTIMANALI.")
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
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .padding(.top, 20)
                .background(Color(uiColor: .systemBackground))
                HStack(spacing: 8) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
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
                                        Capsule().fill((lineName == "S12") ? .white : getColor(for: lineName))
                                    } else {
                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                    }
                                }
                            )
                            .foregroundStyle(selectedTab == .map ? ((lineName == "S19" || lineName == "S1" || lineName == "M1" || lineName == "M4") ? .white : Color(.systemBackground)) : .primary)
                    }

                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
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
                                        Capsule().fill((lineName == "S12") ? .white : getColor(for: lineName))
                                    } else {
                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                    }
                                }
                            )
                            .foregroundStyle(selectedTab == .works ? ((lineName == "S19" || lineName == "S1" || lineName == "M1" || lineName == "M4") ? .white : Color(.systemBackground)) : .primary)
                    }
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
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
                                        Capsule().fill((lineName == "S12") ? .white : getColor(for: lineName))
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
                    Map(initialPosition: .region(MKCoordinateRegion(
                            center: centerCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                        )),
                        bounds: lombardyBounds
                        ){
                            let lineColor: Color = getColor(for: lineName)
                            switch(lineName){
                                case "M1":
                                    MapPolyline(coordinates: stations.filter { $0.branch == "Main" }.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                    let pagano = stations.first(where: { $0.name == "Pagano" })!
                                    let rhoBranch = [pagano] + stations.filter { $0.branch == "Rho" }
                                    MapPolyline(coordinates: rhoBranch.map(\.coordinate))
                                        .stroke(lineColor, lineWidth: 5)
                                    
                                    let bisceglieBranch = [pagano] + stations.filter { $0.branch == "Bisceglie" }
                                    MapPolyline(coordinates: bisceglieBranch.map(\.coordinate))
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
                        }
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
                                        let item = WorkItem(title: work.title, titleIcon: work.titleIcon, typeOfTransport: work.typeOfTransport, roads: work.roads, lines: work.lines, startDate: work.startDate, endDate: work.endDate, details: work.details, company: work.company)
                                        WorkInProgressRow(item: item)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical, 8)
                            } else {
                                Text("Nessun lavoro attuale o programmato su questa linea.")
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
                }
                
            }
            .navigationTitle("Dettagli Linea")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LineSmallDetailedView: View {
    @AppStorage("selectedWidgetLine") private var selectedWidgetLine: String = ""
    @State private var openPopUpWidget: Bool = false
    
    let lineName: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String
    
    let workScheduled: Int
    let workNow: Int
    let viewModel: WorkViewModel
    
    let interchanges: [InterchangeStation] = [
        .init(key: "Molino Dorino", displayName: "Molino Dorino MM", lines: ["M1"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Cadorna FN", displayName: "Milano Cadorna FN", lines: ["M1", "M2", "MXP", "R16", "R17", "R22", "R27", "RE1", "RE7", "S3", "S4"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Parabiago", displayName: "Parabiago", lines: ["z644", "z643"], typeOfInterchange: "bus.fill"),
        .init(key: "Rho", displayName: "Rho FS", lines: ["S5", "S6", "S11", "z616", "z618"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Busto Garolfo", displayName: "Busto Garolfo", lines: ["z625", "z627", "z644", "z647", "z648", "z649"], typeOfInterchange: "bus.fill"),
        .init(key: "Legnano", displayName: "Legnano", lines: ["z602", "z612", "z601", "z611", "z642", "z627"], typeOfInterchange: "bus.fill"),
        .init(key: "Bisceglie", displayName: "Bisceglie MM", lines: ["M1", "z560", "k506"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Romolo", displayName: "Romolo FS", lines: ["M2", "S9", "S19", "R31"], typeOfInterchange: "train.side.front.car"),
        .init(key: "S. Stefano Ticino", displayName: "Santo Stefano Ticino - Corbetta", lines: ["S6"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Magenta", displayName: "Magenta FS", lines: ["S6", "RV"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Abbiategrasso Vittorio Veneto", displayName: "Abbiategrasso V. Veneto", lines: ["z551", "z552", "z553", "z555", "z556", "z560"], typeOfInterchange: "bus.fill"),
        .init(key: "Gorgonzola", displayName: "Gorgonzola MM", lines: ["M2", "z401", "z403"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Cernusco", displayName: "Cernusco sul Naviglio MM", lines: ["M2"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Gessate", displayName: "Gessate MM", lines: ["M2", "z404", "z405", "z406", "z407"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Donato", displayName: "San Donato MM", lines: ["M3", "z411", "z412", "z413", "z415", "z420", "k501", "k502", "k511", "k512", "k521", "k522", "k523", "k524", "k525"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Sesto", displayName: "Sesto San Giovanni FS", lines: ["M1", "R13", "R14", "RE8", "S7", "S8", "S9", "S11", "z221", "z222", "z225", "z227"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Monza FS", displayName: "Monza FS", lines: ["R13", "R14", "RE8", "RE80", "S7", "S8", "S9", "S11", "z228"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Seregno FS", displayName: "Seregno FS", lines: ["RE80", "S9", "S11", "z228", "z231", "z233"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Desio FS", displayName: "Desio FS", lines: ["RE80", "S9", "S11", "z250", "z251"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Crema", displayName: "Crema FS", lines: ["R6", "k503", "k505", "k506", "k507", "k512", "k520", "k521", "k522", "k523", "k524", "k525", "k601"], typeOfInterchange: "bus.fill"),
        .init(key: "Linate", displayName: "Linate Aereoporto", lines: ["M4", "k510"], typeOfInterchange: "airplane.departure"),
        .init(key: "Pavia FS", displayName: "Pavia FS", lines: ["R34", "R35", "R36", "R37", "RE13", "S13", "Pavia 2", "Pavia 3", "Pavia 4", "Pavia 6", "Pavia 7"], typeOfInterchange: "train.side.front.car"),
        .init(key: "Famagosta", displayName: "Famagosta MM", lines: ["M2"], typeOfInterchange: "tram.fill.tunnel"),
        .init(key: "Cremona", displayName: "Cremona", lines: ["k208", "k214"], typeOfInterchange: "bus.fill")
    ]
    
    var activeInterchange: InterchangeStation? {
        interchanges.first { branches.contains($0.key) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                            if(selectedWidgetLine == lineName) {
                                selectedWidgetLine = ""
                                DataManager.shared.deleteSavedLine()
                            }
                            else {
                                DataManager.shared.setSavedLine(SavedLine(id: lineName, name: lineName, longName: typeOfTransport, iconTransport: getCurrentTransportIcon(for: typeOfTransport), worksNow: workNow, worksScheduled: workScheduled))
                                selectedWidgetLine = lineName
                                openPopUpWidget = true
                            }
                        }){
                            Image(systemName: (selectedWidgetLine == lineName) ? "widget.small" : "widget.small.badge.plus")
                                .foregroundStyle((selectedWidgetLine == lineName) ? .yellow : .gray)
                                .scaleEffect(1.5)
                        }
                        .alert("Linea attivata", isPresented: $openPopUpWidget) {
                            Button("OK", role: .cancel){}
                        } message: {
                            Text("Linea impostata per essere vista sul Widget dell'app!")
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
                    }
                    
                    if(!waitMinutes.isEmpty){
                        VStack(alignment: .leading, spacing: 5) {
                            Text("TEMPO DI ATTESA MEDIO:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .bold()
                            
                            Text(waitMinutes)
                                .font(.title3)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    else {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("FERMATA DI INTERSCAMBIO:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .bold()
                            if let station = activeInterchange {
                                Label(station.displayName, systemImage: station.typeOfInterchange)
                                    .font(.title3)
                                    .multilineTextAlignment(.leading)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(station.lines, id: \.self) { line in
                                            TransportBadge(line: line)
                                        }
                                    }
                                }
                            } else {
                                Text("Nessuna fermata di interscambio.")
                                    .foregroundColor(.secondary)
                            }
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
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .padding(.top, 20)
                .background(Color(uiColor: .systemBackground))
                HStack(spacing: 8) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                    }) {
                        Text("Lavori linea")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill((waitMinutes.isEmpty) ? (lineName.contains("P") ? getColor(for: lineName) : Color(red: 28/255, green: 28/255, blue: 1)) : .orange)
                            )
                            .foregroundStyle((waitMinutes.isEmpty) ? .white : Color(.systemBackground))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                VStack {
                    ScrollView {
                        let currentWorks = getCurrentWorks(line: lineName, viewModel: viewModel)
                        if currentWorks.count > 0 {
                            LazyVStack(spacing: 12) {
                                ForEach(currentWorks) { work in
                                    let item = WorkItem(title: work.title, titleIcon: work.titleIcon, typeOfTransport: work.typeOfTransport, roads: work.roads, lines: work.lines, startDate: work.startDate, endDate: work.endDate, details: work.details, company: work.company)
                                    WorkInProgressRow(item: item)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                        } else {
                            Text("Nessun lavoro attuale o programmato su questa linea.")
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
            .navigationTitle("Dettagli Linea")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InterchangeView: View {
    let item: InterchageInfo
    let currentLine: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(item.name, systemImage: "arrow.left.and.right")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Color("TextColor"))
            
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

//NOTE: FILTERS
enum FilterBy: String, CaseIterable, Identifiable {
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
    
    var id: String{self.rawValue}
}

struct LineInfo: Identifiable{
    let id = UUID()
    let name: String
    let branches: String
    let type: String
    let waitMinutes: String
    let stations: [MetroStation]
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

func getColor(for line: String) -> Color {
    switch line {
        //SUBURBAN LINES
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
        
        //TILO LINES
        case "S10": return Color(red: 228/255, green: 35/255, blue: 19/255)
        case "S30": return Color(red: 0, green: 166/255, blue: 81/255)
        case "S40": return Color(red: 117/255, green: 188/255, blue: 118/255)
        case "S50": return Color(red: 131/255, green: 76/255, blue: 22/255)
        
        //METRO LINES
        case "M1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "M2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "M3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "M4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "M5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        
        //BUS LINES
        case _ where line.contains("z") || line.contains("k"):
            return Color(red: 28/255, green: 28/255, blue: 1)
        case _ where line.contains("Filobus"):
            return Color(red: 101/255, green: 179/255, blue: 46/255)
        case _ where line.contains("P") && !(line.contains("MXP")):
            return Color(red: 69/255, green: 56/255, blue: 0)
        
        //OTHER LINES
        case "MXP": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP1": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP2": return Color(red: 140/255, green: 0, blue: 118/255)
        case "AV": return .red
        case "Aereoporto": return .black
        case _ where line.contains("R"):
                return Color.blue
        case let s where (1...33).contains(Int(s) ?? 0):
            return .orange
        
        default: return Color.gray
    }
}

func getCurrentTransportIcon(for lineLongName: String) -> String{
    switch(lineLongName){
        case "Suburbano":
            return "train.side.front.car"
        case "Transfrontaliera":
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
            let isAutoguidovie = transport.contains("autoguidovie") || linesLower.contains {
                $0.hasPrefix("z4") || $0.hasPrefix("z2") || $0.hasPrefix("k") || $0.hasPrefix("p")
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
            if transport.contains("STAV") {return true}
            if linesLower.contains(where: { $0.hasPrefix("z5") }) {return true}
        }
        
        if favorites.contains("z4"){
            if transport.contains("Autoguidovie") {return true}
            if linesLower.contains(where: { $0.hasPrefix("z4") }) {return true}
        }

        if favorites.contains("z2"){
            if transport.contains("Autoguidovie") {return true}
            if linesLower.contains(where: { $0.hasPrefix("z2") }) {return true}
        }
        
        if favorites.contains("k"){
            if transport.contains("Autoguidovie") {return true}
            if linesLower.contains(where: { $0.hasPrefix("k") }) {return true}
        }
        
        if favorites.contains("p"){
            if transport.contains("Autoguidovie") {return true}
            if linesLower.contains(where: { $0.hasPrefix("p") }) {return true}
        }
        
        if favorites.contains("Tram") {
            let isTram = transport.contains("tram") && !transport.contains("tram.fill.tunnel") && !transport.contains("metro")
            if isTram { return true }
        }
        
        for workLine in self.lines {
            let cleanWorkLine = workLine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            
            for fav in favorites {
                let cleanFav = fav.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if cleanWorkLine == cleanFav {
                    return true
                }
            }
            
            let upperLine = workLine.uppercased()
            
            if favorites.contains("S") && upperLine.hasPrefix("S") {
                let suffix = upperLine.dropFirst()
                if !suffix.isEmpty && suffix.allSatisfy({ $0.isNumber }) { return true }
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

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
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

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

#Preview {
    ContentView()
}

