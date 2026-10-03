//
//  GTFSHelper.swift
//  LavoraMi
//
//  Created by Andrea Filice on 21/04/2026.
//

import Foundation

struct GTFSRoute: Codable, Sendable {
    let route: String
    let headsigns: [String]
    let services: [String: GTFSService]
    let stops: [String: GTFSStop]
}

struct GTFSService: Codable, Sendable {
    let id: String
    let dates: [String]
    let daytype: String?
}

struct GTFSStop: Codable, Sendable {
    let n: String
    let d: [String: [GTFSEntry]]
}

struct GTFSEntry: Codable, Sendable {
    let minutes: Int
    let headsign: Int
    let service: Int

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let time = try container.decode(String.self)
        
        headsign = try container.decode(Int.self)
        service = try container.decode(Int.self)
        minutes = GTFSEntry.parse(time)
    }

    func encode(to encoder: Encoder) throws {
        var containerEncoder = encoder.unkeyedContainer()
        try containerEncoder.encode(String(format: "%02d:%02d", max(minutes, 0) / 60, max(minutes, 0) % 60))
        try containerEncoder.encode(headsign)
        try containerEncoder.encode(service)
    }

    private static func parse(_ time: String) -> Int {
        var parts: [Int] = []
        var current = 0
        var hasDigits = false
        
        for u in time.utf8 {
            if u == 58 {parts.append(current); current = 0; hasDigits = false}
            else if u >= 48 && u <= 57 {current = current * 10 + Int(u - 48); hasDigits = true}
            else { return -1 }
        }
        
        if hasDigits { parts.append(current) }
        
        return parts.count >= 2 ? parts[0] * 60 + parts[1] : -1
    }
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

actor GTFSStore {
    static let shared = GTFSStore()

    private var memory: [URL: (route: GTFSRoute, date: Date)] = [:]
    private var inflight: [URL: Task<GTFSRoute, Error>] = [:]
    private static let ttl: TimeInterval = 6 * 3600

    func route(from url: URL) async throws -> GTFSRoute {
        if let cached = memory[url], Date().timeIntervalSince(cached.date) < Self.ttl {return cached.route}
        if let running = inflight[url] {return try await running.value}

        let task = Task.detached(priority: .userInitiated) {
            try await GTFSStore.fetch(url)
        }
        inflight[url] = task
        defer { inflight[url] = nil }

        let route = try await task.value
        memory[url] = (route, Date())
        return route
    }

    private static func cacheFile(for url: URL) -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("gtfs_" + url.lastPathComponent)
    }

    private static func fetch(_ url: URL) async throws -> GTFSRoute {
        let file = cacheFile(for: url)
        let fm = FileManager.default

        if let modified = (try? fm.attributesOfItem(atPath: file.path))?[.modificationDate] as? Date,
           Date().timeIntervalSince(modified) < ttl,
           let data = try? Data(contentsOf: file),
           let route = try? JSONDecoder().decode(GTFSRoute.self, from: data) {
            return route
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            
            let route = try JSONDecoder().decode(GTFSRoute.self, from: data)
            try? data.write(to: file, options: .atomic)
            return route
        }
        catch {
            if let data = try? Data(contentsOf: file),
               let route = try? JSONDecoder().decode(GTFSRoute.self, from: data) {
                return route
            }
            throw error
        }
    }
}

struct GTFSHelper {
    static func load(from url: URL) async throws -> GTFSRoute {
        try await GTFSStore.shared.route(from: url)
    }
    
    static func getDepartures(for stopId: String, in route: GTFSRoute, limit: Int = 10, now: Date = Date()) -> [String: [Departure]]? {
        guard let stop = route.stops[stopId] else { return nil }

        let nowMins = minutes(of: now)
        let active = activeServiceIndices(in: route, on: now)
        guard !active.isEmpty else { return nil }

        var result: [String: [Departure]] = [:]

        for (directionId, entries) in stop.d {
            var seen = Set<Int>()
            var list: [Departure] = []

            for e in entries {
                guard e.minutes >= nowMins, active.contains(e.service) else { continue }
                guard seen.insert(e.minutes << 8 | e.headsign).inserted else { continue }

                let headsign = route.headsigns.indices.contains(e.headsign) ? route.headsigns[e.headsign] : "Direzione ignota"
                list.append(Departure(
                    time: String(format: "%02d:%02d", e.minutes / 60, e.minutes % 60),
                    headsign: headsign,
                    minutesFromNow: e.minutes - nowMins
                ))
            }

            list.sort { $0.minutesFromNow < $1.minutesFromNow }
            if !list.isEmpty { result[directionId] = Array(list.prefix(limit)) }
        }

        return result.isEmpty ? nil : result
    }
    
    private static func activeServiceIndices(in route: GTFSRoute, on date: Date) -> Set<Int> {
        let today = dateString(date)
        let valid = route.services.filter { $0.value.daytype?.lowercased() != "sconosciuto" }
        var active = Set(valid.compactMap { $0.value.dates.contains(today) ? Int($0.key) : nil })
        
        if active.isEmpty {
            let type = dayType(of: date)
            active = Set(valid.compactMap { $0.value.daytype?.lowercased() == type ? Int($0.key) : nil })
        }
        
        return active
    }

    private static var romeCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        
        return calendar
    }

    private static func dayType(of date: Date) -> String {
        let calendar = romeCalendar.dateComponents([.year, .month, .day, .weekday], from: date)
        guard let y = calendar.year, let m = calendar.month, let d = calendar.day, let weekend = calendar.weekday else { return "feriale" }

        if weekend == 1 || isHoliday(year: y, month: m, day: d) { return "festivo" }
        return weekend == 7 ? "sabato" : "feriale"
    }

    private static func isHoliday(year: Int, month: Int, day: Int) -> Bool {
        let fixed: Set<[Int]> = [[1,1],[6,1],[25,4],[1,5],[2,6],[15,8],[1,11],[7,12],[8,12],[25,12],[26,12]]
        if fixed.contains([month, day]) { return true }

        let varA = year % 19, b = year / 100, c = year % 100
        let varD = b / 4, e = b % 4, f = (b + 8) / 25, g = (b - f + 1) / 3
        let varH = (19 * varA + b - varD - g + 15) % 30
        let varI = c / 4, k = c % 4
        let varL = (32 + 2 * e + 2 * varI - varH - k) % 7
        let varMm = (varA + 11 * varH + 22 * varL) / 451
        let easterMonth = (varH + varL - 7 * varMm + 114) / 31
        let easterDay = (varH + varL - 7 * varMm + 114) % 31 + 1
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
        let formatter = DateFormatter()
        
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "Europe/Rome")
        
        return formatter.string(from: date)
    }

    private static func minutes(of date: Date) -> Int {
        let calendar = romeCalendar.dateComponents([.hour, .minute], from: date)
        
        return (calendar.hour ?? 0) * 60 + (calendar.minute ?? 0)
    }
}
