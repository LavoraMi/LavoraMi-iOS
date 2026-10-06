//
//  AdPositionCalculator.swift
//  LavoraMi
//
//  Created by Andrea Filice on 30/06/2026.
//

import Foundation

enum AdPlacement {
    static let positions: [Int] = [1, 4]
    static var maxAds: Int {positions.count}
}

enum AdItemType {
    case item
    case ad
}

extension Array where Element: Identifiable {
    func withAdsInserted(adCount: Int) -> [(index: Int, type: AdItemType, item: Element?, adIndex: Int?)] {
        var result: [(index: Int, type: AdItemType, item: Element?, adIndex: Int?)] = []
        guard !isEmpty else {return result}
        
        let availableAds = Swift.min(adCount, AdPlacement.positions.count)
        var adIndex = 0
        
        for element in self {
            if adIndex < availableAds && result.count == AdPlacement.positions[adIndex] {
                result.append((index: result.count, type: .ad, item: nil, adIndex: adIndex))
                adIndex += 1
            }
            result.append((index: result.count, type: .item, item: element, adIndex: nil))
        }
        
        while adIndex < availableAds {
            result.append((index: result.count, type: .ad, item: nil, adIndex: adIndex))
            adIndex += 1
        }
        
        return result
    }
}
