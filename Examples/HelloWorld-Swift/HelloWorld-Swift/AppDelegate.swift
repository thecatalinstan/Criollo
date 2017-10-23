//
//  AppDelegate.swift
//  HelloWorld-Swift
//
//  Created by Cătălin Stan on 11/16/15.
//
//

import Criollo
import CSSystemInfoHelper

let PortNumber:UInt = 10781
let LogConnections:Bool = false
let LogRequests:Bool = true

class AppDelegate: NSObject, CRApplicationDelegate, CRServerDelegate {

    var server:CRServer!
    var baseURL:NSURL!
    var app:CRApplication!
    
    func applicationDidFinishLaunching(_ notification: Notification) {

        self.app = CRApp as! CRApplication

        // Create the server and add some handlers to do some work
        self.server = CRHTTPServer(delegate:self)

        let bundle:Bundle! = Bundle.main

        // Add a header that says who we are :)
        self.server.add { (request, response, completionHandler) -> Void in
            response.setValue("\(bundle.bundleIdentifier!), \(bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String) build \(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String)", forHTTPHeaderField: "Server")

            if ( request.cookies!["session_cookie"] == nil ) {
                response.setCookie("session_cookie", value:UUID().uuidString, path:"/", expires:nil, domain:nil, secure:false)
            }
            response.setCookie("persistant_cookie", value:UUID().uuidString, path:"/", expires:Date.distantFuture, domain:nil, secure:false)

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
            response.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-type")
            response.send(["status": true, "message": "Hello World"])
            completionHandler()
        }
        
        // Prints some more info as text/html
        self.server.add("/status") { (request, response, completionHandler) in

            let startTime:NSDate! = NSDate()

            var responseString:String = String()

            // HTML
            responseString += "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"/><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"/><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>"
            responseString += "<title>\(bundle.bundleIdentifier!)</title>"
            responseString += "<link rel=\"stylesheet\" href=\"/static/style.css\"/><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css\" integrity=\"sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7\" crossorigin=\"anonymous\"/><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css\" integrity=\"sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r\" crossorigin=\"anonymous\"/></head><body>"

            // Bundle info
            responseString += "<h1>\(bundle.bundleIdentifier!)</h1>"
            responseString += "<h2>Version \(bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String) build \(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String)</h2>"

            // Headers
            responseString += "<h3>Request Headers:</h2><pre>"
            for (key, val) in request.allHTTPHeaderFields {
                responseString += "\(key): \(val)\n"
            }
            responseString += "</pre>"

            // Request Enviroment
            responseString += "<h3>Request Environment:</h2><pre>"
            for (key, val) in request.env {
                responseString += "\(key): \(val)\n"
            }
            responseString += "</pre>"

            // Query
            responseString += "<h3>Request Query:</h2><pre>"
            for (key, val) in request.query {
                responseString += "\(key): \(val)\n"
            }
            responseString += "</pre>"

            // Cookies
            responseString += "<h3>Request Cookies:</h2><pre>"
            for (key, val) in request.cookies! {
                responseString += "\(key): \(val)\n"
            }
            responseString += "</pre>"

            // Stack trace
            responseString += "<h3>Stack Trace:</h2><pre>"
            for call in Thread.callStackSymbols {
                responseString += "\(call)\n"
            }
            responseString += "</pre>"

            // System Info
            responseString += "<hr/>"
            responseString += "<small>\(String(describing: CSSystemInfoHelper.shared().systemInfoString))</small><br/>"
            responseString += String(format: "<small>Task took: %.4fms</small>", startTime.timeIntervalSinceNow * -1000)

            // HTML
            responseString += "</body></html>"

            response.setValue("text/html; charset=utf-8", forHTTPHeaderField: "Content-type")
            response.setValue("\(responseString.lengthOfBytes(using: String.Encoding.utf8))", forHTTPHeaderField: "Content-Length")
            response.send(responseString)

            completionHandler()
        }

        self.server.add("/controller", viewController: HelloWorldViewController.self, withNibName: "HelloWorldViewController", bundle: nil)
        
        // Serve static files from "/Public" (relative to bundle)
        let staticFilePath = "\(Bundle.main.resourcePath ?? "")/Public"
        self.server.mount("/static", directoryAtPath: staticFilePath, options: [.followSymlinks, .autoIndex])

        // Redirecter
        self.server.get("/redirect") { (request, response, completionHandler) in
            let redirectURL = URL(string: request.query["redirect"]!)
            if ( redirectURL != nil ) {
                response.redirect(to: redirectURL!)
            }
            completionHandler()
        }
        
        // Start listening
        var serverError:NSError?
        if ( self.server.startListening(&serverError, portNumber: PortNumber) ) {

            
            // Output some nice info to the console
            self.baseURL = NSURL(string: "http://\(CSSystemInfoHelper.shared().ipAddress):\(PortNumber)")

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
            self.app.logError("Failed to start HTTP server. \(String(describing: serverError?.localizedDescription))")
            self.app.terminate(nil)
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        self.server.stopListening()
    }

    func server(_ server: CRServer, didAccept connection: CRConnection) {
        if ( LogConnections ) {
            self.app.log(" * Accepted connection from \(connection.remoteAddress):\(connection.remotePort)")
        }
    }

    func server(_ server: CRServer, didClose connection: CRConnection) {
        if ( LogConnections ) {
            self.app.log(" * Disconnected \(connection.remoteAddress):\(connection.remotePort)")
        }
    }
    
    
    func server(_ server: CRServer, didFinish request: CRRequest) {
        if ( LogRequests ) {
//            self.app.log(" * \(request.response?.connection!.remoteAddress ?? "") \(request.description) - \(request.response?.statusCode ?? 200) - \(request.env["HTTP_USER_AGENT"] ?? "-")")
        }
    }

}
