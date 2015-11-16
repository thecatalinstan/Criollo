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

    func applicationDidFinishLaunching(aNotification: NSNotification) {

        let app:CRApplication! = CRApp as! CRApplication;

        // Create the server and add some handlers to do some work
        self.server = CRHTTPServer(delegate:self);

        // Prints a simple hello world as text/plain
        let helloBlock:CRRouteHandlerBlock = { (request:CRRequest!, response:CRResponse!, completionHandle:((Void) -> Void)!) -> Void in

        };
        self.server.addHandlerBlock(helloBlock, forPath: "/");

        // Prints a hello world JSON object as application/json
        let jsonHelloBlock:CRRouteHandlerBlock = { (request:CRRequest!, response:CRResponse!, completionHandle:((Void) -> Void)!) -> Void in

        };
        self.server.addHandlerBlock(jsonHelloBlock, forPath: "/json");

        // Prints some more info as text/html
        let statusBlock:CRRouteHandlerBlock = { (request:CRRequest!, response:CRResponse!, completionHandle:((Void) -> Void)!) -> Void in

        };
        self.server.addHandlerBlock(statusBlock, forPath: "/status");

        // Start listening
        var serverError:NSError?;
        if ( self.server.startListening(&serverError, portNumber: PortNumber) ) {

            // Output some nice info to the console

            // Get server ip address
            var address:NSString!;
            let result:Bool = self.getIPAddress(address);
            if ( !result ) {
                address = "127.0.0.1";
            }

            // Set the base url. This is only for logging
            self.baseURL = NSURL(string: String(format: "http://%@:%d/", address, PortNumber))

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

            app.log("Available paths are");
            sortedPaths.enumerateObjectsUsingBlock({ (obj:AnyObject, idx:Int, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                app.log(String(format: " * %@", obj.absoluteString));
            });

        } else {
            app.logError(String("Failed to start HTTP server. %@", serverError?.localizedDescription));
            app .terminate(nil);
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func getIPAddress(var address:NSString?) -> Bool {
        address = "1234234123";
        return false;
    }


}

