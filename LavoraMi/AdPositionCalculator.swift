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
        if totalAds == 0 || totalItems < 6 {return false}
        
        guard position >= 4, (position - 4) % 8 == 0 else {return false}
        
        let k = (position - 4) / 8
        guard k < totalAds else {return false}
        
        return totalItems > 4 + 7 * k
    }
    
    func getRealEventPosition(for adapterPosition: Int) -> Int {
        if totalAds == 0 {return adapterPosition}
        
        var itemsCount = 0
        var adsCount = 0
        
        for i in 0..<adapterPosition {
            if shouldShowAdAtAdapterPosition(i) {adsCount += 1}
            else {itemsCount += 1}
        }
        
        return itemsCount
    }
    
    func getItemCount() -> Int {
        if totalAds == 0 {return totalItems}
        
        if totalItems >= 6 {
            let adsToShow = min(totalAds, 1 + ((totalItems - 5) / 7))
            return totalItems + adsToShow
        }
        
        return totalItems
    }
    
    func getAdIndexForPosition(_ position: Int) -> Int? {
        var adCount = 0
        
        for i in 0...position {
            if shouldShowAdAtAdapterPosition(i) {
                if i == position {return adCount}
                
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
            if calculator.shouldShowAdAtAdapterPosition(adapterPos) {result.append((index: result.count, type: .ad, item: nil))}
            else {
                let realPos = calculator.getRealEventPosition(for: adapterPos)
                if realPos >= 0 && realPos < self.count {result.append((index: result.count, type: .item, item: self[realPos]))}
            }
        }
        
        return result
    }
}

enum AdItemType {
    case item
    case ad
}
