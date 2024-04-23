//
//  StepDiagram.swift
//  Pro-these-
//
//  Created by Frederik Kohler on 05.08.23.
//

import SwiftUI
import Charts

struct StepDiagram: View {
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var themeManager: ThemeManager
    
    @StateObject var healthStore = HealthStoreProvider()
    
    private var currentTheme: Theme {
        return self.themeManager.currentTheme()
    }

    @State var stepsData: [WeeklySteps] = []
    
    var lastWeekSteps: [WeeklySteps] {
        return self.stepsData.sorted(by: { $0.week.end > $1.week.end })
    }
    
    var maxSteps: Double {
        return self.stepsData.map({ $0.steps }).max() ?? 20.000
    }
    
    var scaleMaxSteps: Double {
        let weekTarget = AppConfig.shared.targetSteps * 7
        let value = self.maxSteps > Double(weekTarget) ? self.maxSteps : Double(weekTarget)
        return value
    }
    
    var weekTargetSteps: Double {
        return Double(AppConfig.shared.targetSteps * 7)
    }
    
    var avgSteps: Double {
        guard self.stepsData.count != 0 else {
            return 0
        }
        
        let count = self.stepsData.count
        let sum = self.stepsData.map({ return $0.steps }).reduce(0,+)
        
        return sum / Double(count)
    }
    
    var dates: [(id: UUID, date: Date)] {
        let dates = Date().extractLastDays(7)
        return dates.sorted(by: { $0.date > $1.date })
    }
    
    @State var ruleMarkTargetSteps: Double = 0
    
    @State var ruleMarkAvgSteps: Double = 0
    
    var weeks: Int
    
    var hightlightColor: Color
    
    func isDateInThisWeek(date: Date) -> Bool {
        return Calendar.current.isDateInThisWeek(date)
    }
    
    func calcAVG(totalSteps: Double, isInThisWeek: Bool) -> Double {
       guard !isInThisWeek else {
           return totalSteps / Double(Date().weekDayNumber) * 7
       }
    
       return totalSteps
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            HStack{
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weekly Steps Chart")
                        .font(.body.bold())
                        .foregroundColor(currentTheme.text)
                    
                    Text("Step history of the last 8 weeks.")
                        .font(.caption2)
                        .foregroundColor(currentTheme.text)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack{
                        Circle()
                            .frame(width: 6)
                            .foregroundStyle(currentTheme.hightlightColor)
                        
                        Text("Estimated steps")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(currentTheme.hightlightColor)
                    }
                    
                    HStack{
                        Text("- -")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(hightlightColor)
                        
                        Text("\( Int(weekTargetSteps) ) step goal")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(hightlightColor)
                    }
                    
                    HStack{
                        Text("- -")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(currentTheme.textGray)
                        
                        Text("⌀ \( Int(avgSteps) ) steps")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(currentTheme.textGray)
                    }
                }
            }
            
            HStack(spacing: 10) {
                
                Chart() {
                    RuleMark( y: .value("Weekly Target", ruleMarkTargetSteps) )
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(currentTheme.hightlightColor)
                    
                    RuleMark( y: .value("Weekly Avg Target", ruleMarkAvgSteps) )
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(currentTheme.textGray)
                    
                    ForEach(lastWeekSteps.indices, id: \.self) { int in
                        
                        let CalcedTotakStepsWeek = calcAVG( totalSteps: lastWeekSteps[int].steps, isInThisWeek: isDateInThisWeek(date: lastWeekSteps[int].week.start) )

                        AreaMark(
                            x: .value("Date", lastWeekSteps[int].week.start),
                            y: .value("Steps", CalcedTotakStepsWeek)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [
                                    currentTheme.hightlightColor.opacity(0.75),
                                    currentTheme.hightlightColor.opacity(0.1),
                                    currentTheme.hightlightColor.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom)
                        )
                        
                        let bool = Calendar.current.isDateInThisWeek(lastWeekSteps[int].week.end)
                        
                        LineMark(
                            x: .value("Date", lastWeekSteps[int].week.start),
                            y: .value("Steps", CalcedTotakStepsWeek)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(currentTheme.hightlightColor)
                        .lineStyle(.init(lineWidth: 3))
                        .symbol {
                            
                            if bool {
                                AnimatedCircle(size: 12, color: currentTheme.hightlightColor)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 12)
                                    
                                    Circle()
                                        .fill(currentTheme.hightlightColor)
                                        .frame(width: 6)
                                }
                            }
                            
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 12)
                                //let dateCheck = Calendar.current.isDate(lastWeekSteps[int].week.start, equalTo: Date(), toGranularity: .weekOfYear)
             
                                Circle()
                                    .fill(currentTheme.hightlightColor)
                                    .frame(width: 6)
                            }
                        }
                    }
                    
                }
                .chartYScale(range: .plotDimension(padding: 10))
                .chartYAxis {
                    let values = Array(stride(from: 0, to: scaleMaxSteps + 10000, by: 20000))
                    
                    AxisMarks(position: .leading, values: values) { axis in

                        AxisValueLabel() {
                            if let axis = axis.as(Double.self) {
                                Text("\( Int(axis) )")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .chartXScale(range: .plotDimension(padding: 20))
                .chartXAxis {
                    AxisMarks(preset: .aligned, position: .bottom, values: xValues) { date in
                        AxisValueLabel() {
                            if let d = date.as(Date.self) {
                                let startCurrentWeek = Date().startOfWeek()
                                let sameWeek = Calendar.current.isDate(d, inSameDayAs: startCurrentWeek)
                                Text(d.dateFormatte(date: "dd.MM", time: "").date)
                                    .font(.system(size: 6))
                                    .foregroundColor(sameWeek ? currentTheme.text : currentTheme.textGray)
                                    .fontWeight(sameWeek ? .bold : .regular)
                            }
                        }
                    }
                }
            }
        }
        .homeScrollCardStyle(currentTheme: currentTheme)
        .onAppear{
            resetData()
            loadData()
        }
        .onDisappear {
            resetData()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                resetData()
                loadData()
            }
        }
    }

    var xValues: [Date] {
        let dates = self.stepsData.map({ $0.week.start })
        return dates
    }
    
    func getSteps(weeks: Int) {
        
        let today = Date()
        
        let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: today)?.startWeek
        let endDate = today.endOfWeek!
        
        let dateInterval = DateInterval(start: startDate!, end: endDate)

        healthStore.queryAvgStepsforWeeks(dateInterval: dateInterval, type: .stepCount) { data in
            
            let converted = WeeklySteps(week: data.week, steps: data.totalSteps)

            DispatchQueue.main.async {
                if converted.week.start < Date() {
                    self.stepsData.append(converted)
                }
            }
        }
    }
    
    func resetData() {
        self.stepsData = []
        self.ruleMarkTargetSteps = 0
        self.ruleMarkAvgSteps = 0
    }
    
    func loadData() {
        getSteps(weeks: weeks)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut) {
                self.ruleMarkTargetSteps = self.weekTargetSteps
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeInOut) {
                self.ruleMarkAvgSteps = self.avgSteps
            }
        }
    }
}

struct StepDiagram_Previews: PreviewProvider {
    static var previews: some View {
        PainDiagram()
    }
}

struct WeeklySteps {
    var week: (start: Date, end: Date)
    var steps: Double
}
