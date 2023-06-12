//
//  ChartView.swift
//  ProWatchOS Watch App
//
//  Created by Frederik Kohler on 29.05.23.
//

import SwiftUI
import Charts 
import HealthKit

struct ChartView: View {
    @EnvironmentObject var vm: WorkoutManager
    @Environment(\.scenePhase) var scenePhase
    
    @State var currentDate = Date()
    @State var currentSteps: Int = 0
    @State var currentWeek: [DateValue] = []
    
    @State var selectedAvgSteps: Double = 0
    
    @State var Steps: [ChartData] = []

    private var avg: Int {
        if self.Steps.count != 0 {
            return self.Steps.map{ Int($0.value) }.reduce(0, +) / self.Steps.count
        } else {
            return 0
        }
        
    }

    var body: some View {
        GeometryReader { geo in
            
            VStack {
              
                HStack{
                    Image("prothesis")
                        .imageScale(.large)
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("\( Int(currentSteps) ) Schritte")
                        .font(.title3)
                        .padding()
                }
                
                Spacer()
                
                chart(geo: geo.size)
                    .padding(.bottom)
                    .frame(width: .infinity, height: .infinity)
            }
            .frame(width: .infinity, height: .infinity)
            
        }
        // Set Date, Extrakt last 7 Days and set showing Steps to the last StepCount (Today)
        .onAppear{
            DispatchQueue.main.async {
                currentDate = Date()
                currentWeek = extractWeekByDate(currentDate: currentDate)
                currentSteps = Int(Steps.last?.value ?? -1)
            }
        }
        // Change the Selected Day, search steps for today and update selected StepCount
        .onChange(of: currentDate, perform: { newDate in
            currentSteps = Int(Steps.first(where: { Calendar.current.isDate($0.date, inSameDayAs: newDate) })?.value ?? -2)
        })
        // Set Date, Extrakt last 7 Days and set showing Steps to the last StepCount (Today)
        .onChange(of: scenePhase, perform: { newPhase in
           if newPhase == .active {
                currentDate = Date()
                currentWeek = extractWeekByDate(currentDate: currentDate)
                currentSteps = Int(Steps.last?.value ?? -1)
            }
        })
    }
    
    func extractWeekByDate(currentDate: Date) -> [DateValue] {
        var ArrWeek: [DateValue] = []

        for day in 0..<7 {
            if let weekDay = Calendar.current.date(byAdding: .day, value: -day, to: currentDate) {
                let date =  Calendar.current.date(byAdding: .hour, value: 2, to: weekDay)
                ArrWeek.append( DateValue(date: date!))
            }
        }
        
        getSteps(ArrWeek)
        
        return ArrWeek
    }
    
    func getSteps(_ dates: [DateValue])  {
         
        dates.map({ day in
            let startDate = Calendar.current.startOfDay(for: day.date)

            vm.retrieveStepCount(today: startDate) { (steps, error) in
                self.Steps.append(ChartData(date: day.date, value: steps ?? 0))
            }
            
        })
       
    }
    
    func checkTargetSteps(steps: Double) -> (Bool, Int) {
        let percent = steps / Double(AppConfig.shared.targetSteps) * 100
        let bool = percent >= 100 ? true : false
        return (bool, Int(percent))
    }
    
    func seperator(_ fv: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0;
        
        return formatter.string(from: NSNumber(value: fv))!
    }
    
    
    @ViewBuilder
    func chart(geo: CGSize) -> some View {
        Chart(currentWeek, id: \.self){ day in
            
            RuleMark(y: .value("Durchschnitt", avg ) )
                .foregroundStyle(.yellow)
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [8]))
                .annotation(position: .automatic, alignment: .leading, spacing: 10) {
                    Text("⌀ \(avg) Steps")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                }

            let formDate = Calendar.current.date(byAdding: .hour, value: 12, to: day.date)!
            
            if let wk = Steps.first(where: { return Calendar.current.isDate($0.date, equalTo: day.date, toGranularity: .day) }) {
                
                AreaMark(
                    x: .value("Dates", formDate),
                    y: .value("Steps", wk.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Color(red: 167/255, green: 178/255, blue: 210/255).opacity(0),
                            Color(red: 167/255, green: 178/255, blue: 210/255).opacity(0.1),
                            Color(red: 167/255, green: 178/255, blue: 210/255).opacity(0.5)
                        ],
                        startPoint: .bottom,
                        endPoint: .top)
                )
                
                LineMark(
                    x: .value("Dates", formDate),
                    y: .value("Steps", wk.value)
                )
                .interpolationMethod(.catmullRom)
                .symbol {
                    VStack(spacing: 5){
                        if Calendar.current.isDate(formDate, inSameDayAs: currentDate) {
                            Text("\( currentSteps )").font(.caption2).foregroundColor(.white)
                        } else {
                            Text("").font(.caption2)
                        }
                        
                        ZStack{
                            // only show when date is not in future
                            if Calendar.current.isDate(formDate, inSameDayAs: currentDate) {
                                // show wenn selected date is same as item
                                let (targetReached, _) = checkTargetSteps(steps: 0)
                                
                                Image(systemName: targetReached ? "hand.thumbsup.fill" : "circle.fill")
                                    .scaleEffect(Calendar.current.isDate(formDate, inSameDayAs: currentDate) && targetReached ? 2.1 : targetReached ? 1.6 : 0.7)
                                    .foregroundColor(targetReached ? .yellow : .white )
                                    .shadow(color: .black, radius: 10)
                                
                                if Calendar.current.isDate(formDate, inSameDayAs: currentDate) {
                                    if !targetReached {
                                        Circle()
                                        .fill(targetReached ? .white.opacity(0) : .white.opacity(0.5))
                                        .frame(width: 20)
                                        .shadow(radius: 2)
                                    }
                                }
                            }
                        }
                    }
                    .offset(y: -10)
                }
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            .yellow.opacity(0.5),
                            .white.opacity(1)
                        ],
                        startPoint: .bottom,
                        endPoint: .top)
                )
                .lineStyle(.init(lineWidth: 5))
                
            }

        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 8))
            
        }
        .chartYAxis {
            let max = Steps.map { $0.value }.max()

            let test = Array(stride(from: 0, to: max ?? 20000, by: 2500))
            
            AxisMarks(position: .trailing, values: test) { axis in
                AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.3, dash: [10]))

                AxisValueLabel() {
                    if let axis = axis.as(Int.self) {
                        Text("\(axis)")
                            .font(.system(size: 6))
                    }
                }
            }
        }
        .chartOverlay { proxy in
          GeometryReader { geometry in
            Rectangle().fill(.clear).contentShape(Rectangle())
              .onTapGesture { location in
                  let origin = geometry[proxy.plotAreaFrame].origin
                  let location = CGPoint(
                      x: location.x - origin.x,
                      y: location.y - origin.y
                  )
                  
                  let (date, _) = proxy.value(at: location, as: (Date, Double).self)!

                  withAnimation {
                      // only update when the date is not in future
                      if date < Date() || Calendar.current.isDate(date, inSameDayAs: currentDate) {
                          currentDate = date
                      }
                  }
              }
              
           }
        }
        .chartYScale(range: .plotDimension(padding: 10))
        .chartXScale(range: .plotDimension(padding: 10))
        .padding(.bottom)
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView()
    }
}

struct DateValue: Identifiable, Hashable {
    let id = UUID()
    let date: Date
}
