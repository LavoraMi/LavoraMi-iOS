//
//  LineHelpers.swift
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

func generateRandomLine() -> String {
    /// This is a method to generate random line names for suggestions.
    /// - Parameters: no parameters for this function.
    /// - Returns: String name of the line extracted randomly.
    
    let lineList: [String] = ["M1", "M4", "S5", "S6", "S8", "R16", "R22", "R40", "RE1", "RE3", "z620", "z643"]
    let randomIndex = Int(arc4random_uniform(UInt32(lineList.count)))
    
    return lineList[randomIndex]
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
    
    return URL(string: "https://www.lavorami.it/404")!
}

func getSuburbanDeviationLink(line: String, viewModel: WorkViewModel) -> URL {
    if let i = viewModel.suburbanWithInterruptions.firstIndex(of: line) {
        return URL(string: viewModel.suburbanInterruptionLinks[i])!
    }
    
    return URL(string: "https://www.lavorami.it/404")!
}

func getRegionalDeviationLink(line: String, viewModel: WorkViewModel) -> URL {
    if let i = viewModel.regionalWithInterruptions.firstIndex(of: line) {
        return URL(string: viewModel.regionalInterruptionLinks[i])!
    }
    
    return URL(string: "https://www.lavorami.it/404")!
}

func getInterchanges(line: String) -> [InterchangeInfo] {
    if (line.starts(with: "M") && !line.starts(with: "MXP")) || line == "H" {
        return InterchangesDB.getMetroInterchanges(line: line)
    }
    else if line.starts(with: "MXP") {
        return InterchangesDB.getMalpensaExpressInterchanges(line: line)
    }
    else if line.starts(with: "S") && !isLineTILO(lineName: line) {
        return InterchangesDB.getSuburbanInterchanges(line: line)
    }
    else if line.starts(with: "R") && !line.starts(with: "RE") {
        return InterchangesDB.getRLinesInterchanges(line: line)
    }
    else if line.starts(with: "RE") {
        return InterchangesDB.getRELinesInterchanges(line: line)
    }
    else if isLineTILO(lineName: line) {
        return InterchangesDB.getTILOInterchanges (line: line)
    }
    else if Int(line) != nil {
        if(line.wholeMatch(of: /9[0-3]/) != nil) { return InterchangesDB.getFilobusInterchanges(line: line) }
        return InterchangesDB.getTramInterchanges(line: line)
    }
    else {return []}
}
