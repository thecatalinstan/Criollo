//
//  AppDelegate.swift
//  CriolloiOSApp
//
//  Created by Cătălin Stan on 27/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

import UIKit
import Criollo

let PortNumber:UInt = 10781
let LogConnections:Bool = false
let LogRequests:Bool = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CRServerDelegate {

    var window:UIWindow?
    
    var server:CRHTTPServer!
    var baseURL:URL!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Create the server and add some handlers to do some work
        self.server = CRHTTPServer(delegate:self)

//        // Setup HTTPS
//        self.server.isSecure = true
//        
//        // Credentials: PKCS#12 Identity and password
//        self.server.identityPath = Bundle.main.path(forResource: "criollo_local", ofType: "p12")
//        self.server.password = "123456"
//        
//        // Credentials: PEM-encoded certificate and public key
//        self.server.certificatePath = Bundle.main.path(forResource: "cert", ofType: "pem")
//        self.server.certificateKeyPath = Bundle.main.path(forResource: "key", ofType: "pem")
//        
//        // Credentials: DER-encoded certificate and public key
//        self.server.certificatePath = Bundle.main.path(forResource: "cert", ofType: "der")
//        self.server.certificateKeyPath = Bundle.main.path(forResource: "key", ofType: "der")

        let bundle:Bundle! = Bundle.main

        // Add a header that says who we are :)
        self.server.add { (request, response, completionHandler) in
            response.setValue("\(bundle.bundleIdentifier!), \(bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String) build \(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String)", forHTTPHeaderField: "Server")

            if ( request.cookies?["session_cookie"] == nil ) {
                response.setCookie("session_cookie", value:NSUUID().uuidString, path:"/", expires:nil, domain:nil, secure:false)
            }
            response.setCookie("persistant_cookie", value:NSUUID().uuidString, path:"/", expires:NSDate.distantFuture, domain:nil, secure:false)

            completionHandler()
        }

        // Prints a simple hello world as text/plain
        self.server.add("/") { (request, response, completionHandler) in
            response.setValue("text/plain", forHTTPHeaderField: "Content-type")
            response.send("Hello World")
            completionHandler()
        }

        // Prints a hello world JSON object as application/json
        self.server.add("/json") { (request, response, completionHandler) in
            response.setValue("application/json charset=utf-8", forHTTPHeaderField: "Content-type")
            response.send(["status": true, "message": "Hello World"])
            completionHandler()
        }

        // Serve static files from "/Public" (relative to bundle)
        let staticFilePath:String = ((Bundle.main.resourcePath)! + "/Public")
        self.server.mount("/static", directoryAtPath:staticFilePath, options: CRStaticDirectoryServingOptions.followSymlinks)

        // Public files
        self.server.mount("/pub", directoryAtPath: "~", options: [CRStaticDirectoryServingOptions.followSymlinks, CRStaticDirectoryServingOptions.autoIndex] )

        // Redirecter
        self.server.get("/redirect") { (request, response, completionHandler) in
            let redirectURL:NSURL! = NSURL(string: request.query["redirect"]!)
            if ( redirectURL != nil ) {
                response.redirect(to: redirectURL as URL)
            }
            completionHandler()
        }

        // HTML view controller
        self.server.add("/controller", viewController: HelloWorldViewController.self, withNibName: String(describing: HelloWorldViewController.self), bundle: nil)

        // Multi route controller
        self.server.add("/api", controller:APIController.self)

        // Multi route view controller
        self.server.add("/multi", viewController: MultiRouteViewController.self, withNibName: String(describing: MultiRouteViewController.self), bundle: nil)

        self.server.add("/mime") { (request, response, completionHandler) in
            response.setValue("text/html", forHTTPHeaderField: "Content-type");
            response.write("<html>")
            response.write("<head>")
            response.write("<link rel=\"stylesheet\" href=\"/static/style.css\"/>")
            response.write("</head>")
            response.write("<body>")
            response.write("<h2>Mime</h2>")
            response.write("<form action=\"\" method=\"post\" enctype=\"multipart/form-data\">")
            response.write("<input type=\"hidden\" name=\"MAX_FILE_SIZE\" value=\"67108864\" />")
            response.write("<div><label>File: </label><input type=\"file\" name=\"file1\" /></div>")
            response.write("<div><label>Text: </label><input type=\"text\" name=\"text1\" /></div>")
            response.write("<div><label>Check: </label><input type=\"checkbox\" name=\"checkbox1\" value=\"1\" /></div>")
            response.write("<div><input type=\"submit\"/></div>")
            response.write("</form>")

            if ( request.method == CRHTTPMethod.post ) {
                if ( request.body != nil ) {
                    response.write("<h2>Request Body</h2>")
                    response.write("<pre>")
                    response.write(request.body!);
                    response.write("</pre>")
                }

                if ( request.files != nil ) {
                    response.write("<h2>Request Files</h2>")
                    response.write("<pre>")

                    let files:NSDictionary! = request.files as [String:CRUploadedFile]! as NSDictionary!
                    files.enumerateKeysAndObjects(options: [], using: { (key, file, stop) in
                        response.write("\(key): \((file as! CRUploadedFile).name)\n")
                    })
                    response.write("</pre>")
                }
            }

            response.finish()

        }

        // Placeholder path controller
        self.server.add("/blog/:year/:month/:slug", viewController: HelloWorldViewController.self, withNibName: String(describing: HelloWorldViewController.self), bundle: nil)

        // Regex path controller
        self.server.add("/f[a-z]{2}/:payload", viewController: HelloWorldViewController.self, withNibName: String(describing: HelloWorldViewController.self), bundle: nil)

        // Start listening
        var serverError:NSError?
        if ( self.server.startListening(&serverError, portNumber: PortNumber, interface: nil) ) {

            // Output some nice info to the console

            // Get server ip address
            let address:NSString! = SystemInfoHelper.ipAddress() as NSString!
            // Set the base url. This is only for logging
            self.baseURL = URL(string: "http\(self.server.isSecure ? "s" :"")://\(address!):\(PortNumber)")

            // Log the paths we can handle

            // Get the list of paths from the registered routes
            let paths = NSMutableSet()
            let routes:NSArray! = self.server.value(forKeyPath: "routes") as! NSArray
            for ( route ) in routes {
                let path:String? = (route as AnyObject).path
                if ( path != nil ) {
                    let pathURL:URL! = self.baseURL.appendingPathComponent(path!)
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

    func applicationWillResignActive(_ application: UIApplication) {

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {

    }

    func applicationDidBecomeActive(_ application: UIApplication) {

    }

    func applicationWillTerminate(_ application: UIApplication) {
        self.server.stopListening()
    }

    func server(_ server: CRServer, didAccept connection: CRConnection) {
        if ( LogConnections ) {
            NSLog(" * Accepted connection from \(connection.remoteAddress):\(connection.remotePort)")
        }
    }

    func server(_ server: CRServer, didClose connection: CRConnection) {
        if ( LogConnections ) {
            NSLog(" * Disconnected \(connection.remoteAddress):\(connection.remotePort)")
        }
    }


    func server(_ server: CRServer, didFinish request: CRRequest) {
        if ( LogRequests ) {
            let env:NSDictionary! = request.value(forKey: "env") as! NSDictionary
            NSLog(" * \(request.response!.connection!.remoteAddress) \(request.description) - \(request.response!.statusCode) - \(String(describing: env["HTTP_USER_AGENT"]))")
        }
        SystemInfoHelper.addRequest()
    }
}

