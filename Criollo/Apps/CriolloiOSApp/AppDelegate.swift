//
//  AppDelegate.swift
//  CriolloiOSApp
//
//  Created by Cătălin Stan on 27/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

import UIKit
import Criollo

let PortNumber:UInt = 10781;
let LogConnections:Bool = false;
let LogRequests:Bool = true;

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CRServerDelegate {

    var server:CRServer!;
    var baseURL:NSURL!;

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Create the server and add some handlers to do some work
        self.server = CRHTTPServer(delegate:self);

        let bundle:NSBundle! = NSBundle.mainBundle();

        // Add a header that says who we are :)
        let identifyBlock:CRRouteBlock = { (request, response, completionHandler) -> Void in
            response.setValue("\(bundle.bundleIdentifier!), \(bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as! String) build \(bundle.objectForInfoDictionaryKey("CFBundleVersion") as! String)", forHTTPHeaderField: "Server");

            if ( request.cookies["session_cookie"] == nil ) {
                response.setCookie("session_cookie", value:NSUUID().UUIDString, path:"/", expires:nil, domain:nil, secure:false);
            }
            response.setCookie("persistant_cookie", value:NSUUID().UUIDString, path:"/", expires:NSDate.distantFuture(), domain:nil, secure:false);

            completionHandler();
        };
        self.server.addBlock(identifyBlock);

        // Prints a simple hello world as text/plain
        let helloBlock:CRRouteBlock = { (request, response, completionHandler) -> Void in
            response.setValue("text/plain", forHTTPHeaderField: "Content-type");
            response.send("Hello World");
            completionHandler();
        };
        self.server.addBlock(helloBlock, forPath: "/");

        // Prints a hello world JSON object as application/json
        let jsonHelloBlock:CRRouteBlock = { (request, response, completionHandler) -> Void in
            response.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-type");
            response.send(["status": true, "message": "Hello World"]);
            completionHandler();
        };
        self.server.addBlock(jsonHelloBlock, forPath: "/json");

        // Prints some more info as text/html
        let uname = SystemInfoHelper.systemInfo();
        let statusBlock:CRRouteBlock = { (request, response, completionHandler) -> Void in

            let startTime:NSDate! = NSDate();

            var responseString:String = String();

            // HTML
            responseString += "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"/><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"/><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>";
            responseString += "<title>\(bundle.bundleIdentifier!)</title>";
            responseString += "<link rel=\"stylesheet\" href=\"/static/style.css\"/><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css\" integrity=\"sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7\" crossorigin=\"anonymous\"/><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css\" integrity=\"sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r\" crossorigin=\"anonymous\"/></head><body>";

            // Bundle info
            responseString += "<h1>\(bundle.bundleIdentifier!)</h1>";
            responseString += "<h2>Version \(bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as! String) build \(bundle.objectForInfoDictionaryKey("CFBundleVersion") as! String)</h2>";

            // Headers
            let headers:NSDictionary! = request.allHTTPHeaderFields;
            responseString += "<h3>Request Headers:</h2><pre>";
            headers.enumerateKeysAndObjectsUsingBlock({ (key,  object, stop) -> Void in
                responseString += "\(key): \(object)\n";
            });
            responseString += "</pre>";

            // Request Enviroment
            let env:NSDictionary! = request.valueForKey("env") as! NSDictionary;
            responseString += "<h3>Request Environment:</h2><pre>";
            env.enumerateKeysAndObjectsUsingBlock({ (key,  object, stop) -> Void in
                responseString += "\(key): \(object)\n";
            });
            responseString += "</pre>";

            // Query
            let queryVars:NSDictionary! = request.query as NSDictionary;
            responseString += "<h3>Request Query:</h2><pre>";
            queryVars.enumerateKeysAndObjectsUsingBlock({ (key,  object, stop) -> Void in
                responseString += "\(key): \(object)\n";
            });
            responseString += "</pre>";

            // Cookies
            let cookies:NSDictionary! = request.cookies as NSDictionary;
            responseString += "<h3>Request Cookies:</h2><pre>";
            cookies.enumerateKeysAndObjectsUsingBlock({ (key,  object, stop) -> Void in
                responseString += "\(key): \(object)\n";
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

            // HTML
            responseString += "</body></html>";

            response.setValue("text/html; charset=utf-8", forHTTPHeaderField: "Content-type");
            response.setValue("\(responseString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))", forHTTPHeaderField: "Content-Length");
            response.sendString(responseString);

            completionHandler();

        };
        self.server.addBlock(statusBlock, forPath: "/status");

        self.server.addBlock({ (request, response, next) -> Void in
            let info:Dictionary = [
                "IPAddress":SystemInfoHelper.IPAddress(),
                "systemInfo":SystemInfoHelper.systemInfo(),
                "systemVersion":SystemInfoHelper.systemVersion(),
                "processName":SystemInfoHelper.processName(),
                "processRunningTime":SystemInfoHelper.processRunningTime(),
                "memoryInfo":SystemInfoHelper.memoryInfo(nil),
                "requestsServed":SystemInfoHelper.requestsServed(),
                "criolloVersion":SystemInfoHelper.criolloVersion(),
                "bundleVersion":SystemInfoHelper.bundleVersion(),
            ];
            do {
                try response.sendData(NSJSONSerialization.dataWithJSONObject(info, options: NSJSONWritingOptions.PrettyPrinted));
            } catch let error as NSError {
                CRServer.errorHandlingBlockWithStatus(500, error: error)(request, response, next);
            }
        }, forPath: "/info")

        self.server.addViewController(HelloWorldViewController.self, withNibName:"HelloWorldViewController", bundle:nil, forPath: "/controller");

        // Serve static files from "/Public" (relative to bundle)
        let staticFilePath:String = (NSBundle.mainBundle().resourcePath?.stringByAppendingString("/Public"))!;
        self.server.mountStaticDirectoryAtPath(staticFilePath, forPath: "/static", options: CRStaticDirectoryServingOptions.FollowSymlinks)


        // Redirecter
        self.server.addBlock({ (request, response, completionHandler) -> Void in
            let redirectURL:NSURL! = NSURL(string: request.query["redirect"]!);
            if ( redirectURL != nil ) {
                response.redirectToURL(redirectURL);
            }
            completionHandler();
            }, forPath: "/redirect", HTTPMethod:CRHTTPMethod.Get);

        // Start listening
        var serverError:NSError?;
        if ( self.server.startListening(&serverError, portNumber: PortNumber) ) {

            // Output some nice info to the console

            // Get server ip address
            let address:NSString! = SystemInfoHelper.IPAddress();
            // Set the base url. This is only for logging
            self.baseURL = NSURL(string: "http://\(address):\(PortNumber)")

            // Log the paths we can handle

            // Get the list of paths from the registered routes
            let routes:NSDictionary!  = self.server.valueForKey("routes") as! NSDictionary;
            let paths:NSMutableSet! = NSMutableSet();
            routes.enumerateKeysAndObjectsUsingBlock({ (key,  object, stop) -> Void in
                let routeKey:NSString! = key as! NSString;
                if ( routeKey.hasSuffix("*") ) {
                    return;
                }
                let path:String = routeKey.substringFromIndex(routeKey.rangeOfString("/").location + 1);
                let pathURL:NSURL! = self.baseURL.URLByAppendingPathComponent(path);
                paths.addObject(pathURL);
            });

            let sortedPaths:NSArray = paths.sortedArrayUsingDescriptors([NSSortDescriptor(key:"absoluteString", ascending:true)]);

            NSLog("Available paths are");
            sortedPaths.enumerateObjectsUsingBlock({ (obj:AnyObject, idx:Int, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                NSLog(" * \(obj.absoluteString )");
            });
            
        } else {
            NSLog("Failed to start HTTP server. \(serverError?.localizedDescription)");
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {

    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {

    }

    func applicationDidBecomeActive(application: UIApplication) {

    }

    func applicationWillTerminate(application: UIApplication) {
        self.server.stopListening()
    }

    func server(server: CRServer, didAcceptConnection connection: CRConnection) {
        if ( LogConnections ) {
            NSLog(" * Accepted connection from \(connection.remoteAddress):\(connection.remotePort)");
        }
    }

    func server(server: CRServer, didCloseConnection connection: CRConnection) {
        if ( LogConnections ) {
            NSLog(" * Disconnected \(connection.remoteAddress):\(connection.remotePort)");
        }
    }


    func server(server: CRServer, didFinishRequest request: CRRequest) {
        if ( LogRequests ) {
            let env:NSDictionary! = request.valueForKey("env") as! NSDictionary;
            NSLog(" * \(request.response!.connection!.remoteAddress) \(request.description) - \(request.response!.statusCode) - \(env["HTTP_USER_AGENT"])");
        }
        SystemInfoHelper.addRequest()
    }
}

