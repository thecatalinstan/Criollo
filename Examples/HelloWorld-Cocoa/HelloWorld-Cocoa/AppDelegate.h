//
//  AppDelegate.h
//  HelloWorld-Cocoa
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CRHTTPServer;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) CRHTTPServer* server;

@end

