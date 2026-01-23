//
//  NotificationManager
//  LavoraMi
//
//  Created by Andrea Filice on 06/01/26.
//

import UserNotifications
import UIKit
import SwiftUI

class NotificationManager {
    @AppStorage("workScheduledNotifications") var workScheduledNotifications: Bool = true
    @AppStorage("workInProgressNotifications") var workInProgressNotifications: Bool = true
    @AppStorage("strikeNotifications") var strikeNotifications: Bool = true
    @AppStorage("enableNotifications") var enableNotifications: Bool = true
    
    static var defaultTime: Date {
        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    @AppStorage("dateSchedule") var dateSchedule: Date = defaultTime
    
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Permesso notifiche concesso")
            } else if let error = error {
                print("Errore permessi: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleWorkAlerts(for work: WorkItem) {
        //WORK ENDED
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour], from: work.endDate)
        let notificationHour = dateComponents.hour ?? 0
        let preferredHour = Calendar.current.component(.hour, from: dateSchedule)
        let preferredMinutes = Calendar.current.component(.minute, from: dateSchedule)
        dateComponents.hour = (notificationHour >= 0 && notificationHour <= 10) ? preferredHour : dateComponents.hour
        dateComponents.minute = preferredMinutes
        
        let contentDayOf = UNMutableNotificationContent()
        contentDayOf.title = "Lavori terminati!"
        contentDayOf.body = "I lavori in \(work.roads) delle linee \(work.lines.joined(separator: ", ")) dovrebbero terminare oggi. Consulta il sito di \(work.company) per aggiornamenti all'ultimo minuto."
        contentDayOf.sound = .default
        
        if let dateOf = calendar.date(from: dateComponents), dateOf > Date() {
            let triggerDayOf = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let requestDayOf = UNNotificationRequest(identifier: "\(work.id.uuidString)_END", content: contentDayOf, trigger: triggerDayOf)
            center.add(requestDayOf)
            print("Notifica programmata per la fine: \(dateOf.formatted())")
        }
        
        if let dayBeforeDate = calendar.date(byAdding: .day, value: -1, to: work.endDate) {
            
            var dayBeforeComponents = calendar.dateComponents([.year, .month, .day, .hour], from: dayBeforeDate)
            let notificationHour = dayBeforeComponents.hour ?? 0
            dayBeforeComponents.hour = (notificationHour >= 0 && notificationHour <= 10) ? preferredHour : dayBeforeComponents.hour
            dayBeforeComponents.minute = preferredMinutes
            
            let debugDate = calendar.date(from: dayBeforeComponents)
            
            if dayBeforeDate > Date() {
                let contentDayBefore = UNMutableNotificationContent()
                contentDayBefore.title = "⚠️ I lavori finiscono domani!"
                contentDayBefore.body = "Domani terminano i lavori in \(work.roads) per \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                contentDayBefore.sound = .default
                
                let triggerDayBefore = UNCalendarNotificationTrigger(dateMatching: dayBeforeComponents, repeats: false)
                let requestDayBefore = UNNotificationRequest(identifier: "\(work.id.uuidString)_PRE", content: contentDayBefore, trigger: triggerDayBefore)
                center.add(requestDayBefore)
                print("Notifica programmata per il preavviso: \(String(describing: debugDate?.formatted()))")
            }
        }
        
