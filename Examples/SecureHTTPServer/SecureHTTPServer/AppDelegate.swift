//
//  AppDelegate.swift
//  SecureHTTPServer
//
//  Created by Cătălin Stan on 19/10/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

import UIKit
import Criollo
import CSSystemInfoHelper

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CRServerDelegate {

    var window: UIWindow?
    var server: CRHTTPServer
    
    var interface = "127.0.0.1"
    var port = 10781
    
    override init() {
        server = CRHTTPServer(delegate: nil)
        super.init()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Setup route
        server.get("/", block: { (req, res, next) in
            res.send("Hello over HTTP\(self.server.isSecure ? "S" : "").")
        })

        // Setup HTTPS with PKCS#12 identity and password.
        server.isSecure = true
        server.identityPath = Bundle.main.path(forResource: "SecureHTTPServer", ofType: "p12")
        server.password = "password"
        
        // Start listening
        interface = CSSystemInfoHelper.shared().ipAddress
        
        var error:NSError?
        if !server.startListening(&error, portNumber: UInt(port), interface: interface) {
            print("Failed to start HTTPS server. \(error!.localizedDescription)")
            print(error?.domain ?? "", error?.code ?? 0)
            print(error?.userInfo ?? "")
            return false
        }

        print("Started HTTPS server at: https://\(self.interface):\(self.port)/")
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        server.stopListening()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        server.startListening()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        server.stopListening()
    }
    
    func serverDidStartListening(_ server: CRServer) {
        print ("Started server.")
    }
    
    func serverDidStopListening(_ server: CRServer) {
        print ("Server stopped.")
    }

}

