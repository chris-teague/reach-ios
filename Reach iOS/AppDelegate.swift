//
//  AppDelegate.swift
//  Reach iOS
//
//  Created by Chris Teague on 26/05/2017.
//  Copyright © 2017 reinteractive. All rights reserved.
//

import UIKit
import Turbolinks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
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
    }
    
    func visit(URL: URL) {
        let visitableViewController = VisitableViewController(url: URL)
        navigationController.pushViewController(visitableViewController, animated: true)
        session.visit(visitableViewController)
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
