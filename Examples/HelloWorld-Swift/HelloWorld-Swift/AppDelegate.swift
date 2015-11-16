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

        (CRApp as! CRApplication).logFormat("%s", "asdfasdfs");

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
            self.baseURL = NSURL(string: String(format: "http://%s:%d/", address, PortNumber))

            // Log the paths we can handle

//            // Get the list of paths
//            NSDictionary<NSString*, NSMutableArray<CRRoute*>*>* routes = [[self.server valueForKey:@"routes"] mutableCopy];
//            NSMutableSet<NSURL*>* paths = [NSMutableSet set];
//            [routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<CRRoute *> * _Nonnull obj, BOOL * _Nonnull stop) {
//            NSString* path = [key substringFromIndex:[key rangeOfString:@"/"].location + 1];
//            [paths addObject:[self.baseURL URLByAppendingPathComponent:path]];
//            }];
//
//            NSArray<NSURL*>* sortedPaths =[paths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"absoluteString" ascending:YES]]];
//
//            [self logFormat:@"Available paths are:"];
//            [sortedPaths enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            [self logFormat:@" * %@", obj.absoluteString];
//            }];


        }
//            [self serverDidStartAtURL:self.baseURL];

//            [self serverDidFailToStartWithError:serverError];
//
//            [self willChangeValueForKey:@"isConnected"];
//            _isConnected = NO;
//            [self didChangeValueForKey:@"isConnected"];
//
//            [self willChangeValueForKey:@"isDisconnected"];
//            _isDisconnected = YES;
//            [self didChangeValueForKey:@"isDisconnected"];
//        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func getIPAddress(var address:NSString?) -> Bool {
        address = "1234234123";
        return false;
    }


}

