//
//  GTFSHelper.swift
//  LavoraMi
//
//  Created by Andrea Filice on 21/04/2026.
//

import Foundation

struct GTFSRoute: Codable {
    let route: String
    let headsigns: [String]
    let services: [String: GTFSService]
    let stops: [String: GTFSStop]
}

struct GTFSService: Codable {
    let id: String
    let dates: [String]
    let daytype: String?
}

struct GTFSStop: Codable {
    let n: String
    let d: [String: [[AnyDecodable]]]
}

struct AnyDecodable: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) { value = s }
        else if let i = try? container.decode(Int.self) { value = i }
        else { value = "" }
    }
    
    func encode(to encoder: Encoder) throws {}
}

struct Departure: Identifiable {
    let id = UUID()
    let time: String
    let headsign: String
    let minutesFromNow: Int

    var formattedWait: String {
        guard minutesFromNow >= 60 else { return "\(minutesFromNow) min" }
        let hours = minutesFromNow / 60
        let mins = minutesFromNow % 60
        return mins == 0 ? "\(hours) h" : "\(hours) h \(mins) min"
    }
}

struct GTFSHelper {
    static func load(from url: URL) async throws -> GTFSRoute {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(GTFSRoute.self, from: data)
    }
    
    static func getDepartures(for stopId: String, in route: GTFSRoute, limit: Int = 10, now: Date = Date()) -> [String: [Departure]]? {
        guard let stop = route.stops[stopId] else { return nil }

        let nowMins = minutes(of: now)
        let active = activeServiceIndices(in: route, on: now)
        guard !active.isEmpty else { return nil }

        var result: [String: [Departure]] = [:]

        for (directionId, entries) in stop.d {
            var seen = Set<String>()
            var list: [Departure] = []

            for entry in entries {
                guard entry.count >= 3,
                      let timeStr = entry[0].value as? String,
                      let headsignIdx = entry[1].value as? Int,
                      let serviceIdx = entry[2].value as? Int,
                      active.contains(serviceIdx) else { continue }

                let parts = timeStr.split(separator: ":").compactMap { Int($0) }
                guard parts.count == 2 else { continue }
                let diff = parts[0] * 60 + parts[1] - nowMins
                guard diff >= 0 else { continue }
                
                guard seen.insert("\(timeStr)|\(headsignIdx)").inserted else { continue }

                let headsign = route.headsigns.indices.contains(headsignIdx) ? route.headsigns[headsignIdx] : "Direzione ignota"
                list.append(Departure(time: timeStr, headsign: headsign, minutesFromNow: diff))
            }

            list.sort { $0.minutesFromNow < $1.minutesFromNow }
            if !list.isEmpty { result[directionId] = Array(list.prefix(limit)) }
        }

        return result.isEmpty ? nil : result
    }
    
    private static func activeServiceIndices(in route: GTFSRoute, on date: Date) -> Set<Int> {
        let today = dateString(date)
        var active = Set(route.services.compactMap { $0.value.dates.contains(today) ? Int($0.key) : nil })
        if active.isEmpty {
            let type = dayType(of: date)
            active = Set(route.services.compactMap { $0.value.daytype?.lowercased() == type ? Int($0.key) : nil })
        }
        
        return active
    }

    private static var romeCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Rome")!
        
        return cal
    }

    private static func dayType(of date: Date) -> String {
        let cal = romeCalendar
        let c = cal.dateComponents([.year, .month, .day, .weekday], from: date)
        guard let y = c.year, let m = c.month, let d = c.day, let wd = c.weekday else { return "feriale" }

        if wd == 1 || isHoliday(year: y, month: m, day: d) { return "festivo" }
        return wd == 7 ? "sabato" : "feriale"
    }

    private static func isHoliday(year: Int, month: Int, day: Int) -> Bool {
        let fixed: Set<[Int]> = [[1,1],[6,1],[25,4],[1,5],[2,6],[15,8],[1,11],[7,12],[8,12],[25,12],[26,12]]
        if fixed.contains([month, day]) { return true }

        let a = year % 19, b = year / 100, c = year % 100
        let d = b / 4, e = b % 4, f = (b + 8) / 25, g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4, k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let mm = (a + 11 * h + 22 * l) / 451
        let easterMonth = (h + l - 7 * mm + 114) / 31
        let easterDay = (h + l - 7 * mm + 114) % 31 + 1
        if month == easterMonth && day == easterDay { return true }

        var comps = DateComponents(year: year, month: easterMonth, day: easterDay)
        comps.timeZone = TimeZone(identifier: "Europe/Rome")
        if let easter = romeCalendar.date(from: comps),
           let monday = romeCalendar.date(byAdding: .day, value: 1, to: easter) {
            let mc = romeCalendar.dateComponents([.month, .day], from: monday)
            return mc.month == month && mc.day == day
        }
        return false
    }

    private static func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "Europe/Rome")
        
        return f.string(from: date)
    }

    private static func minutes(of date: Date) -> Int {
        let c = romeCalendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
