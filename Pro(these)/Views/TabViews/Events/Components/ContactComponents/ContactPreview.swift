//
//  ContactPreview.swift
//  Pro(these)
//
//  Created by Frederik Kohler on 04.05.23.
//

import SwiftUI

struct ContactPreview: View {
    @ EnvironmentObject var appConfig: AppConfig
    var icon: String
    var color: Color
    var name: String
    var titel: String
    var body: some View {
        HStack(spacing: 20) {
            Button(action: { print("phone") }, label: {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            })
            
            VStack(alignment: .leading, spacing: 5){
                Text(name)
                    .font(.callout)
                
                Text(titel)
                    .foregroundColor(appConfig.fontLight)
                    .font(.caption2)
            }
            
            Spacer()
        }
        .padding(10)
    }
}

