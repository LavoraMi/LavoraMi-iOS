//
//  AdMobManager.swift
//  LavoraMi
//
//  Created by Andrea Filice on 30/06/2026.
//

import Foundation
import GoogleMobileAds
import SwiftUI
import Combine

class AdMobManager: NSObject, ObservableObject {
    @Published var nativeAds: [NativeAd] = []
    @Published var isLoading = false
    
    private var adLoader: AdLoader?
    private var loadedCount = 0
    private let totalDesired = 15
    private let batchSize = 5
    
    override init() {
        super.init()
        initializeMobileAds()
    }
    
    private func initializeMobileAds() {
        MobileAds.shared.start()
    }
    
    func loadNativeAds(adUnitID: String) {
        isLoading = true
        loadedCount = 0
        nativeAds.removeAll()
        loadNextBatch(adUnitID: adUnitID)
    }
    
    private func loadNextBatch(adUnitID: String) {
        if loadedCount >= totalDesired {
            isLoading = false
            return
        }
        
        let remaining = totalDesired - loadedCount
        let toLoad = min(batchSize, remaining)
        
        let options = NativeAdImageAdLoaderOptions()
        options.shouldRequestMultipleImages = false
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: [options]
        )
        
        adLoader?.delegate = self
        let request = Request()
        adLoader?.load(request)
    }
    
    deinit {
        for ad in nativeAds {
            ad.delegate = nil
        }
    }
}

extension AdMobManager: AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        let remaining = totalDesired - loadedCount
        if remaining > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadNextBatch(adUnitID: adLoader.adUnitID)
            }
        } else {
            isLoading = false
        }
    }
}

extension AdMobManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            self.nativeAds.append(nativeAd)
            self.loadedCount += 1
            
            if self.loadedCount % self.batchSize == 0 || self.loadedCount >= self.totalDesired {
                if self.loadedCount < self.totalDesired {
                    self.loadNextBatch(adUnitID: adLoader.adUnitID)
                } else {
                    self.isLoading = false
                }
            }
        }
    }
}
