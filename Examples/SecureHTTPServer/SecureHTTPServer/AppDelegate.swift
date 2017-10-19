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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        self.interface = CSSystemInfoHelper.shared().ipAddress
        self.server = CRHTTPServer(delegate: self)
        
        // Setup HTTPS
        self.server?.isSecure = true
        
//        // Secure with PKCS#12 identity and password
//        self.server?.identityPath = Bundle.main.path(forResource: "SecureHTTPServer", ofType: "p12")
//        self.server?.password = "password"
        
        // Secure with PEM certificate and key
        self.server?.certificatePath = Bundle.main.path(forResource: "SecureHTTPServer.bundle", ofType: "pem")
        self.server?.certificateKeyPath = Bundle.main.path(forResource: "SecureHTTPServer.key", ofType: "pem")
        
        // Add some routes
        self.server?.get("/", block: { (req, res, next) in
            res.send("Hello world")
        })
        
        // Start listening
        var serverError:NSError?
        if ( self.server?.startListening(&serverError, portNumber: UInt(self.port), interface: self.interface) )! {
            
            // Output some nice info to the console
            
            // Get server ip address
            // Set the base url. This is only for logging
            self.baseURL = URL(string: "http\((self.server?.isSecure)! ? "s" :"")://\(self.interface):\(self.port)")
            
            // Log the paths we can handle
            // Get the list of paths from the registered routes
            let paths = NSMutableSet()
            let routes:NSArray! = self.server!.value(forKeyPath: "routes") as! NSArray
            for ( route ) in routes {
                let path:String? = (route as AnyObject).path
                if ( path != nil ) {
                    let pathURL:URL! = self.baseURL!.appendingPathComponent(path!)
                    paths.add(pathURL)
                }
            }
            
            let sortedPaths = paths.sortedArray(using: [NSSortDescriptor(key:"absoluteString", ascending:true)] )
            print("Available paths are:")
            for ( path ) in sortedPaths {
                print(" * \(path)")
            }
        } else {
            print("Failed to start HTTP server. \(serverError!.localizedDescription)")
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
        print ("Server stop listening.")
    }

}

