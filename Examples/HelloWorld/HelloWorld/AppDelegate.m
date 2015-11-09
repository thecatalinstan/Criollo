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

@end
