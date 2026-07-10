//
//  LocationManager.swift
//  LavoraMi
//
//  Created by Andrea Filice on 07/06/2026.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermission() {manager.requestWhenInUseAuthorization()}
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("Permesso garantito!")
            case .denied, .restricted:
                print("Permesso negato.")
            case .notDetermined:
                print("In attesa di risposta...")
            @unknown default:
                break
        }
    }
}
