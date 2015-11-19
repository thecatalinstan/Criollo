//
//  AppDelegate.swift
//  HelloWorld-Swift
//
//  Created by Cătălin Stan on 11/16/15.
//
//

import Criollo

let PortNumber:UInt = 10781;
let LogConnections:Bool = true;
let LogRequests:Bool = true;

class AppDelegate: NSObject, CRApplicationDelegate, CRServerDelegate {

    var server:CRHTTPServer!;
    var baseURL:NSURL!;
    var app:CRApplication!;

    func applicationDidFinishLaunching(aNotification: NSNotification) {

        self.app = CRApp as! CRApplication;

        // Create the server and add some handlers to do some work
        self.server = CRHTTPServer(delegate:self);

        // Prints a simple hello world as text/plain
        let helloBlock:CRRouteHandlerBlock = { (request:CRRequest!, response:CRResponse!, completionHandler:((Void) -> Void)!) -> Void in
            response.setValue("text/plain", forHTTPHeaderField: "Content-type");
            response.sendString("Hello World");
            completionHandler();
        };
        self.server.addHandlerBlock(helloBlock, forPath: "/");

        // Prints a hello world JSON object as application/json
        let jsonHelloBlock:CRRouteHandlerBlock = { (request:CRRequest!, response:CRResponse!, completionHandler:((Void) -> Void)!) -> Void in
            do {
                response.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-type");
                try response.sendData(NSJSONSerialization.dataWithJSONObject(["status": true, "message": "Hello World"], options:NSJSONWritingOptions.PrettyPrinted));
            } catch let jsonError as NSError {
                response.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-type");
                response.sendString("\(jsonError)")
            }
            completionHandler();
        };
        self.server.addHandlerBlock(jsonHelloBlock, forPath: "/json");

        // Prints some more info as text/html
        let uname = systemInfo();
        let statusBlock:CRRouteHandlerBlock = { (request:CRRequest!, response:CRResponse!, completionHandler:((Void) -> Void)!) -> Void in

            let startTime:NSDate! = NSDate();

            var responseString:String = String();

            // Bundle info
            let bundle:NSBundle! = NSBundle.mainBundle();
            responseString += "<h1>\(bundle.bundleIdentifier!)</h1>";
            responseString += "<h2>Version \(bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as! String) build \(bundle.objectForInfoDictionaryKey("CFBundleVersion") as! String)</h2>";

            // Headers
            let headers:NSDictionary! = request.allHTTPHeaderFields;
            responseString += "<h3>Request Headers:</h2><pre>";
            headers.enumerateKeysAndObjectsUsingBlock({ (key:AnyObject,  object:AnyObject, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                let header:String = key as! String;
                let value:String = object as! String;
                responseString += "\(header): \(value)\n";
            });
            responseString += "</pre>";

            // Request Enviroment
            let env:NSDictionary! = request.valueForKey("env") as! NSDictionary;
            responseString += "<h3>Request Environment:</h2><pre>";
            env.enumerateKeysAndObjectsUsingBlock({ (key:AnyObject,  object:AnyObject, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                let envKey:String = key as! String;
                responseString += "\(envKey): ";
                if let value = object as? String {
                    responseString += "\(value)";
                } else if let value = object as? NSNumber {
                    responseString += "\(value)";
                }
                responseString += "\n";
            });
            responseString += "</pre>";

            // Stack trace
            let stackTrace:NSArray! = NSThread.callStackSymbols();
            responseString += "<h3>Stack Trace:</h2><pre>";
            stackTrace.enumerateObjectsUsingBlock({ (call:AnyObject, idx:Int, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                let callInfo:String = call as! String;
                responseString += "\(callInfo)\n";
            });
            responseString += "</pre>";

            // System Info
            responseString += "<hr/>";
            responseString += "<small>\(uname)</small><br/>";
            responseString += String(format: "<small>Task took: %.4fms</small>", startTime.timeIntervalSinceNow * -1000);

            response.setValue("text/html; charset=utf-8", forHTTPHeaderField: "Content-type");
            response.setValue("\(responseString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))", forHTTPHeaderField: "Content-Length");
            response.sendString(responseString);

            completionHandler();

        };
        self.server.addHandlerBlock(statusBlock, forPath: "/status");

        // Start listening
        var serverError:NSError?;
        if ( self.server.startListening(&serverError, portNumber: PortNumber) ) {

            // Output some nice info to the console

            // Get server ip address
            var address:NSString?;
            let result:Bool = getIPAddress(&address);
            if ( !result ) {
                address = "127.0.0.1";
            }

            // Set the base url. This is only for logging
            self.baseURL = NSURL(string: "http://\(address!):\(PortNumber)")

            // Log the paths we can handle

            // Get the list of paths from the registered routes
            let routes:NSDictionary!  = self.server.valueForKey("routes") as! NSDictionary;
            let paths:NSMutableSet! = NSMutableSet();
            routes.enumerateKeysAndObjectsUsingBlock({ (key:AnyObject,  object:AnyObject, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                let routeKey:NSString! = key as! NSString;
                let path:String = routeKey.substringFromIndex(routeKey.rangeOfString("/").location + 1);
                let pathURL:NSURL! = self.baseURL.URLByAppendingPathComponent(path);
                paths.addObject(pathURL);
            });

            let sortedPaths:NSArray = paths.sortedArrayUsingDescriptors([NSSortDescriptor(key:"absoluteString", ascending:true)]);

            self.app.log("Available paths are");
            sortedPaths.enumerateObjectsUsingBlock({ (obj:AnyObject, idx:Int, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                self.app.log(" * \(obj.absoluteString )");
            });

        } else {
            self.app.logError("Failed to start HTTP server. \(serverError?.localizedDescription)");
            self.app.terminate(nil);
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        self.server.stopListening();
    }

    func server(server: CRServer!, didAcceptConnection connection: CRConnection!) {
        if ( LogConnections ) {
            self.app.log(" * Accepted connection from \(connection.remoteAddress):\(connection.remotePort)");
        }
    }

    func server(server: CRServer!, didCloseConnection connection: CRConnection!) {
        if ( LogConnections ) {
            self.app.log(" * Disconnected \(connection.remoteAddress):\(connection.remotePort)");
        }
    }


    func server(server: CRServer!, didFinishRequest request: CRRequest!) {
        if ( LogRequests ) {
            let env:NSDictionary! = request.valueForKey("env") as! NSDictionary;
            self.app.log(" * \(request.response.connection!.remoteAddress) \(request.description) - \(request.response.statusCode) - \(env["HTTP_USER_AGENT"])");
        }
    }



}

