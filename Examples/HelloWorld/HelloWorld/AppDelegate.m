//
//  AppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 28/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong) CRServer* server;

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.server = [[CRHTTPServer alloc] initWithDelegate:self];
    NSError* error;
    if ( ! [self.server startListening:&error] ) {
        [CRApp logErrorFormat:@"Failed to start server. %@", error.localizedDescription];
        [CRApp terminate:nil];
    } else {
        [CRApp logFormat:@"Running at http://%@:%lu/", self.server.configuration.CRServerInterface.length == 0 ? @"127.0.0.1" : self.server.configuration.CRServerInterface, self.server.configuration.CRServerPort];
    }
}

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender {
    return CRTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.server stopListening];
}

#pragma mark - CRServerDelegate

- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
//    NSString* string = [[NSBundle mainBundle].bundleIdentifier stringByAppendingFormat:@" Connections: %lu\n", self.connections.count];
//    [connection.socket writeData:[string dataUsingEncoding:NSUTF8StringEncoding] withTimeout:0 tag:0];
//    [connection.socket disconnectAfterWriting];
}

@end
