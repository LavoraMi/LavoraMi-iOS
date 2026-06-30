//
//  AdPositionCalculator.swift
//  LavoraMi
//
//  Created by Andrea Filice on 30/06/2026.
//

import Foundation

struct AdPositionCalculator {
    let totalItems: Int
    let totalAds: Int
    
    init(itemCount: Int, adCount: Int) {
        self.totalItems = itemCount
        self.totalAds = adCount
    }
    
    func shouldShowAdAtAdapterPosition(_ position: Int) -> Bool {
        if totalAds == 0 || totalItems < 6 {
            return false
        }
        
        if position == 4 && totalItems >= 6 {
            return true
        }
        
        if position == getItemCount() - 1 && totalAds > 0 {
            return true
        }
        
        if position % 8 == 7 && position != 7 {
            let adIndex = (position + 1) / 8 - 1
            return adIndex < totalAds
        }
        
        return false
    }
    
    func getRealEventPosition(for adapterPosition: Int) -> Int {
        if totalAds == 0 || totalItems >= 6 && adapterPosition > 4 {
            return adapterPosition - 1
        }
        return adapterPosition
    }
    
    func getItemCount() -> Int {
        if totalAds == 0 {
            return totalItems
        }
        
        if totalItems >= 6 {
            return totalItems + 1
        }
        
        let totalSlots = (totalItems / 7) + 1
        let maxAds = min(totalSlots, totalAds)
        return totalItems + maxAds
    }
    
    func getAdIndexForPosition(_ position: Int) -> Int? {
        var adCount = 0
        for i in 0...position {
            if shouldShowAdAtAdapterPosition(i) {
                if i == position {
                    return adCount
                }
                adCount += 1
            }
        }
        return nil
    }
}

extension Array where Element: Identifiable {
    func withAdsInserted(adCount: Int) -> [(index: Int, type: AdItemType, item: Element?)] {
        var result: [(index: Int, type: AdItemType, item: Element?)] = []
        let calculator = AdPositionCalculator(itemCount: self.count, adCount: adCount)
        
        for adapterPos in 0..<calculator.getItemCount() {
            if calculator.shouldShowAdAtAdapterPosition(adapterPos) {
                result.append((index: result.count, type: .ad, item: nil))
            } else {
                let realPos = calculator.getRealEventPosition(for: adapterPos)
                if realPos >= 0 && realPos < self.count {
                    result.append((index: result.count, type: .item, item: self[realPos]))
                }
            }
        }
        
        return result
    }
}

enum AdItemType {
    case item
    case ad
}
