//
//  GTFSRealtime.swift
//  LavoraMi
//
//  Created by Andrea Filice on 15/11/2026.
//

import Foundation

struct RTPrediction: Sendable {
    let delay: Int?
    let time: Int?
    let skipped: Bool
}

struct RTSnapshot: Sendable {
    let fetchedAt: Date
    let feedTimestamp: Date
    let predictions: [String: [String: RTPrediction]]
    let canceledTrips: Set<String>

    var isFresh: Bool {
        let now = Date()
        return now.timeIntervalSince(fetchedAt) < 60 && now.timeIntervalSince(feedTimestamp) < 180
    }

    func isCanceled(_ tripId: String) -> Bool { canceledTrips.contains(tripId) }
    func prediction(trip: String, stop: String) -> RTPrediction? { predictions[trip]?[stop] }
}

private struct RTFeed: Decodable {
    struct Header: Decodable { let timestamp: Int? }
    struct Entity: Decodable { let tripUpdate: TripUpdate? }
    
    struct TripUpdate: Decodable {
        struct Trip: Decodable {
            let tripId: String?
            let scheduleRelationship: String?
        }
        
        struct StopEvent: Decodable {
            let delay: Int?
            let time: Int?
        }
        
        struct StopTimeUpdate: Decodable {
            let stopId: String?
            let arrival: StopEvent?
            let departure: StopEvent?
            let scheduleRelationship: String?
        }
        
        let trip: Trip
        let stopTimeUpdate: [StopTimeUpdate]?
    }

    let header: Header
    let entity: [Entity]?
}

actor GTFSRealtimeStore {
    static let shared = GTFSRealtimeStore()

    private var cache: [URL: RTSnapshot] = [:]
    private var inflight: [URL: Task<RTSnapshot, Error>] = [:]
    private static let minInterval: TimeInterval = 10   // il feed viene emesso ~ogni 15s

    func snapshot(from url: URL) async throws -> RTSnapshot {
        if let cached = cache[url], Date().timeIntervalSince(cached.fetchedAt) < Self.minInterval { return cached }
        if let running = inflight[url] { return try await running.value }

        let task = Task { try await GTFSRealtimeStore.fetch(url) }
        inflight[url] = task
        defer { inflight[url] = nil }

        let snap = try await task.value
        cache[url] = snap
        return snap
    }

    private static func fetch(_ url: URL) async throws -> RTSnapshot {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("LavoraMi/iOS;info@lavorami.it", forHTTPHeaderField: "X-BusOne-Client")
        request.setValue("personal", forHTTPHeaderField: "X-BusOne-Use")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let feed = try decoder.decode(RTFeed.self, from: data)

        var predictions: [String: [String: RTPrediction]] = [:]
        var canceled = Set<String>()

        for entity in feed.entity ?? [] {
            guard let tu = entity.tripUpdate, let tripId = tu.trip.tripId else { continue }

            if tu.trip.scheduleRelationship == "CANCELED" {
                canceled.insert(tripId)
                continue
            }

            var perStop: [String: RTPrediction] = [:]
            for u in tu.stopTimeUpdate ?? [] {
                guard let stopId = u.stopId, u.scheduleRelationship != "NO_DATA" else { continue }
                let skipped = u.scheduleRelationship == "SKIPPED"
                let event = u.departure ?? u.arrival

                if skipped || event?.delay != nil || event?.time != nil {
                    perStop[stopId] = RTPrediction(delay: event?.delay, time: event?.time, skipped: skipped)
                }
            }
            if !perStop.isEmpty { predictions[tripId] = perStop }
        }

        return RTSnapshot(
            fetchedAt: Date(),
            feedTimestamp: Date(timeIntervalSince1970: TimeInterval(feed.header.timestamp ?? 0)),
            predictions: predictions,
            canceledTrips: canceled
        )
    }
}
