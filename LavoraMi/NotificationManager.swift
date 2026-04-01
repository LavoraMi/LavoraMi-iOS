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
    @AppStorage("notificationConsent") var notificationConsent: Bool = false
    
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
                self.notificationConsent = true
            } else if let error = error {
                print("Errore permessi: \(error.localizedDescription)")
                self.notificationConsent = false
            }
        }
    }
    
    func scheduleWorkAlerts(for work: WorkItem) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        let preferredHour = Calendar.current.component(.hour, from: dateSchedule)
        let preferredMinutes = Calendar.current.component(.minute, from: dateSchedule)
        
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour], from: work.endDate)
        let endHour = dateComponents.hour ?? 12
        dateComponents.hour = (endHour < 7) ? preferredHour : endHour
        dateComponents.minute = preferredMinutes
        
        let contentDayOf = UNMutableNotificationContent()
        contentDayOf.title = "Lavori terminati!"
        
        if(work.roads.range(of: "via", options: .caseInsensitive) != nil) {
            if(work.lines.count <= 1){
                contentDayOf.body = "I lavori in \(work.roads) della linea \(work.lines.joined(separator: ", ")) dovrebbero terminare oggi. Consulta il sito di \(work.company) per aggiornamenti all'ultimo minuto."
            }
            else{
                contentDayOf.body = "I lavori in \(work.roads) delle linee \(work.lines.joined(separator: ", ")) dovrebbero terminare oggi. Consulta il sito di \(work.company) per aggiornamenti all'ultimo minuto."
            }
        }
        else{
            if(work.lines.count <= 1){
                contentDayOf.body = "I lavori a \(work.roads) della linea \(work.lines.joined(separator: ", ")) dovrebbero terminare oggi. Consulta il sito di \(work.company) per aggiornamenti all'ultimo minuto."
            }
            else{
                contentDayOf.body = "I lavori a \(work.roads) delle linee \(work.lines.joined(separator: ", ")) dovrebbero terminare oggi. Consulta il sito di \(work.company) per aggiornamenti all'ultimo minuto."
            }
        }
        
        contentDayOf.sound = .default
        
        if let dateOf = calendar.date(from: dateComponents), dateOf > Date() {
            let triggerDayOf = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let requestDayOf = UNNotificationRequest(identifier: "\(work.id.uuidString)_END", content: contentDayOf, trigger: triggerDayOf)
            center.add(requestDayOf)
            print("✅ Notifica END programmata: \(dateOf.formatted())")
        }
        
        if let dayBeforeDate = calendar.date(byAdding: .day, value: -1, to: work.endDate), dayBeforeDate > Date() {
            var dayBeforeComponents = calendar.dateComponents([.year, .month, .day, .hour], from: dayBeforeDate)
            let preHour = dayBeforeComponents.hour ?? 12
            dayBeforeComponents.hour = (preHour < 7) ? preferredHour : preHour
            dayBeforeComponents.minute = preferredMinutes
            
            let contentDayBefore = UNMutableNotificationContent()
            contentDayBefore.title = "⚠️ I lavori finiscono domani!"
            
            if(work.roads.range(of: "via", options: .caseInsensitive) != nil) {
                if(work.lines.count <= 1){
                    contentDayBefore.body = "Domani terminano i lavori in \(work.roads) per la linea \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    contentDayBefore.body = "Domani terminano i lavori in \(work.roads) per le linee \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
            }
            else {
                if(work.lines.count <= 1){
                    contentDayBefore.body = "Domani terminano i lavori a \(work.roads) per la linea \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    contentDayBefore.body = "Domani terminano i lavori a \(work.roads) per le linee \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
            }
            
            contentDayBefore.sound = .default
            
            let triggerDayBefore = UNCalendarNotificationTrigger(dateMatching: dayBeforeComponents, repeats: false)
            let requestDayBefore = UNNotificationRequest(identifier: "\(work.id.uuidString)_PRE", content: contentDayBefore, trigger: triggerDayBefore)
            center.add(requestDayBefore)
            
            let debugDate = calendar.date(from: dayBeforeComponents)
            print("✅ Notifica PRE-END programmata: \(String(describing: debugDate?.formatted()))")
        }
    }
    
    func scheduleWorksBefore(for work: WorkItem) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        let preferredHour = Calendar.current.component(.hour, from: dateSchedule)
        let preferredMinutes = Calendar.current.component(.minute, from: dateSchedule)
        
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour], from: work.startDate)
        let startHour = dateComponents.hour ?? 12
        dateComponents.hour = (startHour < 7) ? preferredHour : startHour
        dateComponents.minute = preferredMinutes
        
        let contentDayOf = UNMutableNotificationContent()
        contentDayOf.title = "Lavori Iniziati!"
        
        if(work.roads.range(of: "via", options: .caseInsensitive) != nil) {
            if(work.lines.count <= 1){
                contentDayOf.body = "I lavori in \(work.roads) della linea \(work.lines.joined(separator: ", ")) sono iniziati oggi. Consulta il sito di \(work.company) per maggiori info."
            }
            else{
                contentDayOf.body = "I lavori in \(work.roads) delle linee \(work.lines.joined(separator: ", ")) sono iniziati oggi. Consulta il sito di \(work.company) per maggiori info."
            }
        }
        else {
            if(work.lines.count <= 1){
                contentDayOf.body = "I lavori a \(work.roads) della linea \(work.lines.joined(separator: ", ")) sono iniziati oggi. Consulta il sito di \(work.company) per maggiori info."
            }
            else{
                contentDayOf.body = "I lavori a \(work.roads) delle linee \(work.lines.joined(separator: ", ")) sono iniziati oggi. Consulta il sito di \(work.company) per maggiori info."
            }
        }
        
        contentDayOf.sound = .default
        
        if let dateOf = calendar.date(from: dateComponents), dateOf > Date() {
            let triggerDayOf = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let requestDayOf = UNNotificationRequest(identifier: "\(work.id.uuidString)_START", content: contentDayOf, trigger: triggerDayOf)
            center.add(requestDayOf)
            print("✅ Notifica START programmata: \(dateOf.formatted())")
        }
        
        if let dayBeforeDate = calendar.date(byAdding: .day, value: -1, to: work.startDate), dayBeforeDate > Date() {
            var dayBeforeComponents = calendar.dateComponents([.year, .month, .day, .hour], from: dayBeforeDate)
            let preHour = dayBeforeComponents.hour ?? 12
            dayBeforeComponents.hour = (preHour < 7) ? preferredHour : preHour
            dayBeforeComponents.minute = preferredMinutes
            
            let contentDayBefore = UNMutableNotificationContent()
            contentDayBefore.title = "⚠️ I lavori iniziano domani!"
            
            if(work.roads.range(of: "via", options: .caseInsensitive) != nil){
                if(work.lines.count <= 1){
                    contentDayBefore.body = "Domani iniziano i lavori in \(work.roads) per la linea \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    contentDayBefore.body = "Domani iniziano i lavori in \(work.roads) per le linee \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
            }
            else{
                if(work.lines.count <= 1){
                    contentDayBefore.body = "Domani iniziano i lavori a \(work.roads) per la linea \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    contentDayBefore.body = "Domani iniziano i lavori a \(work.roads) per le linee \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
            }
            
            contentDayBefore.sound = .default
            
            let triggerDayBefore = UNCalendarNotificationTrigger(dateMatching: dayBeforeComponents, repeats: false)
            let requestDayBefore = UNNotificationRequest(identifier: "\(work.id.uuidString)_PRESTART", content: contentDayBefore, trigger: triggerDayBefore)
            center.add(requestDayBefore)
            
            let debugDate = calendar.date(from: dayBeforeComponents)
            print("✅ Notifica PRE-START programmata: \(String(describing: debugDate?.formatted()))")
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
        guard enableNotifications else {
            for work in works { removeWorkAlerts(for: work) }
            return
        }
        
        for work in works { removeWorkAlerts(for: work) }
        
        let now = Date()
        let calendar = Calendar.current
        
        struct PendingNotif {
            let work: WorkItem
            let date: Date
            let type: String
        }
        
        var pending: [PendingNotif] = []
        
        let preferredHour = calendar.component(.hour, from: dateSchedule)
        let preferredMin  = calendar.component(.minute, from: dateSchedule)
        
        for work in works {
            guard work.matchesFavorites(favorites) else { continue }
            
            func adjustedDate(_ base: Date) -> Date {
                let h = calendar.component(.hour, from: base)
                var comps = calendar.dateComponents([.year, .month, .day], from: base)
                comps.hour   = (h < 7) ? preferredHour : h
                comps.minute = preferredMin
                comps.second = 0
                return calendar.date(from: comps) ?? base
            }
            
            if workInProgressNotifications {
                let endNotif = adjustedDate(work.endDate)
                if endNotif > now { pending.append(PendingNotif(work: work, date: endNotif, type: "END")) }
                
                if let pre = calendar.date(byAdding: .day, value: -1, to: work.endDate) {
                    let preNotif = adjustedDate(pre)
                    if pre > now { pending.append(PendingNotif(work: work, date: preNotif, type: "PRE_END")) }
                }
            }
            
            if workScheduledNotifications {
                let startNotif = adjustedDate(work.startDate)
                if startNotif > now { pending.append(PendingNotif(work: work, date: startNotif, type: "START")) }
                
                if let pre = calendar.date(byAdding: .day, value: -1, to: work.startDate) {
                    let preNotif = adjustedDate(pre)
                    if pre > now { pending.append(PendingNotif(work: work, date: preNotif, type: "PRE_START")) }
                }
            }
        }
        
        let sorted = pending.sorted { $0.date < $1.date }
        let toSchedule = Array(sorted.prefix(60))
        
        print("📊 Notifiche da schedulare: \(pending.count) totali, \(toSchedule.count) programmate (limite 60), \(max(0, pending.count - 60)) scartate per overflow")
        
        for item in toSchedule {
            switch item.type {
            case "END", "PRE_END":
                scheduleSingleAlert(for: item.work, type: item.type)
            case "START", "PRE_START":
                scheduleSingleBefore(for: item.work, type: item.type)
            default: break
            }
        }
    }
    
    private func scheduleSingleAlert(for work: WorkItem, type: String) {
        let center   = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let preferredHour = calendar.component(.hour, from: dateSchedule)
        let preferredMin  = calendar.component(.minute, from: dateSchedule)
        
        func notifDate(from base: Date) -> (DateComponents, Date?) {
            var comps = calendar.dateComponents([.year, .month, .day, .hour], from: base)
            let h = comps.hour ?? 12
            comps.hour   = (h < 7) ? preferredHour : h
            comps.minute = preferredMin
            return (comps, calendar.date(from: comps))
        }
        
        if type == "END" {
            let (comps, date) = notifDate(from: work.endDate)
            guard let date = date, date > Date() else { return }
            let content = UNMutableNotificationContent()
            content.title = "Lavori terminati!"
            
            if(work.roads.range(of: "via", options: .caseInsensitive) != nil) {
                if(work.lines.count <= 1){
                    content.body = "I lavori in \(work.roads) della linea \(work.lines.joined(separator: ", ")) dovrebbero terminare oggi. Consulta il sito di \(work.company) per aggiornamenti all'ultimo minuto."
                }
                else{
                    content.body = "I lavori in \(work.roads) delle linee \(work.lines.joined(separator: ", ")) dovrebbero terminare oggi. Consulta il sito di \(work.company) per aggiornamenti all'ultimo minuto."
                }
            }
            else{
                if(work.lines.count <= 1){
                    content.body = "I lavori a \(work.roads) della linea \(work.lines.joined(separator: ", ")) dovrebbero terminare oggi. Consulta il sito di \(work.company) per aggiornamenti all'ultimo minuto."
                }
                else{
                    content.body = "I lavori a \(work.roads) delle linee \(work.lines.joined(separator: ", ")) dovrebbero terminare oggi. Consulta il sito di \(work.company) per aggiornamenti all'ultimo minuto."
                }
            }
            
            content.sound = .default
            center.add(UNNotificationRequest(identifier: "\(work.id.uuidString)_END", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
            print("✅ END: \(date.formatted()) | \(work.title) - \(work.roads)")
            
        }
        else {
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: work.endDate), dayBefore > Date() else { return }
            let (comps, date) = notifDate(from: dayBefore)
            let content = UNMutableNotificationContent()
            content.title = "⚠️ I lavori finiscono domani!"
            
            if(work.roads.range(of: "via", options: .caseInsensitive) != nil) {
                if(work.lines.count <= 1){
                    content.body = "Domani terminano i lavori in \(work.roads) per la linea \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    content.body = "Domani terminano i lavori in \(work.roads) per le linee \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
            }
            else {
                if(work.lines.count <= 1){
                    content.body = "Domani terminano i lavori a \(work.roads) per la linea \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    content.body = "Domani terminano i lavori a \(work.roads) per le linee \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
            }
            
            content.sound = .default
            center.add(UNNotificationRequest(identifier: "\(work.id.uuidString)_PRE", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
            print("✅ PRE_END: \(String(describing: date?.formatted())) | \(work.title) - \(work.roads)")
        }
    }
    
    private func scheduleSingleBefore(for work: WorkItem, type: String) {
        let center   = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let preferredHour = calendar.component(.hour, from: dateSchedule)
        let preferredMin  = calendar.component(.minute, from: dateSchedule)
        
        func notifDate(from base: Date) -> (DateComponents, Date?) {
            var comps = calendar.dateComponents([.year, .month, .day, .hour], from: base)
            let h = comps.hour ?? 12
            comps.hour   = (h < 7) ? preferredHour : h
            comps.minute = preferredMin
            return (comps, calendar.date(from: comps))
        }
        
        if type == "START" {
            let (comps, date) = notifDate(from: work.startDate)
            guard let date = date, date > Date() else { return }
            let content = UNMutableNotificationContent()
            content.title = "Lavori Iniziati!"
            
            if(work.roads.range(of: "via", options: .caseInsensitive) != nil) {
                if(work.lines.count <= 1){
                    content.body = "I lavori in \(work.roads) della linea \(work.lines.joined(separator: ", ")) sono iniziati oggi. Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    content.body = "I lavori in \(work.roads) delle linee \(work.lines.joined(separator: ", ")) sono iniziati oggi. Consulta il sito di \(work.company) per maggiori info."
                }
            }
            else {
                if(work.lines.count <= 1){
                    content.body = "I lavori a \(work.roads) della linea \(work.lines.joined(separator: ", ")) sono iniziati oggi. Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    content.body = "I lavori a \(work.roads) delle linee \(work.lines.joined(separator: ", ")) sono iniziati oggi. Consulta il sito di \(work.company) per maggiori info."
                }
            }
            
            content.sound = .default
            center.add(UNNotificationRequest(identifier: "\(work.id.uuidString)_START", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
            print("✅ START: \(date.formatted()) | \(work.title) - \(work.roads)")
            
        }
        else {
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: work.startDate), dayBefore > Date() else { return }
            let (comps, date) = notifDate(from: dayBefore)
            let content = UNMutableNotificationContent()
            content.title = "⚠️ I lavori iniziano domani!"
            
            if(work.roads.range(of: "via", options: .caseInsensitive) != nil){
                if(work.lines.count <= 1){
                    content.body = "Domani iniziano i lavori in \(work.roads) per la linea \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    content.body = "Domani iniziano i lavori in \(work.roads) per le linee \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
            }
            else{
                if(work.lines.count <= 1){
                    content.body = "Domani iniziano i lavori a \(work.roads) per la linea \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
                else{
                    content.body = "Domani iniziano i lavori a \(work.roads) per le linee \(work.lines.joined(separator: ", ")). Consulta il sito di \(work.company) per maggiori info."
                }
            }
            
            content.sound = .default
            center.add(UNNotificationRequest(identifier: "\(work.id.uuidString)_PRESTART", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
            print("✅ PRE_START: \(String(describing: date?.formatted())) | \(work.title) - \(work.roads)")
        }
    }
    
    func getPermissionOfNotifications(){
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    print("Stato notifiche: ATTIVO")
                    self.notificationConsent = true
                case .denied, .notDetermined:
                    print("Stato notifiche: NEGATO o NON DETERMINATO")
                    self.notificationConsent = false
                @unknown default:
                    self.notificationConsent = false
                }
            }
        }
    }
}
