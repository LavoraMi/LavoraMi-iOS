//
//  WorkViewModel.swift
//  LavoraMi
//
//  Created by Andrea Filice on 06/01/26.
//

import Foundation
import Combine
import SwiftUI

class WorkViewModel: ObservableObject {
    @Published var items: [WorkItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var strikeEnabled: Bool = false
    @Published var strikeEnabledDebug: Bool = false
    @Published var companiesStrikes: String = ""
    @Published var dateStrike: String = ""
    @Published var guaranteed: String = ""
    @Published var maintenanceModeEnabled: Bool = false
    @Published var maintenanceModeDebugEnabled: Bool = false
    @Published var maintenanceDeps: String = ""
    @Published var maintenanceDepsEn: String = ""
    @Published var minimumVersion: String = ""
    @Published var linesDeviated: [String] = [""]
    @Published var linesDeviatedLink: [String] = [""]
    @Published var linesSupportedGTFS: [String] = [""]
    
    private let urlString = "https://cdn.lavorami.it/lavoriAttuali.json"
    private let urlVariables = "https://cdn.lavorami.it/_vars.json"
    private let requirements = "https://cdn.lavorami.it/requirements.json"
    
    func fetchWorks() {
        guard let url = URL(string: urlString) else {
            self.errorMessage = "URL non valido"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "Nessun dato ricevuto"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let decodedItems = try decoder.decode([WorkItem].self, from: data)
                    self?.items = decodedItems

                    let defaults = UserDefaults.standard
                    var savedFavorites: [String] = []
                    
                    if let savedFavoritesData = defaults.data(forKey: "linesFavorites"),
                       let decoded = try? JSONDecoder().decode([String].self, from: savedFavoritesData) {
                        savedFavorites = decoded
                    } else if let favoritesString = defaults.string(forKey: "linesFavorites"),
                              let data = favoritesString.data(using: .utf8),
                              let decoded = try? JSONDecoder().decode([String].self, from: data) {
                        savedFavorites = decoded
                    }
                    
                    let notificationsEnabled = (defaults.object(forKey: "enableNotifications") as? Bool) ?? true
                    if notificationsEnabled {
                        NotificationManager.shared.syncNotifications(for: decodedItems, favorites: savedFavorites)
                    }
                } catch {
                    self?.errorMessage = "\(error.localizedDescription)"
                    print("Errore di decodifica: \(error)")
                }
            }
        }.resume()
    }
    
    func fetchVariables() {
        guard let url = URL(string: urlVariables) else {
            self.errorMessage = "URL non valido"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Nessun dato trovato."
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(RemoteConfigData.self, from: data)
                DispatchQueue.main.async {
                    self?.strikeEnabled = (result.enableStrike == "true")
                    self?.strikeEnabledDebug = (result.enableStrikeDebug == "true")
                    self?.companiesStrikes = result.companies
                    self?.dateStrike = result.date
                    self?.guaranteed = result.guaranteed
                    self?.linesDeviated = result.linesAffectedbyDeviation
                    self?.linesDeviatedLink = result.linesDeviationLinks
                    self?.linesSupportedGTFS = result.linesSupportedGTFS
                    
                    if self?.strikeEnabled == true {
                            NotificationManager.shared.scheduleStrikeNotifications(
                                dateString: result.date,
                                companies: result.companies,
                                guaranteed: result.guaranteed
                            )
                        } else {
                            NotificationManager.shared.removeStrikeNotifications()
                        }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "\(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchRequirements(completion: (() -> Void)? = nil) {
        guard let url = URL(string: requirements) else {
            self.errorMessage = "URL non valido"
            completion?()
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async { self?.isLoading = false }
            
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.errorMessage = error?.localizedDescription ?? "Nessun dato trovato."
                    completion?()
                }
                return
            }
            
            do {
                let result = try JSONDecoder().decode(RequirementsData.self, from: data)
                DispatchQueue.main.async {
                    self?.maintenanceModeEnabled = (result.maintenanceMode == "true")
                    self?.maintenanceModeDebugEnabled = (result.maintenanceModeDebug == "true")
                    self?.maintenanceDeps = result.maintenanceDeps
                    self?.minimumVersion = result.minVersioniOS
                    self?.maintenanceDepsEn = result.maintenanceDepsEn
                    completion?()
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "\(error.localizedDescription)"
                    completion?()
                }
            }
        }.resume()
    }
}

struct RemoteConfigData: Codable {
    let enableStrike: String
    let enableStrikeDebug: String
    let date: String
    let companies: String
    let guaranteed: String
    let linesAffectedbyDeviation: [String]
    let linesDeviationLinks: [String]
    let linesSupportedGTFS: [String]
}

struct RequirementsData: Codable {
    let maintenanceMode: String
    let maintenanceModeDebug: String
    let maintenanceDeps: String
    let maintenanceDepsEn: String
    let minVersioniOS: String
}
