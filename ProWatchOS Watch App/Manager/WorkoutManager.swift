//
//  WorkoutManager.swift
//  ProWatchOS Watch App
//
//  Created by Frederik Kohler on 10.05.23.
//

import Foundation
import HealthKit
import CoreLocation
import MapKit

class WorkoutManager: NSObject, ObservableObject {
    
    var workoutTypes: [HKWorkoutActivityType] = [.cycling, .running, .walking]
    
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            startWorkout(workoutType: selectedWorkout)
        }
    }
    
    @Published var showingSummaryView: Bool = false {
        didSet {
            // Sheet dismissed
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    
    let healthStore = HKHealthStore()
    var routeBuilder: HKWorkoutRouteBuilder?
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    var locationManager = CLLocationManager()
    
    // Request authorization to access Healthkit.
    func requestAuthorization() {
        
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWheelchair)!,
            HKObjectType.activitySummaryType(),
            HKSeriesType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        // Request authorization for those quantity types
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            // Handle error.
        }
        
        locationManager.requestAlwaysAuthorization()
    }
    
    
    // MARK: - State Control
    // The workout session state
    @Published var running = false
    
    func startWorkout(workoutType: HKWorkoutActivityType) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        setUpLocationManager()
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            return
        }
        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        
        session?.delegate = self
        builder?.delegate = self
        
        // Start the workout session and begin data collection.
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate, completion: { success, error in
            // The workout has started
        })
        
        self.running = true
        
    }
    
    func pause() {
        session?.pause()
    }
    
    func resume() {
        session?.resume()
    }
    
    func togglePuase() {
        if running == true {
            pause()
        } else {
            resume()
        }
    }
    
    func endWorkout() {
        session?.end()
        showingSummaryView = true
        selectedWorkout = nil
        //addRoute(to: workout ?? nil)
    }
    
    // MARK: - Workout Metrics
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var avgSpeed: Double = 0
    @Published var workout: HKWorkout?
    
    @Published var workoutRoute: HKWorkoutRoute?
    
    func retrieveStepCount(today:Date,completion: @escaping(Double?,Error?) -> ()) {

           let inputFormatter = DateFormatter()
           inputFormatter.dateFormat = "dd/MM/yyyy"
            
           //   Define the Step Quantity Type
           let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
            
            var components = DateComponents()
            components.day = 1
            components.second = -1
        
           //  Set the Predicates & Interval
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: today) , end: Calendar.current.date(byAdding: components, to: today)!, options: .strictStartDate)
           var interval = DateComponents()
           interval.day = 1
           //print(predicate)
            
           let query = HKStatisticsQuery(quantityType: stepsCount!, quantitySamplePredicate: predicate, options: HKStatisticsOptions.cumulativeSum) { (query, result, error) in
     
               var resultCount = 0.0
               if error != nil {
                   completion(nil, error)
                   return
               }
                
               if let myResult = result {
                   if let sum = myResult.sumQuantity() {
                       resultCount = sum.doubleValue(for: HKUnit.count())
                   }
                    
                   DispatchQueue.main.async {
                       completion(resultCount, nil)
                   }
               }
           }
           HKHealthStore().execute(query)
       }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {

   func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
       DispatchQueue.main.async {
           self.running = toState == .running
       }
       // Wait for the session to transition states before ending the builder.
       if toState == .ended {
           builder?.endCollection(withEnd: date, completion: { [self] success, error in

               self.builder?.finishWorkout(completion: { workout, error in
                   self.workout = workout
                   
                   if let workoutRoute = workout {
                     self.addRoute(workoutRoute)
                   }
               })
               
               
           })
       }
   }

   func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

   }

}

