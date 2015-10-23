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
    [CRApp logFormat:@"%s", __PRETTY_FUNCTION__];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    CRServer* server = [[CRServer alloc] init];

    [CRApp logFormat:@"%s %@", __PRETTY_FUNCTION__, server];
//    [app logFormat:@"Running at http://%@:%lu/", app.interface.length < 7 ? @"127.0.0.1" :  app.interface, app.portNumber];
}


- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender {
    [CRApp logFormat:@"%s", __PRETTY_FUNCTION__];
    return CRTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [CRApp logFormat:@"%s", __PRETTY_FUNCTION__];
}

@end
