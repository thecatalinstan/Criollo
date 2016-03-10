//
//  AppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 07/03/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong, nonnull) CRServer* server;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Instantiate the server
    self.server = [[CRHTTPServer alloc] init];

    // Add a middleware that sets the 'Server' header and two cookies
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        // The the Server header to the main bundle identifier
        [response setValue:[NSBundle mainBundle].bundleIdentifier forHTTPHeaderField:@"Server"];

        // Set a session cookie if there isn't already one
        if ( !request.cookies[@"session"] ) {
            [response setCookie:@"session" value:[NSUUID UUID].UUIDString path:@"/" expires:nil domain:nil secure:NO];
        }

        // Set a long-lived cookie
        [response setCookie:@"token" value:[NSUUID UUID].UUIDString path:@"/" expires:[NSDate distantFuture] domain:nil secure:NO];

        // Call the next block
        completionHandler();
    }];

    // Add the route block for "GET /"
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        // Send string (the default Content-Type is text/plain)
        [response sendString:@"Hello world!"];

        // Call the next block
        completionHandler();
    } forPath:@"/" HTTPMethod:CRHTTPMethodGET];

    // Send MIME Type for .nfo files
    [[CRMimeTypeHelper sharedHelper] setMimeType:@"text/plain; charset=utf-8" forExtension:@"nfo"];

    // Expose the contents of the home dir "~" at "/pub"
    [self.server mountStaticDirectoryAtPath:@"~" forPath:@"/pub" options:CRStaticDirectoryServingOptionsCacheFiles|CRStaticDirectoryServingOptionsAutoIndex];

    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger statusCode = request.response.statusCode;
        NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
        NSString* userAgent = request.env[@"HTTP_USER_AGENT"];
        NSString* remoteAddress = request.connection.remoteAddress;
        NSLog(@"%@ %@ - %lu %@ - %@", remoteAddress, request, statusCode, contentLength ? : @"-", userAgent);
        completionHandler();
    }];

    // Start listening
    [self.server startListening];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
