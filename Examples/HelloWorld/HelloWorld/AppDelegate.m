//
//  AppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 28/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupServer];
    [self startListening:nil];
}

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender {
    if ( self.server.connections.count > 0 ) {
        [self closeAllConnections];
        return CRTerminateLater;
    } else {
        return CRTerminateNow;
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self stopListening:nil];
}

- (void)serverDidStartAtURL:(NSURL *)URL {
    [CRApp logFormat:@"Started HTTP server at %@", URL.absoluteString];
}

- (void)serverDidFailToStartWithError:(NSError *)error {
    [CRApp logErrorFormat:@"Failed to start HTTP server. %@", error.localizedDescription];
}

#pragma mark - CRServerDelegate

- (void)serverDidStartListening:(CRServer *)server {
#if LogDebug
    [CRApp logFormat:@" * Started listening on %@:%lu", server.configuration.CRServerInterface.length == 0 ? @"*" : server.configuration.CRServerInterface, server.configuration.CRServerPort];
#endif
}

- (void)serverDidStopListening:(CRServer *)server {
#if LogDebug
    [CRApp logFormat:@" * Stopped listening on: %@:%lu", server.configuration.CRServerInterface, server.configuration.CRServerPort];
#endif
}

- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
#if LogDebug
    [CRApp logFormat:@" * Connection from %@:%lu", connection.remoteAddress, connection.remotePort];
#endif
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
#if LogDebug
    [CRApp logFormat:@" * Disconnected."];
#endif
}

- (void)server:(CRServer *)server didReceiveRequest:(CRRequest *)request {
#if LogDebug
    [CRApp logFormat:@" * Received request %@", request];
#endif
}

- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
#if LogDebug
    [CRApp logFormat:@" * Finished request: %@ - %lu", request, request.response.statusCode];
#endif
}

@end
