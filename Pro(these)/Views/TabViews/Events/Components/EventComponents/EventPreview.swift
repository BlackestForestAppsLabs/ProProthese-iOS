//
//  EventPreview.swift
//  Pro(these)
//
//  Created by Frederik Kohler on 04.05.23.
//

import SwiftUI

struct EventPreview: View {
    @EnvironmentObject private var appConfig: AppConfig
    @EnvironmentObject var eventManager: EventManager
    var item: Event
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: eventManager.getIcon(item.contact?.titel ?? "") )
                .font(.title)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 5){
                HStack{
                    Text(item.titel ?? "Unbekannter Titel")
                        .foregroundColor(appConfig.fontColor)
                        .font(.callout)
                }
                
                HStack{
                    Text(item.startDate ?? Date(), style: .date)
                        .foregroundColor(appConfig.fontLight)
                        .font(.caption2)
                    Text(item.startDate ?? Date(), style: .time)
                        .foregroundColor(appConfig.fontLight)
                        .font(.caption2)
                    
                    Text("(\(item.contact?.name ?? "Unbekannter Kontakt"))")
                        .foregroundColor(appConfig.fontLight)
                        .font(.caption2)
                }
            }
            
            Spacer()
        }
        .padding(10)
    }
}
