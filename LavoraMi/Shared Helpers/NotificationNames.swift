//
//  NotificationNames.swift
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

// MARK: DEEP LINK
extension Notification.Name {
    static let openLetueLinkInfo = Notification.Name("openLetueLinkInfo")
    static let openLineDetailFromWidget = Notification.Name("openLineDetailFromWidget")
    static let openTrainFilter = Notification.Name("openTrainFilter")
}
