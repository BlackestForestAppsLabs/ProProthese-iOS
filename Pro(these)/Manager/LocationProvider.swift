//
//  LocationManager.swift
//  Pro(these)
//
//  Created by Frederik Kohler on 26.04.23.

import CoreLocation
import CoreLocationUI
import MapKit

class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static var shared = LocationProvider()
    
    let manager = CLLocationManager()

    @Published var location: CLLocationCoordinate2D?
    @Published var region: MKCoordinateRegion
 
    
    override init() {
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.62369790077433, longitude: 8.22015741916841),
            latitudinalMeters: 750, longitudinalMeters: 750
        )
        
        super.init()
        self.manager.delegate = self
        manager.requestAlwaysAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location!.latitude, longitude: location!.longitude),
            latitudinalMeters: 750, longitudinalMeters: 750
        )
    }
    
    func getLocation() -> MKCoordinateRegion {
        startMonitoring()
        
        let region = updateRegion(location: location)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.stopMonitoring()
        })
        
        return region
    }
    
    func updateRegion(location: CLLocationCoordinate2D?) -> MKCoordinateRegion {
        guard location != nil else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 47.62369790077433, longitude: 8.22015741916841),
                latitudinalMeters: 750, longitudinalMeters: 750
            )
        }
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location!.latitude, longitude: location!.longitude),
            latitudinalMeters: 750, longitudinalMeters: 750
        )
        return region
    }
    
    func startMonitoring() {
        manager.startMonitoringSignificantLocationChanges()
        manager.startUpdatingLocation()
    }
    
    func stopMonitoring() {
        manager.stopMonitoringSignificantLocationChanges()
        manager.stopUpdatingLocation()
    }
}

