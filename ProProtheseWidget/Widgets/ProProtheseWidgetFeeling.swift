//
//  ProProtheseWidget.swift
//  ProProtheseWidget
//
//  Created by Frederik Kohler on 13.06.23.
//

import WidgetKit
import SwiftUI

struct FeelingProvider: TimelineProvider {
    func placeholder(in context: Context) -> FeelingSimpleEntry {
        FeelingSimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (FeelingSimpleEntry) -> ()) {
        let entry = FeelingSimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [FeelingSimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = FeelingSimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct FeelingSimpleEntry: TimelineEntry {
    let date: Date
}

struct ProProtheseWidgetFeelingEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: FeelingProvider.Entry

    var body: some View {
        Link(destination: URL(string: "ProProthese://feeling")!) {
            ZStack {
                
                LinearGradient(colors: [Color(red: 32/255, green: 40/255, blue: 63/255), Color(red: 4/255, green: 5/255, blue: 8/255)], startPoint: .top, endPoint: .bottom)
                
                switch widgetFamily {
                case .systemSmall:
                    GeometryReader { screen in
                        
                        let width = screen.size.width / 2
                        
                        VStack {
                            
                            Text("Hey, Wie fühlst du dich heute?")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                            
                            ZStack{
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: width, height: width)
                                
                                Image(systemName: "plus")
                                    .font(.title.bold())
                                    .foregroundColor(.yellow)
                            }
                        }
                        .frame(width: screen.size.width, height: screen.size.height)
                        
                    }
                case .systemLarge:
                    VStack {
                        Text(entry.date, style: .time)
                        Text("Large Widget")
                    }
                default:
                    VStack {
                        Text(entry.date, style: .time)
                        Text("Default")
                    }
                }
            }.widgetURL(URL(string: "ProProthese://feeling"))
        }
       
    }
}

struct ProProtheseWidgetFeeling: Widget {
    let kind: String = "ProProtheseWidgetFeeling"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FeelingProvider()) { entry in
            ProProtheseWidgetFeelingEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Wie geht es dir?")
        .description("Trage es schnell ein wie es mit der Prothese heute geht.")
    }
}

struct ProProtheseWidgetFeeling_Previews: PreviewProvider {
    static var previews: some View {
        ProProtheseWidgetFeelingEntryView(entry: FeelingSimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
