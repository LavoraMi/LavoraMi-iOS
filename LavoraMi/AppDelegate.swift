//
//  AppDelegate.swift
//  LavoraMi
//
//  Created by Andrea Filice on 06/01/26.
//

import SwiftUI
import UserNotifications
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(handlePushToggle(_:)), name: NSNotification.Name("pushNotificationsToggled"), object: nil)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }

        return true
    }

    @objc func handlePushToggle(_ notification: Notification) {
        guard let enabled = notification.object as? Bool else { return }
        if enabled {
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            Messaging.messaging().deleteToken { _ in
                UserDefaults.standard.removeObject(forKey: "fcmToken")
            }
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenHex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs token: \(tokenHex)")
        UserDefaults.standard.set(tokenHex, forKey: "apnsToken")

        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { token, error in
            if let error = error {
                UserDefaults.standard.set("ERRORE: \(error.localizedDescription)", forKey: "fcmDebug")
                return
            }
            guard let token = token else { return }
            print("FCM Token rigenerato: \(token)")
            UserDefaults.standard.set(token, forKey: "fcmToken")
            UserDefaults.standard.set("OK", forKey: "fcmDebug")
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Errore APNs: \(error.localizedDescription)")
        UserDefaults.standard.set("FALLITO: \(error.localizedDescription)", forKey: "apnsToken")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM Token: \(token)")
        UserDefaults.standard.set(token, forKey: "fcmToken")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let pushAbilitate = UserDefaults.standard.object(forKey: "enablePushNotifications") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "enablePushNotifications")

        completionHandler(pushAbilitate ? [.banner, .sound, .badge, .list] : [])
    }
}
