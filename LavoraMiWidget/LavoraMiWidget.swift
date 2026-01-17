//
//  LavoraMiWidget.swift
//  LavoraMiWidget
//
//  Created by Andrea Filice on 17/01/26.
//

import WidgetKit
import SwiftUI

struct WorkEntry: TimelineEntry {
    let date: Date
    let linea: SavedLine?
    let stato: String
}

struct Provider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (WorkEntry) -> Void) {
        let entry = WorkEntry(date: Date(), linea: SavedLine(id: "0", name: "M1", longName: "Metro", worksNow: 0, worksScheduled: 2), stato: "Anteprima")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkEntry>) -> Void) {
        let lineChoosed = DataManager.shared.getSavedLine()
        
        let isValid = (lineChoosed == nil || lineChoosed?.id == "empty")
        let entry = WorkEntry(date: Date(), linea: lineChoosed, stato: (isValid) ? "empty" : "def")
        
        //MARK: WIDGET UPDATES
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    func placeholder(in context: Context) -> WorkEntry {
        WorkEntry(date: Date(), linea: SavedLine(id: "empty", name: "1", longName: "2<", worksNow: 0, worksScheduled: 0), stato: "empty")
    }
}

struct LavoraMiWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        if(entry.stato == "empty") {
            VStack(alignment: .leading) {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                Spacer()
                Text("Seleziona una linea da mostrare nel Widget.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        else{
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.linea?.name ?? "err")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(getColor(for: entry.linea?.name ?? "no"))
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Image(systemName: "tram.fill")
                        .foregroundColor(.secondary)
                }
                Text("\(entry.linea?.longName ?? "") \(entry.linea?.name ?? "no")")
                    .bold()
                    .font(.system(size: 15))
                Divider()
                HStack(spacing: 2) {
                    Label("IN CORSO", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(entry.linea?.worksNow ?? 0)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                }
                HStack(spacing: 2) {
                    Label("PROGRAMMATI", systemImage: "calendar")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Spacer()
                    Text("\(entry.linea?.worksScheduled ?? 0)")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

func getColor(for line: String) -> Color {
    switch line {
        //SUBURBAN LINES
        case "S1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "S2": return Color(red: 0, green: 152/255, blue: 121/255)
        case "S3": return Color(red: 169/255, green: 10/255, blue: 46/255)
        case "S4": return Color(red: 131/255, green: 187/255, blue: 38/255)
        case "S5": return Color(red: 243/255, green: 145/255, blue: 35/255)
        case "S6": return Color(red: 246/255, green: 210/255, blue: 0)
        case "S7": return Color(red: 229/255, green: 0, blue: 113/255)
        case "S8": return Color(red: 246/255, green: 182/255, blue: 182/255)
        case "S9": return Color(red: 162/255, green: 51/255, blue: 138/255)
        case "S11": return Color(red: 165/255, green: 147/255, blue: 198/255)
        case "S12": return .black
        case "S13": return Color(red: 167/255, green: 109/255, blue: 17/255)
        case "S19": return Color(red: 102/255, green: 13/255, blue: 54/255)
        case "S31": return .gray
        
        //TILO LINES
        case "S10": return Color(red: 228/255, green: 35/255, blue: 19/255)
        case "S30": return Color(red: 0, green: 166/255, blue: 81/255)
        case "S40": return Color(red: 117/255, green: 188/255, blue: 118/255)
        case "S50": return Color(red: 131/255, green: 76/255, blue: 22/255)
        
        //METRO LINES
        case "M1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "M2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "M3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "M4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "M5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        
        //BUS LINES
        case _ where line.contains("z") || line.contains("k"):
            return Color(red: 28/255, green: 28/255, blue: 1)
        case _ where line.contains("Filobus"):
            return Color(red: 101/255, green: 179/255, blue: 46/255)
        case _ where line.contains("P") && !(line.contains("MXP")):
            return Color(red: 69/255, green: 56/255, blue: 0)
        
        //OTHER LINES
        case "MXP": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP1": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP2": return Color(red: 140/255, green: 0, blue: 118/255)
        case "AV": return .red
        case "Aereoporto": return .black
        case _ where line.contains("R"):
                return Color.blue
            
        default: return Color.gray
    }
}

struct LavoraMiWidget: Widget {
    let kind: String = "LavoraMiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                LavoraMiWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LavoraMiWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Stato Linea")
        .description("Mostra la linea scelta nell'App.")
    }
}

#Preview(as: .systemSmall) {
    LavoraMiWidget()
} timeline: {
    WorkEntry(date: Date(), linea: SavedLine(id: "M1", name: "M1", longName: "Metro", worksNow: 1, worksScheduled: 2), stato: "empty")
}
