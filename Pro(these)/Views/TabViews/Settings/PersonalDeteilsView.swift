//
//  PersonalDeteilsView.swift
//  Pro(these)
//
//  Created by Frederik Kohler on 27.04.23.
//

import SwiftUI

struct PersonalDeteilsView: View {
    var titel: String
    @StateObject var appConfig = AppConfig()
    var body: some View {
        ZStack {
            AppConfig().backgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20){
                    HStack{
                        Text(titel)
                            .foregroundColor(.white)
                    }
                    
                    SettingChangeName(image: "person.fill", info: "Ändere den Anzeigenamen.")
                    
                    SettingSetStepTarget()
                    
                    VStack(){
                       
                        VStack(alignment: .leading){
                            Text("Startseite")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppConfig().fontColor)
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                .padding(.bottom, 5)
                            
                            Picker("Startseite", selection: appConfig.$entrySite) {
                                ForEach(Tab.allCases, id: \.id) { tab in
                                    Text("\(tab.TabTitle())").tag(tab)
                                }
                            }
                            .pickerStyle(.navigationLink)
                            .tint(.white)
                           
                        }
                        .padding(.leading)
                        
                    }
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding(.all, 15.0)
                    .frame(maxWidth: .infinity)
                    .background(AppConfig().background.opacity(0.5))
                    .cornerRadius(10)
                }
                .padding(.top, 80)
            }
            .ignoresSafeArea()
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    func Link(buttonText: String, foregroundColor: Color) -> some View {
        HStack {
            HStack{
                Text(buttonText)
                    .foregroundColor(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppConfig().backgroundLabel)
            .overlay(
                   RoundedRectangle(cornerRadius: 10)
                   .stroke(lineWidth: 2)
                   .stroke(foregroundColor)
           )
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 50)
    }
}
