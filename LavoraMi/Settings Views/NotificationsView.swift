//
//  NotificationsView.swift
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
                    
                    Text("Imposta tutte le notifiche sottostanti su uno stato.")
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
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    Section("Altre Notifiche") {
                        Toggle(isOn: $strikeNotifications) {
                            Label("Notifiche Scioperi", systemImage: "megaphone.fill")
                        }
                        .onChange(of: strikeNotifications){
                            viewModel.fetchVariables()
                        }
                        .disabled(!enableNotifications)
                        Toggle(isOn: $enablePushNotifications) {
                            Label("Notifiche In Tempo Reale", systemImage: "bell.and.waves.left.and.right.fill")
                        }
                        .onChange(of: enablePushNotifications) { oldValue, enabled in
                            NotificationCenter.default.post(name: NSNotification.Name("pushNotificationsToggled"), object: enabled)
                        }
                        .disabled(!enableNotifications)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    Section(header: Text("Impostazioni Notifiche"), footer: Text("Modifica l'orario di arrivo delle notifiche.")){
                        VStack{
                            DatePicker(selection: $dateSchedule, displayedComponents: .hourAndMinute){
                                Label("Orario Notifiche", systemImage: "clock.badge.fill")
                            }
                            .disabled(!enableNotifications)
                        }
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
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
