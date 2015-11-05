//
//  AppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 28/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//

#import "AppDelegate.h"

#define HTTPPortNumber 10782
#define FCGIPortNumber 10781

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong) CRHTTPServer* HTTPServer;
@property (nonatomic, strong) CRFCGIServer* FCGIServer;

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.HTTPServer = [[CRHTTPServer alloc] initWithDelegate:self];
    NSError* HTTPServerError;
    if ( ! [self.HTTPServer startListeningOnPortNumber:HTTPPortNumber error:&HTTPServerError] ) {
        [CRApp logErrorFormat:@"Failed to start HTTP server. %@", HTTPServerError.localizedDescription];
    } else {
        [CRApp logFormat:@"Started HTTP server at http://%@:%lu/", self.HTTPServer.configuration.CRServerInterface.length == 0 ? @"127.0.0.1" : self.HTTPServer.configuration.CRServerInterface, self.HTTPServer.configuration.CRServerPort];
    }

    self.FCGIServer = [[CRFCGIServer alloc] initWithDelegate:self];
    NSError* FCGIServerError;
    if ( ! [self.FCGIServer startListeningOnPortNumber:FCGIPortNumber error:&FCGIServerError] ) {
        [CRApp logErrorFormat:@"Failed to start FCGI server. %@", FCGIServerError.localizedDescription];
    } else {
        [CRApp logFormat:@"Running FCGI server on %@:%lu", self.FCGIServer.configuration.CRServerInterface.length == 0 ? @"127.0.0.1" : self.FCGIServer.configuration.CRServerInterface, self.FCGIServer.configuration.CRServerPort];
    }

    if ( HTTPServerError != nil  && FCGIServerError != nil ) {
        [CRApp logErrorFormat:@"%@", @"Neither the FCGI nor the HTTP server could be started. Exiting."];
        [CRApp terminate:nil];
    }
}

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender {
    if ( self.HTTPServer.connections.count > 0 || self.FCGIServer.connections.count > 0 ) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self.HTTPServer closeAllConnections];
            [self.FCGIServer closeAllConnections];
        });
        return CRTerminateLater;
    } else {
        return CRTerminateNow;
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.HTTPServer stopListening];
    [self.FCGIServer stopListening];
}

#pragma mark - CRServerDelegate

@end