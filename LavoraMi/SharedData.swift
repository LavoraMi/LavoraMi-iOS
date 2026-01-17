//
//  SharedData.swift
//  LavoraMi
//
//  Created by Andrea Filice on 17/01/26.
//

import Foundation
import WidgetKit
import SwiftUI

struct SavedLine: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let longName: String
    let worksNow: Int
    let worksScheduled: Int
    
    static let empty = SavedLine(id: "empty", name: "empty", longName: "", worksNow: 0, worksScheduled: 0)
}

class DataManager {
    static let shared = DataManager()
    
    @AppStorage("favouriteLine", store: UserDefaults(suiteName: "group.com.andreafilice.lavorami"))
    private var savedLineData: Data = Data()
    
    func setSavedLine(_ line: SavedLine) {
        guard let encoded = try? JSONEncoder().encode(line) else {
            return
        }
        
        savedLineData = encoded
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func getSavedLine() -> SavedLine? {
        guard !savedLineData.isEmpty else {
            return nil
        }
        
        do {
            let line = try JSONDecoder().decode(SavedLine.self, from: savedLineData)
            return line
        } catch {
            return nil
        }
    }
    
    func deleteSavedLine() {
        savedLineData = Data()
    }
}
