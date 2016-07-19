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

        self.server.addViewController(HelloWorldViewController.self, withNibName:"HelloWorldViewController", bundle:nil, forPath: "/controller");

        // Serve static files from "/Public" (relative to bundle)
        let staticFilePath:String = (NSBundle.mainBundle().resourcePath?.stringByAppendingString("/Public"))!;
        self.server.mountStaticDirectoryAtPath(staticFilePath, forPath: "/static", options: CRStaticDirectoryServingOptions.FollowSymlinks)

        // Redirecter
        self.server.addBlock({ (request, response, completionHandler) -> Void in
            let redirectURL:NSURL! = NSURL(string: request.query["redirect"]!)
            if ( redirectURL != nil ) {
                response.redirectToURL(redirectURL)
            }
            completionHandler()
        }, forPath: "/redirect", HTTPMethod:CRHTTPMethod.Get)

        // API 
        self.server .addController(APIController.self, forPath: "/api", HTTPMethod: CRHTTPMethod.All, recursive: true)

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

