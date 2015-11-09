//
//  AppDelegate.h
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PortNumber          10781   // HTTP server port
#define LogDebug                0   // Debug logging
#define KVO                     1   // Update user interface with every request

@class CRHTTPServer;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) CRHTTPServer* server;

- (void)logFormat:(NSString *)format, ...;
- (void)logDebugFormat:(NSString *)format, ...;
- (void)logErrorFormat:(NSString *)format, ...;


@end

