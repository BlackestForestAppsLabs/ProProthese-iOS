//
//  ProProtheseWidget.swift
//  ProProtheseWidget
//
//  Created by Frederik Kohler on 13.06.23.
//

import WidgetKit
import SwiftUI
import Foundation
import CoreData

struct ShowFeelingProvider: TimelineProvider {
    
    let url = URL(string: "ProProthese://showFeeling")
    
    var nextUpdate: Date {
        return Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    }
    
    func placeholder(in context: Context) -> ShowFeelingSimpleEntry {
        ShowFeelingSimpleEntry(date: Date(), nextUpdate: Date(), url: url, feelings: try! fetchFeelings())
    }

    func getSnapshot(in context: Context, completion: @escaping (ShowFeelingSimpleEntry) -> ()) {
        let entry = ShowFeelingSimpleEntry(date: Date(), nextUpdate: Date(), url: url, feelings: try! fetchFeelings())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entrie = ShowFeelingSimpleEntry(date: Date(), nextUpdate: nextUpdate, url: url, feelings: try! fetchFeelings())
        
        let timeline = Timeline(entries: [entrie], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchFeelings() throws -> [Feeling]{
        let context = PersistenceController.shared.container.viewContext
        
        let request = Feeling.fetchRequest()
        let result = try context.fetch(request)
        
        return result
    }
}

struct ShowFeelingSimpleEntry: TimelineEntry {
    let date: Date
    let nextUpdate: Date
    let url: URL?
    let feelings: [Feeling]
}

struct ProProtheseWidgetShowFeelingEntryView : View {

    private var currentTheme: Theme {
        return ThemeManager().currentTheme()
    }
    
    @Environment(\.widgetFamily) var widgetFamily
    var entry: ShowFeelingProvider.Entry

    private let debug = true
    
    @State var week: [(weekday: String, date: Date)] = []
    
    var isFeelingToday: Bool {
        
        let today = Date()
        
        let entry = self.entry.feelings.first(where: { return isSameDay(d1: $0.date ?? Date(), d2: today) })
        
        return (entry != nil) ? true : false
    }
    
    var body: some View {
        Link(destination: URL(string: isFeelingToday ? "ProProthese://showFeeling" : "ProProthese://addFeeling")!) {
            ZStack {
                currentTheme.gradientBackground(nil)
                
                switch widgetFamily {
                    case .systemSmall:
                        ViewThatFits {
                            
                            VStack(alignment: .center, spacing: 5){
                                Text("Hey, how are you feeling today?")
                                    .font(.caption.bold())
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(currentTheme.hightlightColor)
                                
                                Spacer()
                                
                                DayButton(convertDateToDayNames(entry.date), entry.date, entry.feelings)

                            }
                            
                        }
                        .padding()
                        .widgetURL(URL(string: isFeelingToday ? "ProProthese://showFeeling" : "addFeeling"))
                        
                    case .systemMedium:
                        ViewThatFits {
                            
                            VStack(spacing: 5){
                                
                                let date = entry.date.dateFormatte(date: "dd.MM.YYYY", time: "").date
                                let weekday = convertDateToDayNames(entry.date)
                                
                                HStack {
                                    Text("Pro Prothese")
                                        .foregroundColor(currentTheme.hightlightColor)
                                        .font(.caption.bold())
                                    
                                    Spacer()
                                    
                                    Text("\(weekday), \(date)")
                                        .font(.caption.bold())
                                        .foregroundColor(currentTheme.hightlightColor)
                                }
                                
                                HStack{
                                    Text("This is how you feel today with your prosthesis.")
                                        .font(.caption2)
                                        .foregroundColor(currentTheme.textGray)
                                    
                                    Spacer()
                                }
                                
                                Spacer()
                                
                                HStack{
                                    ForEach(extractWeekByDate(currentDate: Date()), id: \.date) { weekday, date in
                                        DayButton(weekday, date, entry.feelings)
                                    }
                                }
                            }
                            
                        }
                        .padding()
                        .widgetURL(URL(string: isFeelingToday ? "ProProthese://showFeeling" : "addFeeling"))
                    default:
                        VStack {
                            Text(entry.date, style: .time)
                                .font(.caption.bold())
                            Text("Default")
                        }
                }
            }
        }
        .onAppear{
           week = extractWeekByDate(currentDate: Date())
        }
        .widgetBackground(Color.clear)

    }
    
    @ViewBuilder // MARK: - Calendar Day Circle
    func DayButton(_ weekday: String, _ date: Date, _ feelings: [Feeling]) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text("\(weekday)")
                .font(.caption2)
                .foregroundColor(.gray)
            
            ZStack {
                
                if let _ = feelings.first(where: { return isSameDay(d1: $0.date ?? Date(), d2: date) }) {
                    
                    let fe = feelings.map( { return  isSameDay(d1: $0.date ?? Date(), d2: date) ? Int( trimFeelings(string: $0.name  ?? "") ) : nil } )
                    if fe.count > 0 {
                        
                        let avg:Int = fe.compactMap{ $0 }.reduce(0, +) / fe.compactMap{ $0 }.count
                        
                        Image("chart_feeling_" + String(avg) )
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.gray)
                            .imageScale(.large)
                            .clipShape(Circle())
                            
                    }
                    
                } else {
                    Circle()
                        .fill(currentTheme.text.opacity(0.1))
                        .scaledToFit()
                        .clipShape(Circle())
                    
                    Image(systemName: "plus")
                        .foregroundColor(currentTheme.hightlightColor)
                        .widgetURL(URL(string: "ProProthese://addFeeling"))
                }
                
            }
            .background(.gray.opacity(0.1))
            .cornerRadius(500)
            
            
            Text(date.dateFormatte(date: "dd", time: "").date)
                .font(.caption2)
                .foregroundColor(currentTheme.textGray)
        }
    }
    
    func extractWeekByDate(currentDate: Date) -> [(weekday: String, date: Date)] {
        var ArrWeek: [(weekday: String, date: Date)] = []
        
        let firstDayOfWeek = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: currentDate).date!
        
        for day in 0..<7 {
            if let weekDay = Calendar.current.date(byAdding: .day, value: day, to: firstDayOfWeek) {
                let date =  Calendar.current.date(byAdding: .hour, value: 2, to: weekDay)
                ArrWeek.append( (weekday: convertDateToDayNames(date!) , date: date!) )
            }
        }
        
        return ArrWeek
    }

    func convertDateToDayNames(_ date: Date) -> String {
       return date.dateFormatte(date: "EE", time: "HH:mm").date
    }
    
    func isSameDay(d1: Date, d2: Date) -> Bool {
       return Calendar.current.isDate(d1, inSameDayAs: d2)
    }
    
    func trimFeelings (string:String) -> String {
        return string.trimmingCharacters(in: ["_", "f", "e" ,"l","i","n","g"])
    }
    
}

struct ProProtheseWidgetShowFeeling: Widget {
    let kind: String = "ProProtheseWidgetShowFeeling"
    
    let supportedFamilies:[WidgetFamily] = [
        .systemSmall,
        .systemMedium
    ]
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShowFeelingProvider()) { entry in
            ProProtheseWidgetShowFeelingEntryView(entry: entry)
        }
        .supportedFamilies(supportedFamilies)
        .configurationDisplayName("Feelings at a glance")
        .description("See your feelings")
        .contentMarginsDisabled()
        
    }
    
    func trimCharater (string:String) -> String {
        return string.trimmingCharacters(in: ["("," ",":","\"",")"])
    }
    
    
    
    func deletingPrefix(input: String, prefix: String) -> String {
        guard input.hasPrefix(prefix) else { return input }
        return String(input.dropFirst(prefix.count))
    }
}
