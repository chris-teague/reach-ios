//
//  AppDelegate.swift
//  Reach iOS
//
//  Created by Chris Teague on 26/05/2017.
//  Copyright © 2017 reinteractive. All rights reserved.
//

import UIKit
import Turbolinks
import APScheduledLocationManager
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, APScheduledLocationManagerDelegate {
    
    private var manager: APScheduledLocationManager!

    var window: UIWindow?
    var navigationController = UINavigationController()
    var session = Session()
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        window?.rootViewController = navigationController
        startApplication()
    }
    
    func startApplication() {
        session.delegate = self
        visit(URL: URL(string: "http://192.168.0.2:3000")!)
        manager = APScheduledLocationManager(delegate: self)
        trackLocation()
    }
    
    func trackLocation() {
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation(interval: 10, acceptableLocationAccuracy: 70)
    }
    
    func saveLocation(location: CLLocation) {
        var request = URLRequest(url: URL(string: "http://192.168.0.2:3000/locations/41030da5-3893-4f89-bd1d-4592bf5fb1f6")!)
        request.httpMethod = "POST"
        let postString = "location[lat]=" + String(format: "%.8f", location.coordinate.latitude) + "&location[lng]=" + String(format: "%.8f", location.coordinate.longitude) + "&_method=patch"
        
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }
        task.resume()

    }
    
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didFailWithError error: Error){
        
    }
    
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        NSLog(String(format: "%.4f", latestLocation.coordinate.latitude))
        saveLocation(location: latestLocation)
    }
    
    @nonobjc func scheduledLocationManager(_ manager: APScheduledLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }
    
    func visit(URL: URL) {
        let visitableViewController = VisitableViewController(url: URL)
        navigationController.pushViewController(visitableViewController, animated: true)
        session.visit(visitableViewController)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        NSLog(String(format: "%.4f", latestLocation.coordinate.latitude))
        
    }
    
}

extension AppDelegate: SessionDelegate {
    func session(_ session: Session, didProposeVisitToURL URL: URL, withAction action: Action) {
        visit(URL: URL)
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        navigationController.present(alert, animated: true, completion: nil)
    }
}
