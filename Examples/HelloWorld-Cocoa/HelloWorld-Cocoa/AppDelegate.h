//
//  AppDelegate.h
//  HelloWorld-Cocoa
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define PortNumber  10781   // HTTP server port
#define LogDebug        0   // Debug logging
#define KVO             1   // Update user interface with every request

@class CRHTTPServer;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) CRHTTPServer* server;

@end

