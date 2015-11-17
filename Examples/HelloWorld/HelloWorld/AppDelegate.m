//
//  AppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 28/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserverForName:LogMessageNotificationName object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSAttributedString* attributtedString = note.object;
        [CRApp logFormat:@"%@", attributtedString.string];
    }];
}

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
    if (self.isConnected) {
        [self stopListening:nil];
    }
}

- (void)serverDidFailToStartWithError:(NSError *)error {
    [super serverDidFailToStartWithError:error];
    [CRApp terminate:nil];
}

@end
