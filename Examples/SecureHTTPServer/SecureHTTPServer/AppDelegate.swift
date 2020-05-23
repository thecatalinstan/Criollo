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
    var server: CRHTTPServer?
    
    var interface = "127.0.0.1"
    var port = 10781
    var baseURL = URL(string: "http://127.0.0.1:10781/")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        self.interface = CSSystemInfoHelper.shared().ipAddress
        self.server = CRHTTPServer(delegate: self)
        
        // Setup HTTPS
        self.server?.isSecure = true
        
        // Secure with PEM certificate and key
        self.server?.certificatePath = Bundle.main.path(forResource: "SecureHTTPServer.bundle", ofType: "pem")
        self.server?.privateKeyPath = Bundle.main.path(forResource: "SecureHTTPServer.key", ofType: "pem")
        
        // Secure with PKCS#12 identity and password.
//        self.server?.identityPath = Bundle.main.path(forResource: "SecureHTTPServer", ofType: "p12")
//        self.server?.password = "password"
        
        self.server?.get("/", block: { (req, res, next) in
            res.send("Hello over HTTPS.")
        })
        
        // Start listening
        var error:NSError?
        if ( self.server?.startListening(&error, portNumber: UInt(self.port), interface: self.interface) )! {
            print("Started HTTPS server at: https://\(self.interface):\(self.port)/")
        } else {
            print("Failed to start HTTPS server. \(error!.localizedDescription)")
            print(error?.domain ?? "", error?.code ?? 0)
            print(error?.userInfo ?? "")
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        self.server?.stopListening()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        self.server?.startListening()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        self.server?.stopListening()
    }
    
    func serverDidStartListening(_ server: CRServer) {
        print ("Started server.")
    }
    
    func serverDidStopListening(_ server: CRServer) {
        print ("Server stopped.")
    }

}

