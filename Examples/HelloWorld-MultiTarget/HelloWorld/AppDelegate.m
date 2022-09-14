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
        NSLog(@"%@", attributtedString.string);
    }];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupServer];
    [self startListening:nil];
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
