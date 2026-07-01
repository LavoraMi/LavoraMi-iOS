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
    private var adUnitIDInUse: String = ""
    
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
        adUnitIDInUse = adUnitID
        nativeAds.removeAll()
        loadNextBatch()
    }
    
    private func loadNextBatch() {
        if loadedCount >= totalDesired {
            isLoading = false
            return
        }
        
        let remaining = totalDesired - loadedCount
        let toLoad = min(batchSize, remaining)
        
        let imageOptions = NativeAdImageAdLoaderOptions()
        imageOptions.shouldRequestMultipleImages = false
        
        var loaderOptions: [GADAdLoaderOptions] = [imageOptions]
        if toLoad > 1 {
            let multipleAdsOptions = MultipleAdsAdLoaderOptions()
            multipleAdsOptions.numberOfAds = toLoad
            loaderOptions.append(multipleAdsOptions)
        }
        
        adLoader = AdLoader(
            adUnitID: adUnitIDInUse,
            rootViewController: nil,
            adTypes: [.native],
            options: loaderOptions
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
    }
    
    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        if loadedCount < totalDesired {
            loadNextBatch()
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
        }
    }
}