extension WorkoutManager: CLLocationManagerDelegate {
    public func setUpLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
          // Update every 13.5 meters in order to achieve updates no faster than once every 3sec.
          // This assumes runner is running at no faster than 6min/mile - 3.7min/km
        locationManager.distanceFilter = 5.0
          // Can use `kCLDistanceFilterNone` 👆 which will give more updates but still only at wide intervals.
        locationManager.activityType = .fitness
          /*
          from the docs
          ...if your app needs to receive location events while in the background,
          it must include the UIBackgroundModes key (with the location value) in its Info.plist file.
          */

        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: .local())

        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Filter the raw data, excluding anything greater than 50m accuracy
        let filteredLocations = locations.filter { isAccurateTo -> Bool in
            isAccurateTo.horizontalAccuracy <= 50
        }

        guard !filteredLocations.isEmpty else { return }

        routeBuilder?.insertRouteData(filteredLocations, completion: { success, error in
            if error != nil {
                // throw alert due to error in saving route.
                print("Error in \(#function) \(error?.localizedDescription ?? "Error in Route Builder")")
            }
        })
    }

    public func addRoute(_ workout: HKWorkout) {
        routeBuilder?.finishRoute(with: workout, metadata: nil, completion: { workoutRoute, error in
            if workoutRoute == nil {
                fatalError("error saving workout route")
            }
        })
    }
    
    /*
    public func getRouteFrom(workout: HKWorkout) {
            let mapDisplayAreaPadding = 1.3

            let runningObjectQuery = HKQuery.predicateForObjects(from: workout)

            let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in

                guard error == nil else {
                    fatalError("The initial query failed.")
                }
                // Make sure you have some route samples
                guard samples!.count > 0 else {
                    return
                }
                let route = samples?.first as! HKWorkoutRoute

                // Create the route query from HealthKit.
                let query = HKWorkoutRouteQuery(route: route) { (query, locationsOrNil, done, errorOrNil) in
                    // This block may be called multiple times.
                    if let error = errorOrNil {
                        print("Error \(error.localizedDescription)")
                        return
                    }

                    guard let locations = locationsOrNil else {
                        fatalError("*** NIL found in locations ***")
                    }

                    let latitudes = locations.map {
                        $0.coordinate.latitude
                    }
                    let longitudes = locations.map {
                        $0.coordinate.longitude
                    }

                    // Outline map region to display
                    guard let maxLat = latitudes.max() else { fatalError("Unable to get maxLat") }
                    guard let minLat = latitudes.min() else { return }
                    guard let maxLong = longitudes.max() else { return }
                    guard let minLong = longitudes.min() else { return }

                    if done {
                        let mapCenter = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLong + maxLong) / 2)
                        let mapSpan = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * mapDisplayAreaPadding,
                                                      longitudeDelta: (maxLong - minLong) * mapDisplayAreaPadding)

                        DispatchQueue.main.async {
                            // Push to main thread to drop dots on the map.
                            // Without this a warning will occur.
                            self.region = MKCoordinateRegion(center: mapCenter, span: mapSpan)
                            locations.forEach { (location) in
                                self.overlayRoute(at: location)
                            }
                        }
                    }
                    // stop the query by calling:
                    // store.stop(query)
                }
                healthStore.execute(query)
            }

            routeQuery.updateHandler = { (query, samples, deleted, anchor, error) in
                guard error == nil else {
                    // Handle any errors here.
                    fatalError("The update failed.")
                }
                // Process updates or additions here.
            }
            healthStore.execute(routeQuery)
        }
     */
}

   // MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {

   func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

   }

   func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
       for type in collectedTypes {
           guard let quantityType = type as? HKQuantityType else { return }
           let statistics = workoutBuilder.statistics(for: quantityType)

           // Update the published values.
           updateForStatistics(statistics)
       }
   }

   func updateForStatistics(_ statistics: HKStatistics?) {
       guard let statistics = statistics else {
           return
       }

       DispatchQueue.main.async {
           switch statistics.quantityType {
               case HKQuantityType.quantityType(forIdentifier: .heartRate):
                   let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                   self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                   self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0

               case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                   let energyUnit = HKUnit.kilocalorie()
                   self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0

               case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                   let meterUnit = HKUnit.meter()
                   self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0

               case HKQuantityType.quantityType(forIdentifier: .walkingSpeed), HKQuantityType.quantityType(forIdentifier: .walkingSpeed):
                       let meterUnit = HKUnit.meter().unitDivided(by: HKUnit.hour())
                       self.avgSpeed = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0

               default: return
           }
       }
   }

   func resetWorkout() {
       selectedWorkout = nil
       builder = nil
       session = nil
       workout = nil
       activeEnergy = 0
       averageHeartRate = 0
       heartRate = 0
       distance = 0
   }

}


struct ChartDataPacked: Identifiable {
    var id = UUID()
    var avg: Int
    var avgName: String
    var weekNr: Int
    var data: [ChartData]
    
}

struct ChartData: Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var value: Double
}

struct WorkoutDataPacked: Identifiable {
    var id = UUID()
    var avg: Int
    var avgName: String
    var weekNr: Int
    var data: [ChartData]
    
}