        //WORK STARTED
        if(workScheduledNotifications){scheduleWorksBefore(for: work)}
    }
    
    func scheduleWorksBefore(for work: WorkItem){
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour], from: work.startDate)
        let notificationHour = dateComponents.hour ?? 0
        let preferredHour = Calendar.current.component(.hour, from: dateSchedule)
        let preferredMinutes = Calendar.current.component(.minute, from: dateSchedule)
        dateComponents.hour = (notificationHour >= 0 && notificationHour <= 10) ? preferredHour : dateComponents.hour
        dateComponents.minute = preferredMinutes
        
        let contentDayOf = UNMutableNotificationContent()
        contentDayOf.title = "Lavori Iniziati!"
        contentDayOf.body = "I lavori in \(work.roads) delle linee \(work.lines.joined(separator: ", ")) sono iniziati oggi. Consulta il sito di \(work.company) per maggiori info."
        contentDayOf.sound = .default
        
        if let dateOf = calendar.date(from: dateComponents), dateOf > Date() {
            let triggerDayOf = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let requestDayOf = UNNotificationRequest(identifier: "\(work.id.uuidString)_START", content: contentDayOf, trigger: triggerDayOf)
            center.add(requestDayOf)
            print("Notifica PREAVVISO NUOVO LAVORO: \(dateOf.formatted())")
        }
        
        if let dayBeforeDate = calendar.date(byAdding: .day, value: -1, to: work.startDate) {
            
            var dayBeforeComponents = calendar.dateComponents([.year, .month, .day, .hour], from: dayBeforeDate)
            let notificationHour = dayBeforeComponents.hour ?? 0
            dayBeforeComponents.hour = (notificationHour >= 0 && notificationHour <= 10) ? preferredHour : dayBeforeComponents.hour
            dayBeforeComponents.minute = preferredMinutes
            
            let debugDate = calendar.date(from: dayBeforeComponents)
            
            if dayBeforeDate > Date() {
                let contentDayBefore = UNMutableNotificationContent()
                contentDayBefore.title = "⚠️ I lavori iniziano domani!"
                contentDayBefore.body = "Domani iniziano i lavori in \(work.roads) per \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                contentDayBefore.sound = .default
                
                let triggerDayBefore = UNCalendarNotificationTrigger(dateMatching: dayBeforeComponents, repeats: false)
                let requestDayBefore = UNNotificationRequest(identifier: "\(work.id.uuidString)_PRESTART", content: contentDayBefore, trigger: triggerDayBefore)
                center.add(requestDayBefore)
                print("Notifica programmata per il preavviso: \(String(describing: debugDate?.formatted()))")
            }
        }
    }
        func removeStrikeNotifications() {
            let center = UNUserNotificationCenter.current()
            let identifiers = ["STRIKE_DAY", "STRIKE_PRE"]
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            print("Notifiche sciopero rimosse.")
        }

        func scheduleStrikeNotifications(dateString: String, companies: String, guaranteed: String) {
            removeStrikeNotifications()
            guard strikeNotifications && enableNotifications else { return }
            
            let center = UNUserNotificationCenter.current()
            let calendar = Calendar.current
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            dateFormatter.locale = Locale(identifier: "it_IT")
            
            guard let strikeDate = dateFormatter.date(from: dateString) else {
                print("Errore: Impossibile convertire '\(dateString)'")
                return
            }
            
            var dayOfComponents = calendar.dateComponents([.year, .month, .day, .hour], from: strikeDate)
            dayOfComponents.hour = 7
            dayOfComponents.minute = 0
            
            if let fireDate = calendar.date(from: dayOfComponents), fireDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "🚫 Oggi Sciopero!"
                content.body = "Oggi è previsto uno sciopero di \(companies), le fascie garantite \(guaranteed)."
                content.sound = .default
                
                let req = UNNotificationRequest(identifier: "STRIKE_DAY", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: dayOfComponents, repeats: false))
                center.add(req)
                print("🔔 Sciopero programmato per il: \(fireDate.formatted())")
            }
            
            if let dayBefore = calendar.date(byAdding: .day, value: -1, to: strikeDate) {
                var dayBeforeComponents = calendar.dateComponents([.year, .month, .day, .hour], from: dayBefore)
                dayBeforeComponents.hour = 18
                dayBeforeComponents.minute = 0
                
                if let firePreDate = calendar.date(from: dayBeforeComponents), firePreDate > Date() {
                    let contentPre = UNMutableNotificationContent()
                    contentPre.title = "⚠️ Domani Sciopero!"
                    contentPre.body = "Domani c'è sciopero per \(companies), le fascie garantite \(guaranteed)"
                    contentPre.sound = .default
                    
                    let reqPre = UNNotificationRequest(identifier: "STRIKE_PRE", content: contentPre, trigger: UNCalendarNotificationTrigger(dateMatching: dayBeforeComponents, repeats: false))
                    center.add(reqPre)
                    print("🔔 Preavviso sciopero programmato per il: \(firePreDate.formatted())")
                }
            }
        }
    
    func removeWorkAlerts(for work: WorkItem) {
        let center = UNUserNotificationCenter.current()
        let identifiers = ["\(work.id.uuidString)_END", "\(work.id.uuidString)_PRE", "\(work.id.uuidString)_START", "\(work.id.uuidString)_PRESTART"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Notifiche rimosse per: \(work.title)")
    }
    
    func syncNotifications(for works: [WorkItem], favorites: [String]) {
        _ = UNUserNotificationCenter.current()
        for work in works {
            
            if work.matchesFavorites(favorites) {
                if(workInProgressNotifications){
                    scheduleWorkAlerts(for: work)
                    print("Attivata notifica per fine lavori: \(work.title), zona \(work.roads) (Match preferiti)")
                }
                if (workScheduledNotifications){
                    scheduleWorksBefore(for: work)
                    print("Attivata notifica per inizio lavori: \(work.title)")
                }
                else{removeWorkAlerts(for: work)}
            }
        }
    }
}
