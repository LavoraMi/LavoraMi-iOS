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
    
    private var adLoaders: [AdLoader] = []
    private var pendingRequests = 0
    private let totalDesired: Int
    
    init(totalDesired: Int = AdPlacement.maxAds) {
        self.totalDesired = totalDesired
        super.init()
        initializeMobileAds()
    }
    
    private func initializeMobileAds() {
        MobileAds.shared.start()
    }
    
    func loadNativeAds(adUnitID: String) {
        guard ConsentManager.shared.canRequestAds else {
            isLoading = false
            return
        }
        
        isLoading = true
        nativeAds.removeAll()
        adLoaders.removeAll()
        pendingRequests = totalDesired
        
        for _ in 0..<totalDesired {
            let loader = makeLoader(adUnitID: adUnitID)
            adLoaders.append(loader)
            loader.load(Request())
        }
    }
    
    private func makeLoader(adUnitID: String) -> AdLoader {
        let imageOptions = NativeAdImageAdLoaderOptions()
        imageOptions.shouldRequestMultipleImages = false
        
        let viewOptions = NativeAdViewAdOptions()
        viewOptions.preferredAdChoicesPosition = .topRightCorner
        
        let loader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: [imageOptions, viewOptions]
        )
        loader.delegate = self
        return loader
    }
    
    private func requestFinished() {
        pendingRequests = max(0, pendingRequests - 1)
        if pendingRequests == 0 {isLoading = false}
    }
    
    deinit {
        for ad in nativeAds {ad.delegate = nil}
    }
}

extension AdMobManager: AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            print("ADMOB: errore caricamento ad: \(error.localizedDescription)")
            self.requestFinished()
        }
    }
    
    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        DispatchQueue.main.async {self.requestFinished()}
    }
}

extension AdMobManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            self.nativeAds.append(nativeAd)
        }
    }
}
