//
//  HowAppWorksView.swift
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

struct HowAppWorksView: View {
    let interchangeInfo: InterchangeInfo = .init(name: "Rho Fiera-Milano", lines: ["M1", "S5", "S6", "S11", "R21", "561"], typeOfInterchange: "lightrail.fill")
    let workItem: WorkItem = .init(title: "Rallentamenti", titleIcon: "clock.badge.fill", typeOfTransport: "train.side.front.car", roads: "Palazzolo, Camnago Lentate, Seveso", lines: ["S2", "S4", "R16"], startDate: ISO8601DateFormatter().date(from: "2026-02-23T00:00:00+01:00") ?? Date(), endDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date(), details: "Nei giorni feriali (escluso il sabato), per lavori di potenziamento infrastrutturale nella tratta Palazzolo – Camnago/L. – Seveso, i seguenti treni circoleranno tra Milano Cadorna e Palazzolo M. a eccezione del treno “R” 11689 che sarà soppresso per l’intero percorso. Si segnala che le corse autobus d’orario 1689A, 691A e 693A saranno sostituite rispettivamente dalle corse 3689A, 2691A e 2693A.", company: "Trenord")
    let stations: [MetroStation] = MetroStationsDB.stationsM1;
    
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
                    .background(Color(.secondarySystemBackground))
                }
                
                Text("Oppure salva una linea nella sezione \"Le tue Linee\" per vedere, tramite l'apposito filtro, solo i lavori che interessano a te.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                CardView {
                    HStack {
                        Text("M1")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(getColor(for: "M1"))
                            )
                        Text("Metro M1")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color(red: 1, green: 93 / 255, blue: 162 / 255))
                            .frame(width: 18, height: 18)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color(.secondarySystemBackground))
                }

                SectionDivider()

                SectionHeader(icon: "arrow.left.arrow.right", title: String(localized: .visualizzaGliInterscambi))

                Text("Visualizza le linee che interscambiano con la TUA linea, oppure sui bus visualizza dove fanno capolinea con una fermata di interscambio.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                InterchangeRow(interchange: interchangeInfo, currentLine: "RE4", isFirst: false, isLast: false)
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
                            center: CLLocationCoordinate2D(latitude: 45.4682, longitude: 9.17588),
                            span: MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)
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

                Text("Ti avvisiamo il giorno prima della fine dei lavori, quando spuntano nuovi cantieri sulla tua linea preferita ed anche quando sarà un venerdì no.")
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
        .navigationTitle("Funzioni dell'App")
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
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 10)
    }
}
