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
import Strongbox
import WebKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, APScheduledLocationManagerDelegate {
    
    private var manager: APScheduledLocationManager!

    let APP_HOST = "https://pdd-reach.herokuapp.com"
    
    var window: UIWindow?
    var navigationController = UINavigationController()
    var session = Session()
    var userID = ""
    var userToken = ""
    var lastURL = URL(string: "https://pdd-reach.herokuapp.com")
    var setupUserRetried = false
    let sb = Strongbox()

    func applicationDidFinishLaunching(_ application: UIApplication) {
        application.registerForRemoteNotifications()
        window?.rootViewController = navigationController
        startApplication()
    }
    
    func startApplication() {
        session.delegate = self
        visit(URL: URL(string: APP_HOST)!)
        manager = APScheduledLocationManager(delegate: self)
        
        handleUser()
        trackLocation()
    }
    
    func handleUser() {
        if let id = sb.unarchive(objectForKey: "user-id") as? String, let token = sb.unarchive(objectForKey: "user-token") as? String {
            userID = id
            userToken = token
            visit(URL: lastURL!)
        } else {
            setupUser()
        }
    }
    
    func setupUser() {
        var request = URLRequest(url: URL(string: APP_HOST + "/users.json")!)
        request.httpMethod = "POST"
        let postString = "user[client]=ios"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 201 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            if self.setupUserRetried {
                print("Setting up user retried")
            }
            let responseString = String(data: data, encoding: .utf8)
            self.saveUserCredentials(jsonString: responseString!)
        }
        task.resume()
    }
    
    func saveUserCredentials(jsonString: String) {
        let data = jsonString.data(using: String.Encoding.utf8)!
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] {
                if let id = jsonObject["id"] as? String, let token = jsonObject["token"] as? String {
                    saveUserCreds(id: id, token: token)
                }
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
    func saveUserCreds(id: String, token: String) {
        sb.archive(token, key: "user-token") // true
        sb.archive(id, key: "user-id") // true
        userID = id
        userToken = token
        DispatchQueue.main.async {
            self.visit(URL: self.lastURL!)
        }
    }
    
    
    func trackLocation() {
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation(interval: 5, acceptableLocationAccuracy: 70)
    }
    
    func saveLocation(location: CLLocation) {
        guard !userID.isEmpty, !userToken.isEmpty else {
            return
        }
        
        var request = URLRequest(url: URL(string: APP_HOST + "/users/"+userID+".json")!)
        request.httpMethod = "POST"
        let postString = "user[lat]=" + String(format: "%.8f", location.coordinate.latitude) + "&user[lng]=" + String(format: "%.8f", location.coordinate.longitude) + "&_method=patch"
        
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 404 && !self.setupUserRetried {
                self.setupUserRetried = true
                self.setupUser()
            }

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
        }
        task.resume()

    }
    
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didFailWithError error: Error){
        
    }
    
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latestLocation: CLLocation = locations[locations.count - 1]
        saveLocation(location: latestLocation)
    }
    
    @nonobjc func scheduledLocationManager(_ manager: APScheduledLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }
    
    func visit(URL: URL) {
        let visitableViewController = VisitableViewController(url: URLWithToken(rawURL: URL))
        
        navigationController.pushViewController(visitableViewController, animated: true)
        
        let dirUrl = URL.deletingLastPathComponent()
        print(dirUrl.path)
        if(dirUrl.path == "/locations") {
            UIPasteboard.general.string = URL.absoluteString
        }
        
        lastURL = URL
        session.visit(visitableViewController)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: CLLocation = locations[locations.count - 1]
    }
    
    private func URLWithToken(rawURL: URL)-> URL {
        if userToken.isEmpty {
            return rawURL
        } else {
            var finalURL = "\(rawURL)"
            if finalURL.range(of: "?") == nil {
                finalURL = "\(finalURL)?userToken=\(userToken)"
            } else {
                finalURL = "\(finalURL)&userToken=\(userToken)"
            }
            return URL(string: finalURL)!
        }
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



