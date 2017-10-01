//
//  AppDelegate.h
//  CriolloServerStats
//
//  Created by Cătălin Stan on 28/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Criollo/Criollo.h>

#define NewRequestNotification @"NewRequestNotification"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) CRHTTPServer *server;

@property (nonatomic, assign) NSUInteger requestsReceived;
@property (nonatomic, assign) NSUInteger connectionsReceived;
@property (nonatomic, assign) BOOL isListening;

@property (nonatomic, strong, readonly) NSString *statusText;
@property (nonatomic, strong, readonly) NSString *lastLogMessage;

- (IBAction)startServer:(id)sender;
- (IBAction)stopServer:(id)sender;

@end

